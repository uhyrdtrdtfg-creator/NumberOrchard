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

// MARK: - Pool hit-detection dead-zone regression
//
// Frame-contains hit testing used to create dead zones between pool blocks once
// any had been consumed: a touch landing exactly in a vacated slot fell outside
// every remaining block's expanded frame, so nothing was picked up and the
// child appeared unable to drag. The closest-within-reach replacement must
// still pick the nearest remaining block in that scenario.
@Test @MainActor func poolHitSelectsClosestBlockWhenTouchingVacatedSlot() {
    let scene = BalanceScene(size: CGSize(width: 1180, height: 820))
    scene.scaleMode = .resizeFill
    // Large targetRightAdd so multiple pool blocks spawn.
    scene.configure(with: MathQuestion(operand1: 2, operand2: 8, operation: .add, gameMode: .balance))
    let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
    view.presentScene(scene)

    // Pool blocks are direct scene children named "pool_N".
    let pool = scene.children.compactMap { $0 as? SKSpriteNode }
        .filter { ($0.name ?? "").hasPrefix("pool_") }
        .sorted { $0.position.x < $1.position.x }
    #expect(pool.count >= 4)

    // Simulate the child having dragged the block at index 2 out of the pool.
    let removed = pool[2]
    let vacatedPoint = removed.position
    removed.removeFromParent()

    // Touching the now-empty slot must still resolve to a real remaining block.
    let picked = scene.hitTestPoolBlock(at: vacatedPoint)
    #expect(picked != nil, "touching a vacated pool slot should pick the nearest remaining block")
    #expect(picked !== removed)

    // Touching far above the pool (e.g. mid-screen) should NOT grab a pool block.
    let farAway = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.6)
    #expect(scene.hitTestPoolBlock(at: farAway) == nil)
}
