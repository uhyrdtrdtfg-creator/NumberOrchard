import Testing
@testable import NumberOrchard

@Test func stageAtZeroXPIsBaby() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 0) == 0)
    #expect(logic.stage(for: 50) == 0)
    #expect(logic.stage(for: 99) == 0)
}

@Test func stageAt100XPIsTeen() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 100) == 1)
    #expect(logic.stage(for: 200) == 1)
    #expect(logic.stage(for: 299) == 1)
}

@Test func stageAt300XPIsAdult() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 300) == 2)
    #expect(logic.stage(for: 1000) == 2)
}

@Test func isMatureRequires300XP() {
    let logic = PetEvolutionLogic()
    #expect(logic.isMature(xp: 0) == false)
    #expect(logic.isMature(xp: 299) == false)
    #expect(logic.isMature(xp: 300) == true)
    #expect(logic.isMature(xp: 500) == true)
}

@Test func canHatchReturnsSumIfInElevenToTwenty() {
    let logic = PetEvolutionLogic()
    #expect(logic.canHatch(matureNoomA: 5, matureNoomB: 6) == 11)
    #expect(logic.canHatch(matureNoomA: 10, matureNoomB: 1) == 11)
    #expect(logic.canHatch(matureNoomA: 10, matureNoomB: 10) == 20)
}

@Test func canHatchReturnsNilIfSumOutsideRange() {
    let logic = PetEvolutionLogic()
    #expect(logic.canHatch(matureNoomA: 1, matureNoomB: 2) == nil)
    #expect(logic.canHatch(matureNoomA: 5, matureNoomB: 5) == nil)
    #expect(logic.canHatch(matureNoomA: 11, matureNoomB: 10) == nil)
}
