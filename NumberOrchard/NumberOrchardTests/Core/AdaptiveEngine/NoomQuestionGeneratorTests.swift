import Testing
@testable import NumberOrchard

@Test func sessionHasFiveQuestions() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    #expect(session.count == 5)
}

@Test func sessionHasOneSplitQuestion() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    let splitCount = session.filter { if case .split = $0 { return true } else { return false } }.count
    #expect(splitCount == 1)
}

@Test func sessionHasFourMergeQuestions() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    let mergeCount = session.filter { if case .merge = $0 { return true } else { return false } }.count
    #expect(mergeCount == 4)
}

@Test func mergeQuestionsRespectSumLimits() {
    let gen = NoomQuestionGenerator()
    for _ in 0..<20 {
        let session = gen.generateSession(alreadyUnlocked: [])
        for (idx, q) in session.enumerated() {
            if case .merge(let a, let b) = q {
                #expect(a >= 1 && b >= 1)
                let sum = a + b
                if idx < 2 {
                    #expect(sum <= 5, "Q\(idx+1) merge \(a)+\(b)=\(sum) should be ≤ 5")
                } else {
                    #expect(sum <= 10, "Q\(idx+1) merge \(a)+\(b)=\(sum) should be ≤ 10")
                }
            }
        }
    }
}

@Test func splitQuestionInRange() {
    let gen = NoomQuestionGenerator()
    for _ in 0..<10 {
        let session = gen.generateSession(alreadyUnlocked: [])
        for q in session {
            if case .split(let total) = q {
                #expect((3...5).contains(total), "split total \(total) should be in 3...5")
            }
        }
    }
}

@Test func challengeTypesEquatable() {
    #expect(NoomChallengeType.merge(a: 2, b: 3) == .merge(a: 2, b: 3))
    #expect(NoomChallengeType.merge(a: 2, b: 3) != .merge(a: 3, b: 2))
    #expect(NoomChallengeType.split(total: 5) != .merge(a: 2, b: 3))
}
