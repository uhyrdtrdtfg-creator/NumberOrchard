import Foundation

/// A math question themed around an active Noom's preferred fruit.
/// Example: "小一先吃了 3 个苹果，又吃了 2 个，一共吃了几个？"
struct PetTheaterQuestion: Sendable, Equatable {
    enum Op: Sendable { case add, subtract }

    let operand1: Int
    let operand2: Int
    let op: Op
    let fruitId: String
    let fruitEmoji: String
    let fruitName: String
    let noomName: String

    var answer: Int {
        switch op {
        case .add: return operand1 + operand2
        case .subtract: return operand1 - operand2
        }
    }

    /// Child-facing prompt string.
    var prompt: String {
        switch op {
        case .add:
            return "\(noomName)先吃了 \(operand1) 个\(fruitName)，又吃了 \(operand2) 个，一共吃了几个呢？"
        case .subtract:
            return "\(noomName)有 \(operand1) 个\(fruitName)，吃掉了 \(operand2) 个，还剩几个？"
        }
    }
}

struct PetTheaterQuestionGenerator: Sendable {
    /// Generate a single themed question for the given Noom at the given difficulty.
    /// Uses `PetPreferenceMap` to pick a fruit matching the Noom's taste.
    func generate(
        noomNumber: Int,
        noomName: String,
        difficulty: DifficultyLevel,
        rng: inout some RandomNumberGenerator
    ) -> PetTheaterQuestion {
        let fruit = pickFruit(for: noomNumber, rng: &rng)
        let maxN = difficulty.maxNumber

        // Decide operation. Only allow subtraction when the difficulty level permits it.
        let useSubtraction = difficulty.allowsSubtraction && Bool.random(using: &rng)

        if useSubtraction {
            let a = Int.random(in: 2...maxN, using: &rng)
            let b = Int.random(in: 1...(a - 1), using: &rng)
            return PetTheaterQuestion(
                operand1: a, operand2: b, op: .subtract,
                fruitId: fruit.id, fruitEmoji: fruit.emoji, fruitName: fruit.name,
                noomName: noomName
            )
        } else {
            let a = Int.random(in: 1...(maxN - 1), using: &rng)
            let b = Int.random(in: 1...(maxN - a), using: &rng)
            return PetTheaterQuestion(
                operand1: a, operand2: b, op: .add,
                fruitId: fruit.id, fruitEmoji: fruit.emoji, fruitName: fruit.name,
                noomName: noomName
            )
        }
    }

    /// Generate `count` questions for a single session.
    func generateBatch(
        count: Int,
        noomNumber: Int,
        noomName: String,
        difficulty: DifficultyLevel,
        rng: inout some RandomNumberGenerator
    ) -> [PetTheaterQuestion] {
        (0..<count).map { _ in
            generate(noomNumber: noomNumber, noomName: noomName,
                     difficulty: difficulty, rng: &rng)
        }
    }

    /// Pick a preferred fruit for this Noom, falling back to any common fruit if none mapped.
    private func pickFruit(
        for noomNumber: Int,
        rng: inout some RandomNumberGenerator
    ) -> FruitItem {
        let preferred = PetPreferenceMap.preferences[noomNumber] ?? []
        for _ in 0..<3 {
            if let id = preferred.randomElement(using: &rng),
               let fruit = FruitCatalog.fruit(id: id) {
                return fruit
            }
        }
        return FruitCatalog.fruit(id: "apple") ?? FruitCatalog.fruits[0]
    }
}
