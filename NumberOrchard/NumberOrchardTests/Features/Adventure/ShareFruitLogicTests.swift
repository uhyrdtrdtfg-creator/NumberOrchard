import Testing
@testable import NumberOrchard

@Test func shareFruitCorrectCountTriggersSuccess() {
    let question = MathQuestion(operand1: 8, operand2: 3, operation: .subtract, gameMode: .shareFruit)
    var state = ShareFruitGameState(question: question)

    #expect(state.plateCount == 8)
    #expect(state.givenCount == 0)
    #expect(state.targetGiveCount == 3)
    #expect(state.isComplete == false)

    state.giveFruit()
    state.giveFruit()
    #expect(state.givenCount == 2)
    #expect(state.isComplete == false)

    state.giveFruit()
    #expect(state.givenCount == 3)
    #expect(state.plateCount == 5)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func shareFruitCannotGiveMoreThanTarget() {
    let question = MathQuestion(operand1: 5, operand2: 2, operation: .subtract, gameMode: .shareFruit)
    var state = ShareFruitGameState(question: question)

    state.giveFruit()
    state.giveFruit()
    #expect(state.isComplete == true)

    state.giveFruit()
    #expect(state.givenCount == 2)
    #expect(state.plateCount == 3)
}
