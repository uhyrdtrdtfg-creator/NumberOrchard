import Foundation

/// Pure stateless logic for "easter egg" legendary fruit drops. After any
/// correct answer in a mini-game, callers roll once — if it hits, a random
/// legendary fruit is returned and the view layer is expected to add it to
/// the child profile's collection and show a celebration overlay.
enum LegendaryDropRoll {
    /// Default 1% drop rate. Low enough to feel rare, high enough a child
    /// will see one in a typical play session of ~20-30 correct answers.
    static let defaultRate: Double = 0.01

    /// Candidate pool: every fruit flagged `.legendary` in the catalog.
    static var eligibleFruits: [FruitItem] {
        FruitCatalog.fruits(rarity: .legendary)
    }

    /// Roll once. Returns a legendary fruit if the roll succeeds, else nil.
    /// The `rate` override + injectable RNG make this deterministically
    /// testable without wall-clock randomness.
    static func roll(
        rate: Double = defaultRate,
        rng: inout some RandomNumberGenerator
    ) -> FruitItem? {
        let r = Double.random(in: 0..<1, using: &rng)
        guard r < rate else { return nil }
        let pool = eligibleFruits
        guard !pool.isEmpty else { return nil }
        return pool.randomElement(using: &rng)
    }
}
