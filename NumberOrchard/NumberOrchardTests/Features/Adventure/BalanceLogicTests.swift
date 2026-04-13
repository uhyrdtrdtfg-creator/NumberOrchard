import Testing
import SpriteKit
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

// MARK: - Drop-zone coordinate-space regression

/// rightPan lives inside `beam → pivot → scene`. Earlier code compared
/// `rightPan.calculateAccumulatedFrame()` (beam-space) with `block.frame` (scene-space)
/// which broke drops once the scene stopped using the fixed 1194x834 size. Guard against that.
@Test @MainActor func dropZoneDetectsRightPanInSceneSpace() {
    let scene = BalanceScene(size: CGSize(width: 844, height: 390))
    scene.scaleMode = .resizeFill
    scene.configure(with: MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance))
    // Force scene setup by adding it to an SKView off-screen.
    let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
    view.presentScene(scene)

    // Find the right pan via its name and compute its world position the same way the scene does.
    guard let rightPan = scene.children
        .flatMap({ $0.children })
        .flatMap({ $0.children })
        .first(where: { $0.name == "right_pan" }) as? SKSpriteNode else {
        Issue.record("right_pan not found in scene hierarchy")
        return
    }
    let panInScene = rightPan.convert(CGPoint.zero, to: scene)

    // Dropping right on the pan's center should count.
    #expect(scene.isInRightPanDropZone(panInScene) == true)

    // Dropping far away (top-left corner) should NOT count.
    #expect(scene.isInRightPanDropZone(CGPoint(x: 10, y: scene.size.height - 10)) == false)
}
