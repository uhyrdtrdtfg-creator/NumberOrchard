import Foundation

/// Tiny seeded LCG — gives us reproducible sequences for procedural
/// rendering (NoomRenderer spots), seeded game layouts (MatchTenGame,
/// FishingGameState), and deterministic tests. Not crypto-grade.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 1 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
