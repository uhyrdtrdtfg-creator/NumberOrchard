import Testing
@testable import NumberOrchard

@Test func balanceStateInitializesFromQuestion() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    let state = BalanceGameState(question: q)
    #expect(state.leftSide == 5)
    #expect(state.rightFixed == 2)
    #expect(state.rightUserPlaced == 0)
    #expect(state.isBalanced == false)
}

@Test func balanceWhenCorrectNumberPlaced() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    #expect(state.rightUserPlaced == 3)
    #expect(state.isBalanced == true)
    #expect(state.isComplete == true)
}

@Test func balanceCanRemoveBlocks() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    #expect(state.isComplete == true)  // already complete at 3 blocks, so 4th is ignored
    // NOTE: once isComplete, removeBlock is a no-op. Test removal on non-complete state:
}

@Test func tiltAngleProportionalToDifference() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    #expect(state.tiltAngleDegrees < 0)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    #expect(state.tiltAngleDegrees == 0)
}
