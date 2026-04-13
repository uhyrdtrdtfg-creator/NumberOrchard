import SwiftUI

/// A single decoration rendered in the orchard — consistent sizing by category, ink shadow,
/// optional subtle idle wiggle. Use inside a `ZStack` with `.position(...)` applied by the parent.
struct PlacedDecorationView: View {
    let emoji: String
    let size: CGFloat
    var wiggle: Bool = true
    var phaseOffset: Double = 0

    @State private var wiggling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .cartoonInkShadow(y: max(2, size * 0.06))
            .rotationEffect(.degrees(rotation))
            .animation(
                (wiggle && !reduceMotion)
                    ? .easeInOut(duration: 2.4 + phaseOffset.truncatingRemainder(dividingBy: 1.0))
                        .repeatForever(autoreverses: true)
                        .delay(phaseOffset)
                    : nil,
                value: wiggling
            )
            .onAppear { wiggling = true }
    }

    private var rotation: Double {
        guard wiggle, !reduceMotion else { return 0 }
        return wiggling ? 4 : -4
    }
}

/// Maps a decoration's `positionY` (0-1, 0 = back of band) to a Z value used for depth sorting.
/// Larger Y ⇒ closer to the viewer ⇒ drawn on top.
func orchardDepthZ(for positionY: Double) -> Double { positionY }
