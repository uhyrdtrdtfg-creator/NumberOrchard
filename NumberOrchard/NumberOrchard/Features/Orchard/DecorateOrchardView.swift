import SwiftUI
import SwiftData

struct DecorateOrchardView: View {
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var selectedCategory: DecorationCategory = .flower
    private let purchaseLogic = DecorationPurchaseLogic()

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 16) {
                // Top bar
                HStack {
                    backButton
                    Spacer()
                    Text("🎨 装饰商店")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(CartoonColor.text)
                    Spacer()
                    CartoonHUD(icon: "star.fill", value: "\(profile?.stars ?? 0)", tint: CartoonColor.gold)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DecorationCategory.allCases, id: \.self) { category in
                            categoryTab(category)
                        }
                    }
                    .padding(.horizontal, 30)
                }

                // Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 24) {
                        ForEach(DecorationCatalog.items(in: selectedCategory)) { item in
                            decorationCard(item)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private var backButton: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 60, height: 60).offset(y: 4)
                Circle().fill(CartoonColor.paper).frame(width: 60, height: 60)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 60, height: 60)
                Image(systemName: "chevron.left")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(CartoonColor.text)
            }
        }
    }

    private func categoryTab(_ category: DecorationCategory) -> some View {
        let selected = selectedCategory == category
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            ZStack {
                Capsule().fill(CartoonColor.ink.opacity(0.9)).frame(height: 48).offset(y: 4)
                Capsule()
                    .fill(selected ? CartoonColor.coral : CartoonColor.paper)
                    .frame(height: 48)
                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(height: 48)
                Text(category.rawValue)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(selected ? .white : CartoonColor.text)
                    .padding(.horizontal, 24)
            }
            .fixedSize()
            .offset(y: selected ? 0 : -2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func decorationCard(_ item: DecorationItem) -> some View {
        let owned = profile?.decorations.filter { $0.itemId == item.id }.count ?? 0
        let stars = profile?.stars ?? 0
        let canAfford = stars >= item.cost

        VStack(spacing: 12) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.85)).frame(width: 130, height: 130).offset(y: 4)
                Circle().fill(CartoonColor.paper).frame(width: 130, height: 130)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 130, height: 130)
                Text(item.emoji).font(.system(size: 74))
                if owned > 0 {
                    Text("×\(owned)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(CartoonColor.leaf))
                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 2))
                        .offset(x: 44, y: -44)
                }
            }

            Text(item.name)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)

            CartoonButton(
                tint: canAfford ? CartoonColor.gold : CartoonColor.ink.opacity(0.3),
                shadowOffset: 4,
                cornerRadius: 20,
                action: { purchase(item) }
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").font(.system(size: 18, weight: .black))
                    Text("\(item.cost)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .frame(width: 110, height: 50)
            }
            .disabled(!canAfford)
        }
    }

    private func purchase(_ item: DecorationItem) {
        guard let profile else { return }
        let result = purchaseLogic.purchase(item: item, availableStars: profile.stars)
        if result.success {
            profile.stars = result.remainingStars
            let decoration = CollectedDecoration(itemId: item.id)
            decoration.isPlaced = true
            decoration.positionX = Double.random(in: 0.1...0.9)
            decoration.positionY = Double.random(in: 0.2...0.7)
            profile.decorations.append(decoration)
            modelContext.insert(decoration)
        }
    }
}
