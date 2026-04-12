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
        NavigationStack {
            VStack {
                HStack {
                    Label("\(profile?.stars ?? 0)", systemImage: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DecorationCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.rawValue)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.2), in: Capsule())
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 16) {
                        ForEach(DecorationCatalog.items(in: selectedCategory)) { item in
                            decorationCard(for: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("装饰商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回", action: onDismiss)
                }
            }
        }
    }

    @ViewBuilder
    private func decorationCard(for item: DecorationItem) -> some View {
        let owned = profile?.decorations.filter { $0.itemId == item.id }.count ?? 0
        let stars = profile?.stars ?? 0
        let canAfford = stars >= item.cost

        VStack(spacing: 6) {
            Text(item.emoji).font(.system(size: 50))
            Text(item.name).font(.caption)
            Text("\(item.cost) ⭐").font(.caption2).foregroundStyle(.orange)
            if owned > 0 {
                Text("已有 x\(owned)").font(.caption2).foregroundStyle(.green)
            }
            Button(action: { purchase(item) }) {
                Text(canAfford ? "购买" : "不够")
                    .font(.caption)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(canAfford ? Color.green : Color.gray, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(!canAfford)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func purchase(_ item: DecorationItem) {
        guard let profile else { return }
        let result = purchaseLogic.purchase(item: item, availableStars: profile.stars)
        if result.success {
            profile.stars = result.remainingStars
            let decoration = CollectedDecoration(itemId: item.id)
            // Auto-place at random position in top 70% of orchard
            decoration.isPlaced = true
            decoration.positionX = Double.random(in: 0.1...0.9)
            decoration.positionY = Double.random(in: 0.2...0.7)
            profile.decorations.append(decoration)
            modelContext.insert(decoration)
        }
    }
}
