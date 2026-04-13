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

            VStack(spacing: CartoonDimensions.spacingMedium) {
                stationBadge

                Text(station.displayName)
                    .cartoonTitle(size: CartoonDimensions.fontTitleLarge)

                starRow

                infoPanel

                actionRow
            }
            .padding(CartoonDimensions.spacingLarge)
        }
        .presentationDetents([.large])
        .onAppear { popped = true }
    }

    private var stationBadge: some View {
        ZStack {
            Circle()
                .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                .frame(width: CartoonDimensions.circleBadgeHuge, height: CartoonDimensions.circleBadgeHuge)
                .offset(y: CartoonDimensions.shadowOffsetLarge)
            Circle()
                .fill(CartoonColor.paper)
                .frame(width: CartoonDimensions.circleBadgeHuge, height: CartoonDimensions.circleBadgeHuge)
            Circle()
                .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: 5)
                .frame(width: CartoonDimensions.circleBadgeHuge, height: CartoonDimensions.circleBadgeHuge)
            Text(station.emoji)
                .font(.system(size: 130))
                .accessibilityHidden(true)
        }
        .scaleEffect(reduceMotion ? 1.0 : (popped ? 1.0 : 0.4))
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.55), value: popped)
    }

    private var starRow: some View {
        HStack(spacing: CartoonDimensions.spacingSmall) {
            ForEach(0..<3) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(i < stars ? CartoonColor.gold : CartoonColor.ink.opacity(0.2))
                    .shadow(color: CartoonColor.ink.opacity(i < stars ? 0.4 : 0), radius: 0, x: 0, y: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("已获得 \(stars) 颗星,共 3 颗")
    }

    private var infoPanel: some View {
        CartoonPanel(cornerRadius: CartoonDimensions.radiusMedium) {
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("难度").cartoonCaption(size: CartoonDimensions.fontBodySmall)
                    Text(station.level.displayName).cartoonTitle(size: CartoonDimensions.fontTitleSmall)
                }
                if let fruitId = station.starFruitId, let fruit = FruitCatalog.fruit(id: fruitId) {
                    VStack(spacing: 4) {
                        Text("三星奖励").cartoonCaption(size: CartoonDimensions.fontBodySmall)
                        HStack(spacing: 6) {
                            Text(fruit.emoji).font(.system(size: 36))
                            Text(fruit.name).cartoonTitle(size: CartoonDimensions.fontBodyLarge)
                        }
                    }
                }
            }
            .padding(CartoonDimensions.spacingMedium + 2)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        if isUnlocked {
            CartoonButton(tint: CartoonColor.leaf, accessibilityLabel: "开始挑战 \(station.displayName)", action: onStart) {
                Text("开始挑战！")
                    .font(.system(size: CartoonDimensions.fontTitle, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                    .frame(width: 240, height: 80)
            }
        } else {
            Text("🔒 还没解锁哦")
                .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.5))
                .padding()
        }

        Button(action: onDismiss) {
            Text("返回")
                .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.75))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("返回")
    }
}
