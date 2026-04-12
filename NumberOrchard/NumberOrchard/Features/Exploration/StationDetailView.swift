import SwiftUI

struct StationDetailView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(station.emoji)
                .font(.system(size: 160))

            Text(station.displayName)
                .font(.system(size: 42, weight: .bold))

            Text("(\(station.id))")
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 50) {
                VStack(spacing: 6) {
                    Text("难度")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(station.level.displayName)
                        .font(.title)
                        .fontWeight(.semibold)
                }
                VStack(spacing: 6) {
                    Text("当前成绩")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(i < stars ? .orange : .gray)
                        }
                    }
                }
            }

            if let fruitId = station.starFruitId, let fruit = FruitCatalog.fruit(id: fruitId) {
                HStack(spacing: 10) {
                    Text("三星奖励:")
                        .font(.title3)
                    Text(fruit.emoji).font(.system(size: 44))
                    Text(fruit.name).font(.title3)
                }
                .padding(14)
                .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }

            if isUnlocked {
                Button(action: onStart) {
                    Text("开始挑战")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                Text("先完成前面的关卡才能解锁哦")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Button("返回", action: onDismiss)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .presentationDetents([.large])
    }
}
