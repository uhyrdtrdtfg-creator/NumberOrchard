import SwiftUI
import SwiftData

struct PetFeedingArea: View {
    @Bindable var viewModel: PetGardenViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var floatingXPText: String?
    @State private var showSwitcher = false
    @State private var showEvolutionEffect = false
    @State private var showWardrobe = false

    private let evolutionLogic = PetEvolutionLogic()

    var body: some View {
        VStack(spacing: 20) {
            activePetSection
            fruitInventorySection
        }
        .sheet(isPresented: $showSwitcher) {
            petSwitcherSheet
        }
        .fullScreenCover(isPresented: $showWardrobe) {
            wardrobeSheet
        }
        .overlay(alignment: .center) {
            if let evo = viewModel.pendingTierEvolution {
                TierEvolutionBanner(
                    noom: evo.noom, skill: evo.skill, newTier: evo.newTier,
                    onDismiss: { viewModel.pendingTierEvolution = nil }
                )
                .zIndex(10)
            }
        }
    }

    @ViewBuilder
    private var wardrobeSheet: some View {
        if let pet = viewModel.activePet {
            NoomWardrobeView(
                viewModel: NoomWardrobeViewModel(
                    profile: viewModel.profile,
                    activePet: pet,
                    modelContext: modelContext
                ),
                onDismiss: { showWardrobe = false }
            )
        }
    }

    @ViewBuilder
    private var activePetSection: some View {
        if let pet = viewModel.activePet, let noom = NoomCatalog.noom(for: pet.noomNumber) {
            CartoonPanel(cornerRadius: 24) {
                VStack(spacing: 12) {
                    HStack {
                        Text(noom.name)
                            .font(CartoonFont.titleSmall)
                            .foregroundStyle(CartoonColor.text)
                        Text(stageLabel(pet.stage))
                            .font(CartoonFont.caption)
                            .foregroundStyle(CartoonColor.text.opacity(0.6))
                    }

                    ZStack {
                        Image(uiImage: NoomRenderer.image(
                            for: noom,
                            expression: .happy,
                            size: CGSize(width: 140, height: 140),
                            stage: pet.stage,
                            skins: viewModel.activeSkins
                        ))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(showEvolutionEffect ? 1.4 : 1.0)
                        .rotationEffect(.degrees(showEvolutionEffect ? 360 : 0))
                        .animation(.easeInOut(duration: 1.0), value: showEvolutionEffect)

                        if let xpText = floatingXPText {
                            Text(xpText)
                                .font(CartoonFont.title)
                                .foregroundStyle(viewModel.lastFedWasPreferred ? CartoonColor.gold : .white)
                                .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
                                .offset(y: -80)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 180, height: 180)

                    xpBar(pet: pet)

                    if let skill = viewModel.activeSkill {
                        skillBadge(skill: skill, tier: viewModel.activeSkillTier)
                    } else if pet.stage == 0 {
                        Text("长大后解锁技能～")
                            .font(CartoonFont.caption)
                            .foregroundStyle(CartoonColor.text.opacity(0.5))
                    }

                    HStack(spacing: 10) {
                        Button("切换宠物") { showSwitcher = true }
                            .font(CartoonFont.bodySmall)
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(Capsule().fill(CartoonColor.paper))
                            .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2))
                        Button("👗 衣柜") { showWardrobe = true }
                            .font(CartoonFont.bodySmall)
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(Capsule().fill(CartoonColor.berry.opacity(0.25)))
                            .overlay(Capsule().stroke(CartoonColor.berry.opacity(0.7), lineWidth: 2))
                    }
                }
                .padding(20)
            }
        } else {
            Text("还没有宠物呢，去小精灵挑战解锁吧！")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .padding()
        }
    }

    private func skillBadge(skill: NoomSkill, tier: NoomSkill.Tier) -> some View {
        // Tier 2 (adult) gets a brighter coral frame + "★★" glyph to make
        // it visually obvious the skill has upgraded.
        let isTier2 = tier == .two
        let frame: Color = isTier2 ? CartoonColor.coral : CartoonColor.gold
        let stars = isTier2 ? "★★" : "★"
        return HStack(spacing: 6) {
            Text(skill.emoji)
            Text("\(skill.displayName) \(stars)")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text)
            Text("·")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.4))
            Text(skill.explanation(tier: tier))
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(frame.opacity(0.25))
                .overlay(Capsule().stroke(frame.opacity(0.7), lineWidth: 1.5))
        )
    }

    private func xpBar(pet: PetProgress) -> some View {
        let nextThreshold = pet.stage < PetEvolutionLogic.stageThresholds.count - 1
            ? PetEvolutionLogic.stageThresholds[pet.stage + 1]
            : pet.xp
        let prevThreshold = PetEvolutionLogic.stageThresholds[pet.stage]
        let progress: Double = nextThreshold > prevThreshold
            ? min(1.0, Double(pet.xp - prevThreshold) / Double(nextThreshold - prevThreshold))
            : 1.0

        return VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: 200, height: 22)
                    .offset(y: 3)
                Capsule().fill(.white).frame(width: 200, height: 22)
                Capsule()
                    .fill(LinearGradient(colors: [CartoonColor.gold, CartoonColor.coral],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(22, progress * 200), height: 22)
                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 2.5).frame(width: 200, height: 22)
            }
            Text("\(pet.xp) / \(nextThreshold) XP")
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
        }
    }

    @ViewBuilder
    private var fruitInventorySection: some View {
        let fruits = viewModel.availableFruits()
        if fruits.isEmpty {
            Text("还没有水果呢！冒险中三星通关可以解锁。")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .padding()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(fruits) { fruit in
                        Button(action: { feed(fruit) }) {
                            Text(fruit.emoji)
                                .font(.system(size: 50))
                                .frame(width: 64, height: 64)
                                .background(
                                    ZStack {
                                        Circle().fill(CartoonColor.ink.opacity(0.9)).offset(y: 3)
                                        Circle().fill(CartoonColor.paper)
                                        Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2.5)
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 80)
        }
    }

    @ViewBuilder
    private var petSwitcherSheet: some View {
        VStack {
            Text("选择宠物")
                .font(CartoonFont.titleSmall)
                .padding()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(viewModel.ownedPets(), id: \.noomNumber) { pet in
                        if let noom = NoomCatalog.noom(for: pet.noomNumber) {
                            Button(action: {
                                viewModel.setActive(pet)
                                showSwitcher = false
                            }) {
                                VStack(spacing: 4) {
                                    Image(uiImage: NoomRenderer.image(
                                        for: noom,
                                        expression: .neutral,
                                        size: CGSize(width: 80, height: 80),
                                        stage: pet.stage
                                    ))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    Text(noom.name)
                                        .font(CartoonFont.caption)
                                        .foregroundStyle(CartoonColor.text)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            Button("关闭") { showSwitcher = false }
                .padding()
        }
    }

    private func feed(_ fruit: FruitItem) {
        let result = viewModel.feedActivePet(fruitId: fruit.id)
        floatingXPText = "+\(result.xp)\(result.preferred ? "!" : "")"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                floatingXPText = nil
            }
        }
        if result.didEvolve {
            showEvolutionEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showEvolutionEffect = false }
            }
        }
    }

    private func stageLabel(_ stage: Int) -> String {
        switch stage {
        case 0: return "幼年"
        case 1: return "少年"
        case 2: return "成年"
        default: return ""
        }
    }
}
