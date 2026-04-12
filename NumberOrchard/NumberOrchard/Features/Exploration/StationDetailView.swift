import SwiftUI

struct StationDetailView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(station.emoji)
                .font(.system(size: 100))

            Text(station.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("(\(station.id))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 30) {
                VStack {
                    Text("难度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(station.level.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                VStack {
                    Text("当前成绩")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(i < stars ? .orange : .gray)
                        }
                    }
                }
            }

            if let fruitId = station.starFruitId, let fruit = FruitCatalog.fruit(id: fruitId) {
                HStack {
                    Text("三星奖励:")
                        .font(.callout)
                    Text(fruit.emoji).font(.title2)
                    Text(fruit.name).font(.callout)
                }
                .padding(8)
                .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }

            if isUnlocked {
                Button(action: onStart) {
                    Text("开始挑战")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                Text("先完成前面的关卡才能解锁哦")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Button("返回", action: onDismiss)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .presentationDetents([.medium, .large])
    }
}
