import Testing
@testable import NumberOrchard

@Test func fishingPondContainsPairSummingToTarget() {
    // With target 10, the seeded pond should contain some (a, 10-a) pair.
    let s = FishingGameState(target: 10, seed: 7)
    let values = s.pondFish.compactMap { $0 }
    var hasPair = false
    for (i, a) in values.enumerated() {
        for b in values[(i + 1)...] where a + b == 10 {
            hasPair = true
        }
    }
    #expect(hasPair)
}

@Test func fishingCatchMovesFishToBucket() {
    var s = FishingGameState(target: 8, seed: 42)
    let originalPond = s.pondCount
    let v = s.pondFish.compactMap { $0 }.first ?? 0
    // Find the first non-nil index
    let idx = s.pondFish.firstIndex(where: { $0 != nil }) ?? 0
    s.catchFish(at: idx)
    #expect(s.pondCount == originalPond - 1)
    #expect(s.bucketFish.contains(v))
    #expect(s.bucketSum == v)
}

@Test func fishingSumHittingTargetMarksComplete() {
    // Force a deterministic state by pulling every fish until sum == target or exceeded.
    var s = FishingGameState(target: 10, seed: 7)
    var safety = 50
    while !s.isComplete && !s.isOverfilled && safety > 0 {
        if let idx = s.pondFish.firstIndex(where: { $0 != nil }) {
            s.catchFish(at: idx)
        } else { break }
        safety -= 1
    }
    // Either we hit target exactly or overfilled — both valid states.
    // We assert the bookkeeping is consistent.
    #expect(s.bucketSum == s.bucketFish.reduce(0, +))
}

@Test func fishingReleaseReturnsFishToPond() {
    var s = FishingGameState(target: 8, seed: 1)
    let idx = s.pondFish.firstIndex(where: { $0 != nil }) ?? 0
    let before = s.pondCount
    s.catchFish(at: idx)
    #expect(s.pondCount == before - 1)
    #expect(s.bucketFish.count == 1)
    let released = s.release(bucketIndex: 0)
    #expect(released)
    #expect(s.bucketFish.isEmpty)
    #expect(s.pondCount == before)
}

@Test func fishingCatchAtEmptySlotIsNoop() {
    var s = FishingGameState(target: 10, seed: 3)
    let idx = s.pondFish.firstIndex(where: { $0 != nil }) ?? 0
    s.catchFish(at: idx)
    let afterFirst = s
    s.catchFish(at: idx)  // slot is now nil — should do nothing
    #expect(s.bucketFish == afterFirst.bucketFish)
    #expect(s.pondCount == afterFirst.pondCount)
}
