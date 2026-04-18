import SwiftUI

/// Tactile press feedback for small buttons that aren't wrapped in
/// `CartoonButton`. Applies a subtle scale + offset so the whole app
/// reads "cartoon-press" instead of system-default. Pair with
/// `Haptics.tap()` on the action for the full effect.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    var pressDepth: CGFloat = 2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
            .offset(y: configuration.isPressed && !reduceMotion ? pressDepth : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}
