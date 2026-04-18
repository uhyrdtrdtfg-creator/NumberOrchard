import Testing
@testable import NumberOrchard

@Test func rhythmRoundCorrectAnswerMatchesOperands() {
    let r = RhythmRound(operand1: 3, operand2: 4, choices: [7, 8, 6])
    #expect(r.correctAnswer == 7)
    #expect(r.displayText.contains("3"))
    #expect(r.displayText.contains("4"))
}

@Test func rhythmGeneratorAlwaysIncludesCorrectAnswer() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<50 {
        let round = RhythmMathGenerator.makeRound(maxTotal: 10, rng: &rng)
        #expect(round.choices.contains(round.correctAnswer))
    }
}

@Test func rhythmGeneratorProducesThreeChoices() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<30 {
        let round = RhythmMathGenerator.makeRound(maxTotal: 10, rng: &rng)
        #expect(round.choices.count == 3)
    }
}

@Test func rhythmGeneratorChoicesAreUnique() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<30 {
        let round = RhythmMathGenerator.makeRound(maxTotal: 10, rng: &rng)
        #expect(Set(round.choices).count == round.choices.count)
    }
}

@Test func rhythmGeneratorRespectsMaxTotal() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<30 {
        let round = RhythmMathGenerator.makeRound(maxTotal: 5, rng: &rng)
        #expect(round.operand1 + round.operand2 <= 5)
        #expect(round.operand1 >= 1 && round.operand2 >= 1)
    }
}
