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
                // Dreamy gold halo radiating outward when this fruit is
                // a preferred favourite. Softer than the old solid-fill
                // glow ring it replaces.
                if showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CartoonColor.gold.opacity(0.85),
                                         CartoonColor.gold.opacity(0.0)],
                                center: .center,
                                startRadius: size * 0.35,
                                endRadius: size * 0.85
                            )
                        )
                        .frame(width: size * 1.4, height: size * 1.4)
                        .blur(radius: 4)
                }
                // Hard ink shadow keeps the sticker silhouette crisp.
                Circle().fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: size, height: size).offset(y: size * 0.05)
                // Inner fill with a subtle top sheen so the badge reads
                // like a polished button.
                Circle()
                    .fill(
                        LinearGradient(
                            colors: showGlow
                                ? [Color.white.opacity(0.9), CartoonColor.paperWarm]
                                : [Color.white.opacity(0.85), CartoonColor.paper],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
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

