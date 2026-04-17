import UIKit

/// Per-Noom personality traits used by NoomRenderer to differentiate the
/// 20 creatures beyond just body color. Maps each Noom number deterministically
/// to a face archetype so the same Noom always renders identically.
struct NoomPersonality: Sendable {
    enum EyeShape: Sendable { case round, sparkle, sleepy, sharp }
    enum BrowShape: Sendable { case none, soft, arched, stern }
    enum Accessory: Sendable { case none, freckles, star, heart }

    let eye: EyeShape
    let brow: BrowShape
    let accessory: Accessory
    /// Spacing between eyes as a fraction of body diameter (0.18-0.32 typical).
    let eyeSpacing: CGFloat
    /// Vertical position of eye centers as a fraction of body height (0.35-0.5).
    let eyeY: CGFloat

    static func forNoom(_ number: Int) -> NoomPersonality {
        switch number {
        // Small Nooms 1-10 — most cheerful, varied softness
        case 1:  return .init(eye: .sparkle, brow: .soft, accessory: .heart, eyeSpacing: 0.22, eyeY: 0.42)
        case 2:  return .init(eye: .round, brow: .soft, accessory: .freckles, eyeSpacing: 0.24, eyeY: 0.44)
        case 3:  return .init(eye: .sparkle, brow: .arched, accessory: .none, eyeSpacing: 0.22, eyeY: 0.42)
        case 4:  return .init(eye: .round, brow: .arched, accessory: .freckles, eyeSpacing: 0.26, eyeY: 0.44)
        case 5:  return .init(eye: .sleepy, brow: .soft, accessory: .none, eyeSpacing: 0.24, eyeY: 0.45)
        case 6:  return .init(eye: .sharp, brow: .arched, accessory: .none, eyeSpacing: 0.26, eyeY: 0.42)
        case 7:  return .init(eye: .sparkle, brow: .arched, accessory: .star, eyeSpacing: 0.24, eyeY: 0.42)
        case 8:  return .init(eye: .sleepy, brow: .none, accessory: .none, eyeSpacing: 0.28, eyeY: 0.46)
        case 9:  return .init(eye: .round, brow: .arched, accessory: .none, eyeSpacing: 0.26, eyeY: 0.42)
        case 10: return .init(eye: .sharp, brow: .stern, accessory: .star, eyeSpacing: 0.28, eyeY: 0.40)

        // Big Nooms 11-20 — more regal/powerful
        case 11: return .init(eye: .sharp, brow: .arched, accessory: .none, eyeSpacing: 0.26, eyeY: 0.42)
        case 12: return .init(eye: .round, brow: .stern, accessory: .freckles, eyeSpacing: 0.28, eyeY: 0.44)
        case 13: return .init(eye: .sparkle, brow: .arched, accessory: .star, eyeSpacing: 0.26, eyeY: 0.42)
        case 14: return .init(eye: .sleepy, brow: .arched, accessory: .none, eyeSpacing: 0.28, eyeY: 0.44)
        case 15: return .init(eye: .sharp, brow: .stern, accessory: .none, eyeSpacing: 0.28, eyeY: 0.40)
        case 16: return .init(eye: .sparkle, brow: .stern, accessory: .star, eyeSpacing: 0.26, eyeY: 0.42)
        case 17: return .init(eye: .round, brow: .arched, accessory: .heart, eyeSpacing: 0.26, eyeY: 0.42)
        case 18: return .init(eye: .sharp, brow: .stern, accessory: .star, eyeSpacing: 0.28, eyeY: 0.40)
        case 19: return .init(eye: .sparkle, brow: .arched, accessory: .star, eyeSpacing: 0.26, eyeY: 0.42)
        case 20: return .init(eye: .sharp, brow: .stern, accessory: .heart, eyeSpacing: 0.28, eyeY: 0.40)

        default: return .init(eye: .round, brow: .soft, accessory: .none, eyeSpacing: 0.24, eyeY: 0.44)
        }
    }
}
