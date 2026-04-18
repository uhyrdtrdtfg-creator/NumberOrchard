import Testing
@testable import NumberOrchard

@Test func mazeGeneratorProducesReachableTarget() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<20 {
        let grid = MazeGridGenerator.make(rng: &rng)
        #expect(grid.rows == 5 && grid.cols == 5)
        #expect(grid.start == MazeGrid.Cell(r: 0, c: 0))
        #expect(grid.exit == MazeGrid.Cell(r: 4, c: 4))
        // Target must be at least the minimum monotone path length (5 cells
        // with values 1-9 each, so ≥ 9 and ≤ 81).
        #expect(grid.target >= 9 && grid.target <= 81)
    }
}

@Test func mazeTapStartBeginsPath() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    let result = grid.tap(0, 0)
    #expect(result == .advanced)
    #expect(grid.path.count == 1)
}

@Test func mazeNonAdjacentTapRejected() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    _ = grid.tap(0, 0)
    let result = grid.tap(3, 3)
    #expect(result == .notAdjacent)
    #expect(grid.path.count == 1)
}

@Test func mazeAdjacentTapExtends() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    _ = grid.tap(0, 0)
    let result = grid.tap(0, 1)
    #expect(result == .advanced)
    #expect(grid.path.count == 2)
}

@Test func mazeTapPreviousBacktracks() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    _ = grid.tap(0, 0)
    _ = grid.tap(0, 1)
    let result = grid.tap(0, 0)
    #expect(result == .backtracked)
    #expect(grid.path.count == 1)
}

@Test func mazeAlreadyVisitedTapRejected() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    // Walk a loop: (0,0) → (1,0) → (1,1) → (0,1). Tip is (0,1). (0,0)
    // is adjacent to (0,1) and already in the path (at index 0, not
    // previous) — must reject with .alreadyInPath.
    _ = grid.tap(0, 0)
    _ = grid.tap(1, 0)
    _ = grid.tap(1, 1)
    _ = grid.tap(0, 1)
    let result = grid.tap(0, 0)
    #expect(result == .alreadyInPath)
}

@Test func mazePathSumTracksCells() {
    var rng = SystemRandomNumberGenerator()
    var grid = MazeGridGenerator.make(rng: &rng)
    _ = grid.tap(0, 0)
    _ = grid.tap(0, 1)
    let expected = grid.cells[0][0] + grid.cells[0][1]
    #expect(grid.pathSum == expected)
}

@Test func mazeIsCompleteRequiresExitAndTarget() {
    // Construct a tiny 2×1 grid manually to exercise isComplete without
    // depending on randomness. cells: [[3], [7]], target 10, path = both.
    var grid = MazeGrid(
        rows: 2, cols: 1,
        cells: [[3], [7]],
        start: MazeGrid.Cell(r: 0, c: 0),
        exit: MazeGrid.Cell(r: 1, c: 0),
        target: 10
    )
    #expect(grid.isComplete == false)
    _ = grid.tap(0, 0)
    #expect(grid.isComplete == false)  // at start, not at exit
    _ = grid.tap(1, 0)
    #expect(grid.isComplete == true)
}

@Test func mazeOverstepIsDetected() {
    var grid = MazeGrid(
        rows: 1, cols: 3,
        cells: [[9, 9, 9]],
        start: MazeGrid.Cell(r: 0, c: 0),
        exit: MazeGrid.Cell(r: 0, c: 2),
        target: 12
    )
    _ = grid.tap(0, 0)
    _ = grid.tap(0, 1)
    // pathSum is 18, target is 12, not at exit yet
    #expect(grid.isOverstepped == true)
}
