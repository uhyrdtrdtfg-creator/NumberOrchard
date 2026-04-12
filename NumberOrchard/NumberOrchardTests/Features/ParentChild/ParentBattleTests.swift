import Testing
@testable import NumberOrchard

@Test func parentDifficultyScalesWithChildLevel() {
    let gen = ParentQuestionGenerator()
    let q1 = gen.generate(forChildLevel: .seed)
    #expect(q1.correctAnswer >= 0)

    let q6 = gen.generate(forChildLevel: .harvest)
    #expect(q6.parentOperation != nil)
}

@Test func l6ParentIncludesMulDiv() {
    let gen = ParentQuestionGenerator()
    var seenMulDiv = false
    for _ in 0..<30 {
        let q = gen.generate(forChildLevel: .harvest)
        if q.parentOperation == .multiply || q.parentOperation == .divide {
            seenMulDiv = true
            break
        }
    }
    #expect(seenMulDiv == true)
}

@Test func childLevelInBattleMatchesProfile() {
    let gen = ParentQuestionGenerator()
    let kidQ = gen.generateChildQuestion(childLevel: .sprout)
    #expect(kidQ.correctAnswer <= 5)
}
