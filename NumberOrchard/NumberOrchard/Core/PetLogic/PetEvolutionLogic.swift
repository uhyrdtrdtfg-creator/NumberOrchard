import Foundation

struct PetEvolutionLogic: Sendable {
    /// Cumulative XP needed for each stage entry.
    /// stage 0 (baby): 0 XP, stage 1 (teen): 100 XP, stage 2 (adult): 300 XP.
    static let stageThresholds = [0, 100, 300]

    func stage(for xp: Int) -> Int {
        for i in stride(from: Self.stageThresholds.count - 1, through: 0, by: -1) {
            if xp >= Self.stageThresholds[i] { return i }
        }
        return 0
    }

    func isMature(xp: Int) -> Bool {
        stage(for: xp) >= 2
    }

    /// If two mature small Nooms (1-10) sum to 11-20, returns the resulting big-Noom number.
    /// Returns nil for invalid combinations.
    func canHatch(matureNoomA: Int, matureNoomB: Int) -> Int? {
        let sum = matureNoomA + matureNoomB
        guard (11...20).contains(sum) else { return nil }
        return sum
    }
}
