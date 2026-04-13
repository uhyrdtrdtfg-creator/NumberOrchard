import Foundation
import CoreFoundation

struct NoomSplitLogic: Sendable {
    /// Map drag distance (pt) to a (left, right) split where left + right == total.
    /// Drag range 0–90pt mapped to (total-1) segments.
    func splitFor(total: Int, dragDistance: CGFloat) -> (Int, Int)? {
        guard (2...10).contains(total) else { return nil }
        let segments = total - 1
        let segmentSize = 90.0 / CGFloat(segments)
        let raw = Int(dragDistance / segmentSize) + 1
        let idx = min(segments, max(1, raw))
        return (idx, total - idx)
    }

    /// All legal (a, b) splits where a + b == n and both ≥ 1.
    func allSplits(of n: Int) -> [(Int, Int)] {
        guard n >= 2 else { return [] }
        return (1..<n).map { ($0, n - $0) }
    }
}
