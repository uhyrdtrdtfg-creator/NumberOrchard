import Testing
@testable import NumberOrchard

@Test func seedLevelGeneratesAdditionOnly() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)

    for _ in 0..<20 {
        let question = generator.generate(for: profile)
        #expect(question.operation == .add)
        #expect(question.gameMode == .pickFruit)
        #expect(question.operand1 + question.operand2 <= 5)
        #expect(question.operand1 >= 1)
        #expect(question.operand2 >= 1)
    }
}

@Test func sproutLevelIncludesSubtraction() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .sprout, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        if question.operation == .add { hasAdd = true }
        if question.operation == .subtract { hasSub = true }
        #expect(question.correctAnswer >= 0)
        #expect(question.correctAnswer <= 5)
        #expect(question.operand1 <= 5)
    }
    #expect(hasAdd == true)
    #expect(hasSub == true)
}

@Test func smallTreeLevelAdditionUpToTen() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .smallTree, subDifficulty: 3)

    for _ in 0..<20 {
        let question = generator.generate(for: profile)
        #expect(question.operation == .add)
        #expect(question.correctAnswer <= 10)
        #expect(question.operand1 >= 1)
        #expect(question.operand2 >= 1)
    }
}

@Test func bigTreeLevelMixedUpToTen() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        if question.operation == .add { hasAdd = true }
        if question.operation == .subtract { hasSub = true }
        #expect(question.correctAnswer >= 0)
        #expect(question.correctAnswer <= 10)
        #expect(question.operand1 <= 10)
    }
    #expect(hasAdd == true)
    #expect(hasSub == true)
}

@Test func subtractionNeverProducesNegativeResult() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 5)

    for _ in 0..<100 {
        let question = generator.generate(for: profile)
        if question.operation == .subtract {
            #expect(question.operand1 >= question.operand2)
        }
    }
}

@Test func gameModeMatchesOperation() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .sprout, subDifficulty: 3)

    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        switch question.operation {
        case .add:
            #expect(question.gameMode == .pickFruit)
        case .subtract:
            #expect(question.gameMode == .shareFruit)
        }
    }
}
