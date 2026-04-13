import Testing
@testable import NumberOrchard

@Test func mergeValidPairsReturnsSum() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 1, b: 1) == 2)
    #expect(logic.merge(a: 2, b: 3) == 5)
    #expect(logic.merge(a: 4, b: 6) == 10)
}

@Test func mergeRejectsZeroOrNegative() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 0, b: 3) == nil)
    #expect(logic.merge(a: 3, b: 0) == nil)
    #expect(logic.merge(a: -1, b: 5) == nil)
}

@Test func mergeRejectsSumOverTen() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 5, b: 6) == nil)
    #expect(logic.merge(a: 9, b: 9) == nil)
    #expect(logic.merge(a: 10, b: 1) == nil)
}

@Test func mergeIsCommutative() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 3, b: 4) == logic.merge(a: 4, b: 3))
}
