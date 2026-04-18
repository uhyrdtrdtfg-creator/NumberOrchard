import SwiftUI

/// A cartoon-framed fruit icon — the system emoji sits inside a paper
/// disc with an ink outline and a hard drop shadow, matching the rest
/// of the app's sticker look. Wraps emoji so they feel like part of
/// the world instead of borrowed OS glyphs.
struct FruitBadge: View {
    let fruitId: String
    var size: CGFloat = 64
    var showGlow: Bool = false   // highlight when preferred / matching
    var showCount: Int? = nil    // optional "×3" badge for basket items

    private var emoji: String {
        FruitCatalog.fruit(id: fruitId)?.emoji ?? "❓"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: size, height: size).offset(y: size * 0.05)
                Circle().fill(showGlow ? CartoonColor.gold.opacity(0.35) : CartoonColor.paper)
                    .frame(width: size, height: size)
                Circle()
                    .stroke(showGlow ? CartoonColor.coral : CartoonColor.ink.opacity(0.7),
                            lineWidth: showGlow ? 3 : 2.5)
                    .frame(width: size, height: size)
                Text(emoji)
                    .font(.system(size: size * 0.72))
            }
            if let count = showCount, count > 0 {
                Text("×\(count)")
                    .font(CartoonFont.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(CartoonColor.coral))
                    .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 1.5))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

