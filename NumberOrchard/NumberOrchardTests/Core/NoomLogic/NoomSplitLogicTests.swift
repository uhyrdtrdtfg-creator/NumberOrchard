import Testing
import CoreFoundation
@testable import NumberOrchard

@Test func splitMapsDragDistanceToRatio() {
    let logic = NoomSplitLogic()
    let r1 = logic.splitFor(total: 5, dragDistance: 5)
    #expect(r1?.0 == 1 && r1?.1 == 4)
    let r2 = logic.splitFor(total: 5, dragDistance: 30)
    #expect(r2?.0 == 2 && r2?.1 == 3)
    let r3 = logic.splitFor(total: 5, dragDistance: 80)
    #expect(r3?.0 == 4 && r3?.1 == 1)
}

@Test func splitClampsToMinFirst() {
    let logic = NoomSplitLogic()
    let r = logic.splitFor(total: 5, dragDistance: 0)
    #expect(r?.0 == 1 && r?.1 == 4)
}

@Test func splitClampsToMaxLast() {
    let logic = NoomSplitLogic()
    let r = logic.splitFor(total: 5, dragDistance: 200)
    #expect(r?.0 == 4 && r?.1 == 1)
}

@Test func splitRejectsInvalidTotal() {
    let logic = NoomSplitLogic()
    #expect(logic.splitFor(total: 1, dragDistance: 50) == nil)
    #expect(logic.splitFor(total: 0, dragDistance: 50) == nil)
    #expect(logic.splitFor(total: 11, dragDistance: 50) == nil)
}

@Test func allSplitsEnumerated() {
    let logic = NoomSplitLogic()
    let splits = logic.allSplits(of: 5)
    let pairs = splits.map { "\($0.0)+\($0.1)" }.sorted()
    #expect(pairs == ["1+4", "2+3", "3+2", "4+1"])
}

@Test func allSplitsEmptyForLessThanTwo() {
    let logic = NoomSplitLogic()
    #expect(logic.allSplits(of: 1).isEmpty)
    #expect(logic.allSplits(of: 0).isEmpty)
}
