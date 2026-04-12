import SwiftUI
import SwiftData

struct FruitCollectionView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedRarity: FruitRarity = .common
    @State private var detailFruit: FruitItem?

    private var profile: ChildProfile? { profiles.first }
    private var collectedIds: Set<String> {
        Set(profile?.collectedFruits.map(\.fruitId) ?? [])
    }
    private var filteredFruits: [FruitItem] {
        FruitCatalog.fruits(rarity: selectedRarity)
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 18) {
                // Top bar
                HStack {
                    backButton
                    Spacer()
                    Text("🍎 水果图鉴")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(CartoonColor.text)
                    Spacer()
                    CartoonHUD(icon: "tray.full.fill", value: "\(collectedIds.count)/30", tint: CartoonColor.coral)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                // Rarity tabs
                HStack(spacing: 12) {
                    rarityTab(rarity: .common, label: "常见", color: CartoonColor.leaf)
                    rarityTab(rarity: .rare, label: "稀有", color: CartoonColor.sky)
                    rarityTab(rarity: .legendary, label: "传说", color: CartoonColor.berry)
                }

                // Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 28) {
                        ForEach(filteredFruits) { fruit in
                            fruitCard(fruit)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(item: $detailFruit) { fruit in
            FruitDetailSheet(fruit: fruit, onDismiss: { detailFruit = nil })
        }
    }

    private var backButton: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 68, height: 68).offset(y: 4)
                Circle().fill(CartoonColor.paper).frame(width: 68, height: 68)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 68, height: 68)
                Image(systemName: "chevron.left")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(CartoonColor.text)
            }
            .frame(width: 72, height: 72)
            .contentShape(Circle())
        }
        .accessibilityLabel("返回")
    }

    private func rarityTab(rarity: FruitRarity, label: String, color: Color) -> some View {
        let selected = selectedRarity == rarity
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedRarity = rarity
            }
        }) {
            ZStack {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.9))
                    .frame(height: 52)
                    .offset(y: selected ? 4 : 4)
                Capsule()
                    .fill(selected ? color : CartoonColor.paper)
                    .frame(height: 52)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
                    .frame(height: 52)
                Text(label)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(selected ? .white : CartoonColor.text)
                    .padding(.horizontal, 28)
            }
            .fixedSize()
            .offset(y: selected ? 0 : -2)
        }
        .buttonStyle(.plain)
    }

    private func fruitCard(_ fruit: FruitItem) -> some View {
        let collected = collectedIds.contains(fruit.id)
        return Button(action: {
            if collected { detailFruit = fruit }
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(CartoonColor.ink.opacity(0.9))
                        .frame(width: 140, height: 140)
                        .offset(y: 5)
                    Circle()
                        .fill(collected ? CartoonColor.gold.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 140, height: 140)
                    Circle()
                        .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 4)
                        .frame(width: 140, height: 140)
                    Text(collected ? fruit.emoji : "?")
                        .font(.system(size: collected ? 78 : 72, weight: .black, design: .rounded))
                        .foregroundStyle(collected ? Color.primary : CartoonColor.ink.opacity(0.4))
                        .grayscale(collected ? 0 : 1)
                        .opacity(collected ? 1 : 0.5)
                }
                Text(collected ? fruit.name : "？？？")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(collected ? CartoonColor.text : CartoonColor.text.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(collected ? "\(fruit.name),已收集" : "未收集的水果")
        .accessibilityHint(collected ? "双击查看详情" : "")
    }
}

struct FruitDetailSheet: View {
    let fruit: FruitItem
    let onDismiss: () -> Void
    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 240, height: 240).offset(y: 6)
                    Circle().fill(CartoonColor.gold.opacity(0.25)).frame(width: 240, height: 240)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 5).frame(width: 240, height: 240)
                    Text(fruit.emoji).font(.system(size: 140)).accessibilityHidden(true)
                }
                .scaleEffect(reduceMotion ? 1 : (popped ? 1 : 0.3))
                .rotationEffect(.degrees(reduceMotion ? 0 : (popped ? 0 : -30)))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: popped)

                Text(fruit.name)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                Text(fruit.rarity.rawValue)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .background(
                        ZStack {
                            Capsule().fill(CartoonColor.ink.opacity(0.9)).offset(y: 4)
                            Capsule().fill(rarityColor)
                            Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
                        }
                    )

                CartoonPanel(cornerRadius: 24) {
                    Text(fruit.funFact)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CartoonColor.text)
                        .multilineTextAlignment(.center)
                        .padding(24)
                }

                CartoonButton(tint: CartoonColor.sky, action: onDismiss) {
                    Text("知道了！")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 200, height: 70)
                }
            }
            .padding(30)
        }
        .presentationDetents([.large])
        .onAppear { popped = true }
    }

    private var rarityColor: Color {
        switch fruit.rarity {
        case .common: return CartoonColor.leaf
        case .rare: return CartoonColor.sky
        case .legendary: return CartoonColor.berry
        }
    }
}
