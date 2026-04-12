import Testing
@testable import NumberOrchard

@Test func subDifficultyIncreasesAfterThreeCorrect() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 1)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 1)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 2)
}

@Test func subDifficultyDecreasesAfterTwoWrong() {
    var profile = LearningProfile(currentLevel: .smallTree, subDifficulty: 3)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 3)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 2)
}

@Test func subDifficultyDoesNotGoBelowOne() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 1)
}

@Test func subDifficultyDoesNotGoAboveFive() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 5)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 5)
}

@Test func levelPromotionWhenAccuracyMet() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 3)
    profile.levelQuestionCount = 10
    profile.levelCorrectCount = 9

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == true)
}

@Test func noPromotionWhenTooFewQuestions() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 3)
    profile.levelQuestionCount = 5
    profile.levelCorrectCount = 5

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false)
}

@Test func noPromotionAtMaxLevel() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .harvest, subDifficulty: 5)
    profile.levelQuestionCount = 20
    profile.levelCorrectCount = 20

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false) // harvest is the true max (L6)
}

@Test func promotionFromBigTreeToBloom() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 3)
    profile.levelQuestionCount = 10
    profile.levelCorrectCount = 8  // 80% > 70% threshold

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == true)

    let newProfile = manager.promote(profile: profile)
    #expect(newProfile.currentLevel == .bloom)
}
