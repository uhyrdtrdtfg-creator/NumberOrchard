import Testing
import SwiftData
@testable import NumberOrchard

@Test @MainActor func collectedNoomInitDefaults() {
    let cn = CollectedNoom(noomNumber: 5)
    #expect(cn.noomNumber == 5)
    #expect(cn.encounterCount == 1)
}

@Test @MainActor func encounterCountCanBeIncremented() {
    let cn = CollectedNoom(noomNumber: 3)
    cn.encounterCount += 1
    cn.encounterCount += 1
    #expect(cn.encounterCount == 3)
}
