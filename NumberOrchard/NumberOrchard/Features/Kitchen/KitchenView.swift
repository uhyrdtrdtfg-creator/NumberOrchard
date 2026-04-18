import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class KitchenViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    static let totalRounds = 5

    var currentRound: Int = 0
    var recipe: CookingRecipe
    var correctRounds: Int = 0
    var sessionComplete: Bool = false

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        var rng = SystemRandomNumberGenerator()
        self.recipe = CookingRecipeGenerator.makeRecipe(rng: &rng)
    }

    func add(_ fruitId: String) {
        recipe.add(fruitId)
        AudioManager.shared.playSound("fruit_pick.wav")
    }

    func remove(_ fruitId: String) {
        recipe.remove(fruitId)
        AudioManager.shared.playSound("button_click.wav")
    }

    func dumpBasket() {
        recipe.dumpBasket()
        AudioManager.shared.playSound("button_click.wav")
    }

    /// Try to serve the plate. Succeeds only if basket == target.
    func serve() {
        guard recipe.isComplete else { return }
        correctRounds += 1
        AudioManager.shared.playSound("correct.wav")
        advance()
    }

    private func advance() {
        currentRound += 1
        if currentRound >= Self.totalRounds {
            sessionComplete = true
            profile.stars += max(1, correctRounds / 2)
            AudioManager.shared.playSound("level_up.wav")
        } else {
            var rng = SystemRandomNumberGenerator()
            recipe = CookingRecipeGenerator.makeRecipe(rng: &rng)
        }
    }

    var progressText: String { "\(min(currentRound + 1, Self.totalRounds)) / \(Self.totalRounds)" }
}

/// Full-screen 烹饪小厨房 — a recipe card names the fruit counts needed,
/// the child taps pantry fruits to match the counts, then hits 上菜.
/// Trains applied addition (“2 + 3 makes my recipe”).
struct KitchenView: View {
    @Bindable var viewModel: KitchenViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 16) {
                topBar
                if viewModel.sessionComplete {
                    completeView
                } else {
                    recipeCard
                    basketPanel
                    pantryPanel
                    actionRow
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 56, height: 56)
                    Image(systemName: "xmark").font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("🍳 烹饪小厨房").font(CartoonFont.titleSmall).foregroundStyle(CartoonColor.text)
            Spacer()
            Text("第 \(viewModel.progressText)")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
                .frame(width: 96, alignment: .trailing)
        }
        .padding(.top, 16)
    }

    private var recipeCard: some View {
        CartoonPanel(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("📋 今日菜谱")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                HStack(spacing: 12) {
                    ForEach(viewModel.recipe.target.sorted(by: { $0.key < $1.key }), id: \.key) { id, count in
                        recipeSticker(fruitId: id, count: count)
                    }
                }
            }
            .padding(18)
        }
    }

    private func recipeSticker(fruitId: String, count: Int) -> some View {
        let emoji = FruitCatalog.fruit(id: fruitId)?.emoji ?? "❓"
        let have = viewModel.recipe.basket[fruitId] ?? 0
        let ok = have == count
        let over = have > count
        let tint: Color = ok ? CartoonColor.leaf : (over ? CartoonColor.coral : CartoonColor.paperWarm)
        return HStack(spacing: 4) {
            Text(emoji).font(.system(size: 32))
            Text("\(have)/\(count)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(ok ? .white : CartoonColor.text)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(tint))
        .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2))
    }

    private var basketPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🧺 篮子 (共 \(viewModel.recipe.totalBasket) 个)")
                    .font(CartoonFont.bodySmall)
                    .foregroundStyle(CartoonColor.text.opacity(0.75))
                Spacer()
                Button("倒掉") { viewModel.dumpBasket() }
                    .font(CartoonFont.caption)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(CartoonColor.coral.opacity(0.75)))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 10) {
                ForEach(viewModel.recipe.basket.filter { $0.value > 0 }.sorted(by: { $0.key < $1.key }), id: \.key) { id, count in
                    Button {
                        viewModel.remove(id)
                    } label: {
                        HStack(spacing: 2) {
                            Text(FruitCatalog.fruit(id: id)?.emoji ?? "?")
                                .font(.system(size: 28))
                            Text("×\(count)")
                                .font(CartoonFont.caption)
                                .foregroundStyle(CartoonColor.text)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(CartoonColor.paper))
                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.5), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.recipe.basket.allSatisfy({ $0.value == 0 }) {
                    Text("还没放东西~")
                        .font(CartoonFont.caption)
                        .foregroundStyle(CartoonColor.text.opacity(0.5))
                }
            }
            .frame(minHeight: 42)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(CartoonColor.paperWarm)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(CartoonColor.ink.opacity(0.5), lineWidth: 2)))
    }

    private var pantryPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🛒 食材柜 — 点一下加入篮子")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.75))
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(CookingRecipeGenerator.pantryIds, id: \.self) { fruitId in
                    pantryButton(fruitId: fruitId)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(CartoonColor.sky.opacity(0.25))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(CartoonColor.ink.opacity(0.5), lineWidth: 2)))
    }

    private func pantryButton(fruitId: String) -> some View {
        let emoji = FruitCatalog.fruit(id: fruitId)?.emoji ?? "?"
        return Button { viewModel.add(fruitId) } label: {
            Text(emoji)
                .font(.system(size: 44))
                .frame(width: 56, height: 56)
                .background(
                    ZStack {
                        Circle().fill(CartoonColor.ink.opacity(0.8)).offset(y: 3)
                        Circle().fill(CartoonColor.paper)
                        Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2)
                    }
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var actionRow: some View {
        let canServe = viewModel.recipe.isComplete
        CartoonButton(
            tint: canServe ? CartoonColor.leaf : CartoonColor.ink.opacity(0.35),
            accessibilityLabel: "上菜",
            action: { viewModel.serve() }
        ) {
            Text(canServe ? "🍽 上菜!" : (viewModel.recipe.isOverfilled ? "太多啦,倒一点" : "还差一点~"))
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(.white)
                .frame(width: 240, height: 56)
        }
    }

    private var completeView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 30)
            Text("🍽🎉").font(.system(size: 80))
            Text("今日菜单完成!")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("答对 \(viewModel.correctRounds) / \(KitchenViewModel.totalRounds)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.8))
            Text("+\(max(1, viewModel.correctRounds / 2)) ⭐")
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.gold)
            Spacer().frame(height: 10)
            CartoonButton(tint: CartoonColor.gold, accessibilityLabel: "完成", action: onDismiss) {
                Text("回到花园")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 60)
            }
        }
    }
}
