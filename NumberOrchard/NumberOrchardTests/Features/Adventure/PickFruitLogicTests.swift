import Testing
@testable import NumberOrchard

@Test func pickFruitCorrectCountTriggersSuccess() {
    let question = MathQuestion(operand1: 3, operand2: 2, operation: .add, gameMode: .pickFruit)
    var state = PickFruitGameState(question: question)

    #expect(state.basketCount == 3)
    #expect(state.fruitsOnTree == 2)
    #expect(state.isComplete == false)

    state.pickFruit()
    #expect(state.basketCount == 4)
    #expect(state.fruitsOnTree == 1)
    #expect(state.isComplete == false)

    state.pickFruit()
    #expect(state.basketCount == 5)
    #expect(state.fruitsOnTree == 0)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func pickFruitCannotPickWhenTreeEmpty() {
    let question = MathQuestion(operand1: 2, operand2: 1, operation: .add, gameMode: .pickFruit)
    var state = PickFruitGameState(question: question)

    state.pickFruit()
    #expect(state.isComplete == true)

    state.pickFruit()
    #expect(state.basketCount == 3)
}
