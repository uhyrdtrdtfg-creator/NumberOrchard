import Testing
@testable import NumberOrchard

@Test func bloomLevelAddsUpToTwenty() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bloom, subDifficulty: 3)

    for _ in 0..<30 {
        let q = generator.generate(for: profile)
        #expect(q.operation == .add)
        #expect(q.correctAnswer <= 20)
        #expect(q.operand1 >= 1)
        #expect(q.operand2 >= 1)
    }
}

@Test func harvestLevelMixesAddSubUpToTwenty() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .harvest, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<60 {
        let q = generator.generate(for: profile)
        #expect(q.correctAnswer >= 0)
        #expect(q.correctAnswer <= 20)
        if q.operation == .add { hasAdd = true }
        if q.operation == .subtract {
            hasSub = true
            #expect(q.operand1 >= q.operand2)
            #expect(q.operand1 >= 11) // L6 subtraction always uses 11-20 minuend
        }
    }
    #expect(hasAdd && hasSub)
}

@Test func lowSubDifficultyAvoidsCarry() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bloom, subDifficulty: 1)
    var noCarryCount = 0
    for _ in 0..<30 {
        let q = generator.generate(for: profile)
        if q.operation == .add {
            let unitsCarry = (q.operand1 % 10 + q.operand2 % 10) >= 10
            if !unitsCarry { noCarryCount += 1 }
        }
    }
    #expect(noCarryCount >= 20)
}
