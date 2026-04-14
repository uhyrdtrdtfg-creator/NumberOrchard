import Testing
@testable import NumberOrchard

@Test @MainActor func petProgressInitDefaults() {
    let p = PetProgress(noomNumber: 5)
    #expect(p.noomNumber == 5)
    #expect(p.xp == 0)
    #expect(p.stage == 0)
    #expect(p.matureAt == nil)
    #expect(p.isActive == false)
}

@Test @MainActor func xpCanBeAccumulated() {
    let p = PetProgress(noomNumber: 3)
    p.xp += 50
    p.xp += 50
    #expect(p.xp == 100)
}

@Test @MainActor func stageCanBeUpdated() {
    let p = PetProgress(noomNumber: 1)
    p.stage = 1
    #expect(p.stage == 1)
}
