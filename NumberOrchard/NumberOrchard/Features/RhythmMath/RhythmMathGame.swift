import Foundation

/// Pure round description for 节奏数学 — a single equation whose correct
/// answer the child picks from three falling number balls. Rounds are
/// deterministic given a seed so tests can assert on distractor shape.
struct RhythmRound: Sendable, Equatable {
    let operand1: Int
    let operand2: Int
    /// The three choices shown as balls. Exactly one equals `correctAnswer`.
    let choices: [Int]

    var correctAnswer: Int { operand1 + operand2 }

    var displayText: String { "\(operand1) + \(operand2) = ?" }
}

enum RhythmMathGenerator {
    /// Build a round appropriate for the given difficulty. Distractors
    /// are chosen close to the correct answer (±1, ±2) so the child can't
    /// win by picking the largest / smallest ball.
    static func makeRound(
        maxTotal: Int,
        rng: inout some RandomNumberGenerator
    ) -> RhythmRound {
        let upper = max(2, maxTotal - 1)
        let a = Int.random(in: 1...upper, using: &rng)
        let b = Int.random(in: 1...(maxTotal - a), using: &rng)
        let answer = a + b

        // Pick two distractors that are not equal to the answer and fall
        // within a reasonable delta.
        var distractors: Set<Int> = []
        var safety = 30
        while distractors.count < 2 && safety > 0 {
            safety -= 1
            let delta = [-2, -1, 1, 2].randomElement(using: &rng) ?? 1
            let candidate = answer + delta
            if candidate >= 0 && candidate <= maxTotal + 2 && candidate != answer {
                distractors.insert(candidate)
            }
        }
        var choices = Array(distractors) + [answer]
        choices.shuffle(using: &rng)
        return RhythmRound(operand1: a, operand2: b, choices: choices)
    }
}
