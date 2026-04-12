import SwiftUI

struct StationDetailView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool
    let onStart: () -> Void
    let onDismiss: () -> Void

    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(CartoonColor.ink.opacity(0.9))
                        .frame(width: 220, height: 220)
                        .offset(y: 6)
                    Circle()
                        .fill(CartoonColor.paper)
                        .frame(width: 220, height: 220)
                    Circle()
                        .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 5)
                        .frame(width: 220, height: 220)
                    Text(station.emoji)
                        .font(.system(size: 130))
                        .accessibilityHidden(true)
                }
                .scaleEffect(reduceMotion ? 1.0 : (popped ? 1.0 : 0.4))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: popped)

                Text(station.displayName)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                // Star rating row
                HStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 48, weight: .black))
                            .foregroundStyle(i < stars ? CartoonColor.gold : CartoonColor.ink.opacity(0.2))
                            .shadow(color: CartoonColor.ink.opacity(i < stars ? 0.4 : 0), radius: 0, x: 0, y: 3)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("已获得 \(stars) 颗星,共 3 颗")

                // Info panel
                CartoonPanel(cornerRadius: 24) {
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("难度")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(CartoonColor.text.opacity(0.6))
                            Text(station.level.displayName)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(CartoonColor.text)
                        }
                        if let fruitId = station.starFruitId, let fruit = FruitCatalog.fruit(id: fruitId) {
                            VStack(spacing: 4) {
                                Text("三星奖励")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(CartoonColor.text.opacity(0.6))
                                HStack(spacing: 6) {
                                    Text(fruit.emoji).font(.system(size: 36))
                                    Text(fruit.name)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                        .foregroundStyle(CartoonColor.text)
                                }
                            }
                        }
                    }
                    .padding(24)
                }

                // Action
                if isUnlocked {
                    CartoonButton(tint: CartoonColor.leaf, accessibilityLabel: "开始挑战 \(station.displayName)", action: onStart) {
                        Text("开始挑战！")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                            .frame(width: 240, height: 80)
                    }
                } else {
                    Text("🔒 还没解锁哦")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(CartoonColor.text.opacity(0.5))
                        .padding()
                }

                Button(action: onDismiss) {
                    Text("返回")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CartoonColor.text.opacity(0.75))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("返回")
            }
            .padding(30)
        }
        .presentationDetents([.large])
        .onAppear {
            popped = true
        }
    }
}
