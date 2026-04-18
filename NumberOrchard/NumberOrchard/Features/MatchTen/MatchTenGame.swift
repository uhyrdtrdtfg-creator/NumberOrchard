import Foundation

/// Pure game state for 凑十消消乐 — a grid of 1–9 tiles. The child taps two
/// orthogonally adjacent tiles whose values sum to 10; they clear, and a
/// new tile drops into each vacated cell from a refill pool.
///
/// A session is "won" when the player has cleared `targetClears` pairs;
/// ending early is allowed (view layer decides).
struct MatchTenGame: Sendable {
    enum Tile: Sendable, Equatable {
        case empty
        case value(Int)        // 1...9
    }

    let rows: Int
    let cols: Int
    let targetClears: Int

    private(set) var grid: [[Tile]]
    private(set) var clearsMade: Int = 0
    /// Index of the currently-selected cell, or nil if none. A cell is
    /// selected on first tap; a second tap on an adjacent complementary
    /// cell clears the pair.
    private(set) var selected: (Int, Int)? = nil
    /// Consecutive successful clears without an intervening invalid tap.
    /// Resets to 0 on `.invalidPair`. Exposed so the view layer can show
    /// combo badges and the score formula can apply a multiplier.
    private(set) var combo: Int = 0
    /// Total score earned this session. Each clear is worth
    /// `10 * max(1, combo)` — so 1st clear = 10, 2nd = 20, 3rd = 30...
    /// Mistakes reset the combo but don't deduct score.
    private(set) var score: Int = 0

    enum TapResult: Sendable, Equatable {
        case selected
        case deselected
        case invalidPair            // adjacent but wrong sum (resets combo)
        case notAdjacent            // anywhere else (no combo change)
        case cleared(points: Int, combo: Int, clearsSoFar: Int)
        case ignored                 // empty cell tapped
    }

    init(rows: Int = 4, cols: Int = 5, targetClears: Int = 10,
         seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.rows = rows
        self.cols = cols
        self.targetClears = targetClears
        var rng = SeededRNG(seed: seed)
        self.grid = Self.makeGrid(rows: rows, cols: cols, rng: &rng)
    }

    /// Test-only initializer. Lets unit tests construct a game with a
    /// deterministic grid so pair-clearing behaviour can be asserted
    /// against known layouts.
    init(forTestWithGrid values: [[Int]], targetClears: Int = 10) {
        self.rows = values.count
        self.cols = values.first?.count ?? 0
        self.targetClears = targetClears
        self.grid = values.map { row in row.map { Tile.value($0) } }
    }

    static func makeGrid(
        rows: Int, cols: Int,
        rng: inout some RandomNumberGenerator
    ) -> [[Tile]] {
        // Build with guaranteed solvability by seeding pairs that sum to 10.
        // Half of cells are randomized; the other half are their complements
        // placed elsewhere. Any leftover odd cell gets a single random value.
        let total = rows * cols
        var values: [Int] = []
        values.reserveCapacity(total)
        for _ in 0..<(total / 2) {
            let a = Int.random(in: 1...9, using: &rng)
            values.append(a)
            values.append(10 - a)
        }
        if total % 2 != 0 {
            values.append(Int.random(in: 1...9, using: &rng))
        }
        values.shuffle(using: &rng)

        var grid: [[Tile]] = Array(
            repeating: Array(repeating: .empty, count: cols),
            count: rows
        )
        var idx = 0
        for r in 0..<rows {
            for c in 0..<cols {
                grid[r][c] = .value(values[idx])
                idx += 1
            }
        }
        return grid
    }

    /// Are these two cells orthogonally adjacent?
    static func isAdjacent(_ a: (Int, Int), _ b: (Int, Int)) -> Bool {
        let dr = abs(a.0 - b.0), dc = abs(a.1 - b.1)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    func value(at r: Int, _ c: Int) -> Int? {
        guard r >= 0, r < rows, c >= 0, c < cols else { return nil }
        if case .value(let v) = grid[r][c] { return v }
        return nil
    }

    /// Apply a tap at (r, c) with the given refill generator used if a clear
    /// happens. Returns a TapResult describing what transpired.
    @discardableResult
    mutating func tap(
        _ r: Int, _ c: Int,
        rng: inout some RandomNumberGenerator
    ) -> TapResult {
        guard value(at: r, c) != nil else { return .ignored }

        if let (sr, sc) = selected, sr == r, sc == c {
            selected = nil
            return .deselected
        }

        guard let (sr, sc) = selected else {
            selected = (r, c)
            return .selected
        }

        guard Self.isAdjacent((sr, sc), (r, c)) else {
            return .notAdjacent
        }

        let v1 = value(at: sr, sc) ?? 0
        let v2 = value(at: r, c) ?? 0
        guard v1 + v2 == 10 else {
            // Wrong sum: deselect and reset combo so the next tap becomes a
            // fresh selection rather than compounding confusion.
            selected = nil
            combo = 0
            return .invalidPair
        }

        grid[sr][sc] = .value(Int.random(in: 1...9, using: &rng))
        grid[r][c] = .value(Int.random(in: 1...9, using: &rng))
        selected = nil
        clearsMade += 1
        combo += 1
        let points = 10 * combo
        score += points
        return .cleared(points: points, combo: combo, clearsSoFar: clearsMade)
    }

    var isComplete: Bool { clearsMade >= targetClears }
}

