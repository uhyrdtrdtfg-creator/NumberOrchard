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
        NavigationStack {
            VStack {
                Picker("稀有度", selection: $selectedRarity) {
                    Text("常见").tag(FruitRarity.common)
                    Text("稀有").tag(FruitRarity.rare)
                    Text("传说").tag(FruitRarity.legendary)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack {
                    Text("图鉴进度: \(collectedIds.count) / 30")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(filteredFruits) { fruit in
                            let collected = collectedIds.contains(fruit.id)
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(collected ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    Text(fruit.emoji)
                                        .font(.system(size: 42))
                                        .grayscale(collected ? 0 : 1)
                                        .opacity(collected ? 1 : 0.3)
                                }
                                Text(collected ? fruit.name : "？")
                                    .font(.caption)
                                    .foregroundStyle(collected ? .primary : .secondary)
                            }
                            .onTapGesture {
                                if collected { detailFruit = fruit }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("水果图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回", action: onDismiss)
                }
            }
            .sheet(item: $detailFruit) { fruit in
                FruitDetailSheet(fruit: fruit, onDismiss: { detailFruit = nil })
            }
        }
    }
}

struct FruitDetailSheet: View {
    let fruit: FruitItem
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(fruit.emoji).font(.system(size: 120))
            Text(fruit.name).font(.largeTitle).fontWeight(.bold)
            Text(fruit.rarity.rawValue)
                .font(.callout)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(rarityColor.opacity(0.2), in: Capsule())
                .foregroundStyle(rarityColor)

            Text(fruit.funFact)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("关闭", action: onDismiss)
                .padding(.top)
        }
        .padding(40)
        .presentationDetents([.medium])
    }

    private var rarityColor: Color {
        switch fruit.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .legendary: return .purple
        }
    }
}
