import SwiftUI
import SwiftData

struct DecorateOrchardView: View {
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var selectedCategory: DecorationCategory = .flower
    @State private var purchaseToast: String?
    @State private var toastVisible = false
    @State private var showEdit = false
    private let purchaseLogic = DecorationPurchaseLogic()

    private var profile: ChildProfile? { profiles.first }
    private var currentItems: [DecorationItem] {
        DecorationCatalog.items(in: selectedCategory)
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()
        }
        .overlay(content)
        .fullScreenCover(isPresented: $showEdit) {
            OrchardEditView(onDismiss: { showEdit = false })
        }
    }

    private var content: some View {
        ZStack {
            Color.clear

            if let toast = purchaseToast, toastVisible {
                VStack {
                    Spacer()
                    HStack(spacing: CartoonDimensions.spacingSmall) {
                        Text("🎉")
                        Text(toast).cartoonTitle(size: CartoonDimensions.fontBodyLarge).foregroundStyle(.white)
                    }
                    .padding(.horizontal, CartoonDimensions.spacingMedium)
                    .padding(.vertical, CartoonDimensions.spacingSmall)
                    .background(
                        ZStack {
                            Capsule().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).offset(y: CartoonDimensions.shadowOffsetRegular)
                            Capsule().fill(CartoonColor.leaf)
                            Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                        }
                    )
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
                .allowsHitTesting(false)
            }

            VStack(spacing: CartoonDimensions.spacingRegular) {
                topBar

                Text("用⭐装扮你的果园～每买一样都会出现在首页")
                    .cartoonBody(size: CartoonDimensions.fontBodySmall)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CartoonDimensions.spacingLarge)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DecorationCategory.allCases, id: \.self) { category in
                            CartoonTabChip(
                                label: category.rawValue,
                                selected: selectedCategory == category,
                                tint: CartoonColor.coral,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, CartoonDimensions.spacingLarge)
                }

                if currentItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 24) {
                            ForEach(currentItems) { item in
                                decorationCard(item)
                            }
                        }
                        .padding(.horizontal, CartoonDimensions.spacingLarge)
                        .padding(.vertical, CartoonDimensions.spacingRegular)
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: CartoonDimensions.spacingSmall) {
            CartoonCircleIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: "返回",
                action: onDismiss
            )
            Spacer()
            Text("🎨 装饰商店")
                .cartoonTitle(size: CartoonDimensions.fontTitle)
            Spacer()
            Button {
                showEdit = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 18, weight: .black))
                    Text("摆放")
                        .font(.system(size: CartoonDimensions.fontBody, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        Capsule().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).offset(y: 3)
                        Capsule().fill(CartoonColor.leaf)
                        Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                    }
                )
                .contentShape(Capsule())
            }
            .accessibilityLabel("摆放果园")
            CartoonHUD(icon: "star.fill", value: "\(profile?.stars ?? 0)", tint: CartoonColor.gold)
        }
        .padding(.horizontal, CartoonDimensions.spacingLarge)
        .padding(.top, 20)
    }

    private var emptyState: some View {
        VStack(spacing: CartoonDimensions.spacingRegular) {
            Spacer()
            Text("🎨")
                .font(.system(size: 100))
                .accessibilityHidden(true)
            Text("这个分类还没有商品哦～")
                .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            Spacer()
        }
    }

    @ViewBuilder
    private func decorationCard(_ item: DecorationItem) -> some View {
        let owned = profile?.decorations.filter { $0.itemId == item.id }.count ?? 0
        let stars = profile?.stars ?? 0
        let canAfford = stars >= item.cost

        VStack(spacing: CartoonDimensions.spacingSmall) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.85)).frame(width: 130, height: 130).offset(y: CartoonDimensions.shadowOffsetRegular)
                Circle().fill(CartoonColor.paper).frame(width: 130, height: 130)
                Circle().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold).frame(width: 130, height: 130)
                Text(item.emoji).font(.system(size: 74))
                if owned > 0 {
                    Text("×\(owned)")
                        .font(.system(size: CartoonDimensions.fontBodySmall, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(CartoonColor.leaf))
                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeThin))
                        .offset(x: 44, y: -44)
                }
            }

            Text(item.name)
                .cartoonTitle(size: CartoonDimensions.fontBodyLarge)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            CartoonButton(
                tint: canAfford ? CartoonColor.gold : CartoonColor.ink.opacity(0.3),
                shadowOffset: CartoonDimensions.shadowOffsetRegular,
                cornerRadius: CartoonDimensions.radiusMedium - 2,
                accessibilityLabel: "购买 \(item.name),价格 \(item.cost) 颗星星",
                accessibilityHint: canAfford ? "双击购买" : "星星不够",
                action: { purchase(item) }
            ) {
                HStack(spacing: CartoonDimensions.spacingTight) {
                    Image(systemName: "star.fill").font(.system(size: CartoonDimensions.fontBody, weight: .black))
                    Text("\(item.cost)")
                        .font(.system(size: CartoonDimensions.fontTitleSmall - 2, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .frame(width: 130, height: 58)
            }
            .disabled(!canAfford)
        }
    }

    private func purchase(_ item: DecorationItem) {
        guard let profile else { return }
        let result = purchaseLogic.purchase(item: item, availableStars: profile.stars)
        guard result.success else { return }

        profile.stars = result.remainingStars

        // Canonical SwiftData order: insert into context first, then mutate, then
        // attach to the parent relationship. Otherwise the inverse link may not
        // persist reliably and the decoration vanishes on relaunch.
        let decoration = CollectedDecoration(itemId: item.id)
        modelContext.insert(decoration)
        decoration.isPlaced = true
        decoration.positionX = Double.random(in: 0.1...0.9)
        decoration.positionY = Double.random(in: 0.0...1.0)
        profile.decorations.append(decoration)

        do { try modelContext.save() } catch { /* autosave will retry */ }

        purchaseToast = "获得 \(item.name) \(item.emoji)"
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            toastVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { toastVisible = false }
        }
    }
}

#Preview {
    DecorateOrchardView(onDismiss: {})
        .modelContainer(for: ChildProfile.self, inMemory: true)
}
