import SwiftUI

/// Celebratory banner shown when a correct answer rolls into a legendary
/// fruit drop. Used by PetTheater and DiceQuickMath; the owning view
/// model exposes `lastLegendaryDrop: FruitItem?` and the host view
/// overlays this banner when non-nil.
struct LegendaryDropBanner: View {
    let fruit: FruitItem

    var body: some View {
        VStack(spacing: 10) {
            Text("✨ 稀有掉落! ✨")
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.ink)
            Text(fruit.emoji).font(.system(size: 72))
            Text(fruit.name)
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.ink)
            Text(fruit.funFact)
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.ink.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(CartoonColor.ink.opacity(0.9)).offset(y: 6)
                RoundedRectangle(cornerRadius: 28).fill(CartoonColor.gold)
                RoundedRectangle(cornerRadius: 28).stroke(CartoonColor.ink, lineWidth: 4)
            }
        )
        .padding(.horizontal, 40)
    }
}
