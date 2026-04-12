import Testing
@testable import NumberOrchard

@Test func trainGameStateInitializesFromQuestion() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    let state = NumberTrainGameState(question: q)
    #expect(state.totalSeats == 10)
    #expect(state.occupiedSeats == 6)
    #expect(state.emptySeats == 4)
    #expect(state.userInput == nil)
    #expect(state.isComplete == false)
}

@Test func trainCorrectAnswerMarksComplete() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    state.submitAnswer(4)
    #expect(state.userInput == 4)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func trainWrongAnswerDoesNotLock() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    state.submitAnswer(3)
    #expect(state.isCorrect == false)
    #expect(state.isComplete == false)
}

@Test func trainCountingModeFillsEmptySeatsOneByOne() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    state.tapEmptySeat()
    state.tapEmptySeat()
    #expect(state.countedSeats == 2)
    state.tapEmptySeat()
    state.tapEmptySeat()
    #expect(state.countedSeats == 4)
    state.commitCountedAnswer()
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}
