import Foundation

/// Pure state for 数字迷宫 — a rows×cols grid of numbered cells. The
/// child starts at `start`, must reach `exit` by tapping orthogonally
/// adjacent cells, and the accumulated path sum must equal `target` at
/// the exit. Overshoot is allowed mid-path but prevents a successful
/// exit — the view shows a gentle "too much" hint and lets the child
/// tap the last step to backtrack.
struct MazeGrid: Sendable, Equatable {
    let rows: Int
    let cols: Int
    let cells: [[Int]]
    let start: Cell
    let exit: Cell
    let target: Int
    private(set) var path: [Cell] = []

    struct Cell: Sendable, Equatable, Hashable {
        let r: Int
        let c: Int
    }

    enum TapResult: Sendable, Equatable {
        case advanced
        case backtracked
        case notAdjacent
        case alreadyInPath
        case noop
    }

    var pathSum: Int {
        path.map { cells[$0.r][$0.c] }.reduce(0, +)
    }

    /// True when the path terminates at the exit cell with a sum equal
    /// to the target. View uses this to enable the "完成" button.
    var isComplete: Bool {
        path.last == exit && pathSum == target
    }

    /// True when the path's running sum already exceeds the target and
    /// the child hasn't reached the exit yet. View surfaces a hint.
    var isOverstepped: Bool {
        pathSum > target && path.last != exit
    }

    func value(at cell: Cell) -> Int {
        cells[cell.r][cell.c]
    }

    static func isAdjacent(_ a: Cell, _ b: Cell) -> Bool {
        let dr = abs(a.r - b.r), dc = abs(a.c - b.c)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    /// Clear the path back to empty so the child can try a different
    /// route from scratch.
    mutating func resetPath() {
        path.removeAll()
    }

    /// Tap a cell: extend the path if adjacent to the current tip, or
    /// pop back one step if tapping the previous cell. Ignores any tap
    /// on the starting cell once the path is underway.
    @discardableResult
    mutating func tap(_ r: Int, _ c: Int) -> TapResult {
        guard r >= 0, r < rows, c >= 0, c < cols else { return .noop }
        let cell = Cell(r: r, c: c)
        // Tap the starting cell once to begin the path.
        if path.isEmpty {
            if cell == start {
                path = [start]
                return .advanced
            }
            return .noop
        }
        // Tap current cell → no-op (tip selected already).
        if cell == path.last { return .noop }
        // Tap previous cell → backtrack.
        if path.count >= 2 && cell == path[path.count - 2] {
            path.removeLast()
            return .backtracked
        }
        // Must be adjacent to tip and not already walked.
        guard let tip = path.last, Self.isAdjacent(tip, cell) else { return .notAdjacent }
        if path.contains(cell) { return .alreadyInPath }
        path.append(cell)
        return .advanced
    }
}

enum MazeGridGenerator {
    /// Build a 5×5 grid with random 1-9 values, start at top-left,
    /// exit at bottom-right, and a target that's at least reachable —
    /// computed as the sum along a randomly-walked reference path so
    /// the grid always has at least one solution. The child may find
    /// a different path to the same sum.
    static func make(
        rows: Int = 5, cols: Int = 5,
        rng: inout some RandomNumberGenerator
    ) -> MazeGrid {
        var cells: [[Int]] = Array(
            repeating: Array(repeating: 1, count: cols),
            count: rows
        )
        for r in 0..<rows {
            for c in 0..<cols {
                cells[r][c] = Int.random(in: 1...9, using: &rng)
            }
        }
        let start = MazeGrid.Cell(r: 0, c: 0)
        let exit = MazeGrid.Cell(r: rows - 1, c: cols - 1)

        // Walk a monotone path from start to exit (right/down only) and
        // use its running sum as the target. This guarantees solvability
        // without exposing the exact path to the child.
        var r = 0, c = 0
        var sum = cells[0][0]
        while r != rows - 1 || c != cols - 1 {
            let canRight = c < cols - 1
            let canDown = r < rows - 1
            let goRight: Bool
            if canRight && canDown {
                goRight = Bool.random(using: &rng)
            } else {
                goRight = canRight
            }
            if goRight { c += 1 } else { r += 1 }
            sum += cells[r][c]
        }
        return MazeGrid(
            rows: rows, cols: cols,
            cells: cells, start: start, exit: exit, target: sum
        )
    }
}
