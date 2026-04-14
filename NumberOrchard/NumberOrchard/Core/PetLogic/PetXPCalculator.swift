import Foundation

struct PetXPCalculator: Sendable {
    static let baseXP = 10
    static let preferredMultiplier = 2

    /// Returns XP gained from feeding `fruitId` to the Noom with `noomNumber`.
    /// Preferred fruit → 2x base; everything else (including unknown fruits/noom numbers) → base.
    func xpFor(fruitId: String, noomNumber: Int) -> Int {
        if PetPreferenceMap.isPreferred(fruitId: fruitId, for: noomNumber) {
            return Self.baseXP * Self.preferredMultiplier
        }
        return Self.baseXP
    }
}
