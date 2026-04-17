import Testing
@testable import NumberOrchard

@Test func diceFastAnswerScoresMax() {
    #expect(DiceQuickMathViewModel.points(for: 1.5, correct: true) == 20)
    #expect(DiceQuickMathViewModel.points(for: 3.0, correct: true) == 20)
}

@Test func diceMediumAnswerScoresMedium() {
    #expect(DiceQuickMathViewModel.points(for: 4.0, correct: true) == 10)
    #expect(DiceQuickMathViewModel.points(for: 6.0, correct: true) == 10)
}

@Test func diceSlowAnswerScoresLow() {
    #expect(DiceQuickMathViewModel.points(for: 10.0, correct: true) == 5)
    #expect(DiceQuickMathViewModel.points(for: 100.0, correct: true) == 5)
}

@Test func diceWrongAnswerScoresZero() {
    #expect(DiceQuickMathViewModel.points(for: 1.0, correct: false) == 0)
    #expect(DiceQuickMathViewModel.points(for: 5.0, correct: false) == 0)
}

@Test func diceStarsThresholds() {
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 0) == 1)
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 25) == 1)
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 40) == 2)
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 79) == 2)
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 80) == 3)
    #expect(DiceQuickMathViewModel.stars(forTotalPoints: 200) == 3)
}
