import UIKit

/// Tiny facade around UIKit feedback generators. Keeps the
/// UIImpactFeedbackGenerator instantiation (which Apple says should be
/// "prepared" ahead of use) in one place and guards every call with a
/// central kill-switch — useful for tests and for a future "reduce
/// haptics" preference.
///
/// All methods are no-ops on devices without a Taptic Engine (iPad,
/// older iPhones) — UIKit handles that silently.
enum Haptics {
    /// Flip to `false` in tests or in a future settings toggle. Main-
    /// actor isolated because haptics are a UIKit (main-thread) concern
    /// and Swift 6 strict concurrency otherwise flags the mutable global.
    @MainActor
    static var isEnabled: Bool = true

    /// Light bump. Use on small UI interactions — tile taps, ball catches.
    @MainActor
    static func tap() {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    /// Heavier thump. Use on important moments — correct answer,
    /// session complete, legendary drop.
    @MainActor
    static func success() {
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }

    /// Gentle shake. Use on wrong answer — never as punishment, just
    /// tactile confirmation that the tap was registered but not
    /// rewarded.
    @MainActor
    static func warning() {
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.warning)
    }

    /// Medium bump. Use on important state changes — evolution,
    /// unlocks, tier-up.
    @MainActor
    static func milestone() {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
    }
}
