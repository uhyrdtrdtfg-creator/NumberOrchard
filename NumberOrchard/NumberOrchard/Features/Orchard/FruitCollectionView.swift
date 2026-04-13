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

            VStack(spacing: CartoonDimensions.spacingRegular + 2) {
                topBar

                HStack(spacing: CartoonDimensions.spacingSmall) {
                    CartoonTabChip(label: "常见", selected: selectedRarity == .common, tint: CartoonColor.leaf) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedRarity = .common }
                    }
                    CartoonTabChip(label: "稀有", selected: selectedRarity == .rare, tint: CartoonColor.sky) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedRarity = .rare }
                    }
                    CartoonTabChip(label: "传说", selected: selectedRarity == .legendary, tint: CartoonColor.berry) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedRarity = .legendary }
                    }
                }

                if filteredFruits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 28) {
                            ForEach(filteredFruits) { fruit in
                                fruitCard(fruit)
                            }
                        }
                        .padding(.horizontal, CartoonDimensions.spacingLarge)
                        .padding(.vertical, CartoonDimensions.spacingRegular + 4)
                    }
                }
            }
        }
        .sheet(item: $detailFruit) { fruit in
            FruitDetailSheet(fruit: fruit, onDismiss: { detailFruit = nil })
        }
    }

    private var topBar: some View {
        HStack {
            CartoonCircleIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: "返回",
                action: onDismiss
            )
            Spacer()
            Text("🍎 水果图鉴")
                .cartoonTitle(size: CartoonDimensions.fontTitle)
            Spacer()
            CartoonHUD(
                icon: "tray.full.fill",
                value: "\(collectedIds.count)/30",
                tint: CartoonColor.coral,
                accessibilityLabel: "已收集 \(collectedIds.count) / 30"
            )
        }
        .padding(.horizontal, CartoonDimensions.spacingLarge)
        .padding(.top, 20)
    }

    private var emptyState: some View {
        VStack(spacing: CartoonDimensions.spacingRegular) {
            Spacer()
            Text("🌱")
                .font(.system(size: 100))
                .accessibilityHidden(true)
            Text("还没有收集到水果～\n去冒险里解锁吧！")
                .multilineTextAlignment(.center)
                .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            Spacer()
        }
    }

    private func fruitCard(_ fruit: FruitItem) -> some View {
        let collected = collectedIds.contains(fruit.id)
        return Button(action: {
            if collected { detailFruit = fruit }
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                        .frame(width: 140, height: 140)
                        .offset(y: 5)
                    Circle()
                        .fill(collected ? CartoonColor.gold.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 140, height: 140)
                    Circle()
                        .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeHeavy)
                        .frame(width: 140, height: 140)
                    Text(collected ? fruit.emoji : "?")
                        .font(.system(size: collected ? 78 : 72, weight: .black, design: .rounded))
                        .foregroundStyle(collected ? Color.primary : CartoonColor.ink.opacity(0.4))
                        .grayscale(collected ? 0 : 1)
                        .opacity(collected ? 1 : 0.5)
                }
                Text(collected ? fruit.name : "？？？")
                    .cartoonTitle(size: CartoonDimensions.fontBody)
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

            VStack(spacing: CartoonDimensions.spacingMedium) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).frame(width: 240, height: 240).offset(y: CartoonDimensions.shadowOffsetLarge)
                    Circle().fill(CartoonColor.gold.opacity(0.25)).frame(width: 240, height: 240)
                    Circle().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: 5).frame(width: 240, height: 240)
                    Text(fruit.emoji).font(.system(size: 140)).accessibilityHidden(true)
                }
                .scaleEffect(reduceMotion ? 1 : (popped ? 1 : 0.3))
                .rotationEffect(.degrees(reduceMotion ? 0 : (popped ? 0 : -30)))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: popped)

                Text(fruit.name)
                    .cartoonTitle(size: CartoonDimensions.fontTitleLarge)

                Text(fruit.rarity.rawValue)
                    .font(.system(size: CartoonDimensions.fontBodyLarge, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, CartoonDimensions.spacingMedium).padding(.vertical, 10)
                    .background(
                        ZStack {
                            Capsule().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).offset(y: CartoonDimensions.shadowOffsetRegular)
                            Capsule().fill(rarityColor)
                            Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                        }
                    )

                CartoonPanel(cornerRadius: CartoonDimensions.radiusMedium) {
                    Text(fruit.funFact)
                        .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                        .multilineTextAlignment(.center)
                        .padding(CartoonDimensions.spacingMedium + 2)
                }

                CartoonButton(tint: CartoonColor.sky, action: onDismiss) {
                    Text("知道了！")
                        .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 200, height: 70)
                }
            }
            .padding(CartoonDimensions.spacingLarge)
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

#Preview {
    FruitCollectionView(onDismiss: {})
        .modelContainer(for: ChildProfile.self, inMemory: true)
}
