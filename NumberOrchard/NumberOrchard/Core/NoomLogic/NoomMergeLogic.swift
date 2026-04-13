import Foundation

struct NoomMergeLogic: Sendable {
    /// Combine two Nooms. Returns nil for invalid inputs (sum > 10 or operands < 1).
    func merge(a: Int, b: Int) -> Int? {
        guard a >= 1, b >= 1, a + b <= 10 else { return nil }
        return a + b
    }
}
