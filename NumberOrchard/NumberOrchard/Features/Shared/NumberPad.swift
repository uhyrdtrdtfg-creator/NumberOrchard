import SwiftUI

/// A 4-row number pad (1-9, then 清 / 0 / ✓). Extracted so PetTheater
/// and DiceQuickMath share a single implementation — before this,
/// each view re-implemented the whole pad with subtly drifting colors,
/// tile sizes, and press animations.
///
/// Behaviour:
///   - `onDigit(Int)` fires when a 0-9 key is tapped (clamped to `maxDigits`
///     by the caller — the pad itself doesn't hold state)
///   - `onClear()` fires when 清 is tapped
///   - `onSubmit()` fires when ✓ is tapped
///   - `disabled: true` greys out the pad (e.g. during a dice roll)
struct NumberPad: View {
    var disabled: Bool = false
    let onDigit: (Int) -> Void
    let onClear: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        padKey("\(n)") { onDigit(n) }
                    }
                }
            }
            HStack(spacing: 10) {
                padKey("清", tint: CartoonColor.coral) { onClear() }
                padKey("0") { onDigit(0) }
                padKey("✓", tint: CartoonColor.leaf) { onSubmit() }
            }
        }
        .opacity(disabled ? 0.55 : 1.0)
        .allowsHitTesting(!disabled)
    }

    private func padKey(
        _ label: String,
        tint: Color = CartoonColor.paper,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 76, height: 60).offset(y: 3)
                RoundedRectangle(cornerRadius: 18).fill(tint)
                    .frame(width: 76, height: 60)
                RoundedRectangle(cornerRadius: 18)
                    .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                    .frame(width: 76, height: 60)
                Text(label)
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(tint == CartoonColor.paper ? CartoonColor.text : .white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
