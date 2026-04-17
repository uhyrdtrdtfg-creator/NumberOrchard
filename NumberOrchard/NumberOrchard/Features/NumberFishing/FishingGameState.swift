import Foundation

/// Pure state for ONE round of 数字钓鱼 — a pond contains numbered fish, the
/// child drags fish into a bucket, the bucket should sum to `target`.
///
/// Session progression (multiple rounds, scoring) is owned by the view
/// model; this struct is just the single-round immutable-target state.
struct FishingGameState: Sendable, Equatable {
    let target: Int
    /// Values of fish currently still swimming in the pond. Nil slots are
    /// empty (kept for stable indexing so on-screen fish don't jump around
    /// when a neighbour is caught).
    private(set) var pondFish: [Int?]
    /// Values of fish the child has placed in the bucket.
    private(set) var bucketFish: [Int] = []

    var bucketSum: Int { bucketFish.reduce(0, +) }
    var isComplete: Bool { bucketSum == target && !bucketFish.isEmpty }
    /// Over-filled: child placed fish that overshot the target. View can
    /// show a gentle "try releasing some" hint.
    var isOverfilled: Bool { bucketSum > target }
    /// Number of fish currently visible in the pond (non-nil slots).
    var pondCount: Int { pondFish.compactMap { $0 }.count }

    /// Build a pond with at least one combination that sums to `target`.
    /// Seeds a guaranteed (a, target-a) pair, then adds 3-5 distractors.
    static func makePond(
        target: Int,
        rng: inout some RandomNumberGenerator
    ) -> [Int] {
        var fish: [Int] = []
        let upper = min(9, target - 1)
        if upper >= 1 {
            let a = Int.random(in: 1...upper, using: &rng)
            fish.append(a)
            fish.append(target - a)
        }
        let distractors = Int.random(in: 3...5, using: &rng)
        for _ in 0..<distractors {
            fish.append(Int.random(in: 1...9, using: &rng))
        }
        fish.shuffle(using: &rng)
        return fish
    }

    init(target: Int, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.target = target
        var rng = SeededRNG(seed: seed)
        self.pondFish = Self.makePond(target: target, rng: &rng).map { $0 as Int? }
    }

    /// Move the fish at `pondIndex` from pond to bucket.
    mutating func catchFish(at pondIndex: Int) {
        guard pondIndex >= 0, pondIndex < pondFish.count,
              let v = pondFish[pondIndex] else { return }
        pondFish[pondIndex] = nil
        bucketFish.append(v)
    }

    /// Dump a fish back into the pond (undo).
    @discardableResult
    mutating func release(bucketIndex: Int) -> Bool {
        guard bucketIndex >= 0, bucketIndex < bucketFish.count else { return false }
        let v = bucketFish.remove(at: bucketIndex)
        if let emptyIdx = pondFish.firstIndex(where: { $0 == nil }) {
            pondFish[emptyIdx] = v
        } else {
            pondFish.append(v)
        }
        return true
    }
}
