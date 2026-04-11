import Testing
@testable import NumberOrchard

@Test func treeStageProgression() {
    let profile = ChildProfile(name: "Test")
    #expect(profile.treeStage == 0)
    #expect(profile.treeExperience == 0)

    profile.treeExperience = 50
    let stage = TreeGrowthCalculator.stageFor(experience: profile.treeExperience)
    #expect(stage == 0)

    let stage2 = TreeGrowthCalculator.stageFor(experience: 100)
    #expect(stage2 == 1)

    let stage3 = TreeGrowthCalculator.stageFor(experience: 300)
    #expect(stage3 == 2)
}

@Test func experienceGain() {
    let calculator = TreeGrowthCalculator()
    #expect(calculator.experienceForCorrectAnswer(combo: 1) == 10)
    #expect(calculator.experienceForCorrectAnswer(combo: 3) == 15)
    #expect(calculator.experienceForCorrectAnswer(combo: 5) == 15)
}
