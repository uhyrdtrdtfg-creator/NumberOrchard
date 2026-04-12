import Foundation

enum ParentOperation: String, Sendable {
    case add
    case subtract
    case multiply
    case divide
}

struct ParentQuestion: Sendable {
    let operand1: Int
    let operand2: Int
    let parentOperation: ParentOperation?
    let correctAnswer: Int
    let displayText: String
}

struct ParentQuestionGenerator: Sendable {

    func generate(forChildLevel childLevel: DifficultyLevel, difficultyMultiplier: Double = 1.0) -> ParentQuestion {
        let baseRange = childLevel.rawValue * 5
        let maxRange = Int(Double(baseRange) * 5 * difficultyMultiplier)

        let includeMulDiv = childLevel.rawValue >= 5
        let ops: [ParentOperation] = includeMulDiv ? [.add, .subtract, .multiply, .divide] : [.add, .subtract]
        let op = ops.randomElement() ?? .add

        let op1: Int
        let op2: Int
        let answer: Int
        let displayText: String

        switch op {
        case .add:
            op1 = Int.random(in: 2...max(3, maxRange - 1))
            op2 = Int.random(in: 1...max(1, maxRange - op1))
            answer = op1 + op2
            displayText = "\(op1) + \(op2) = ?"
        case .subtract:
            op1 = Int.random(in: 10...max(11, maxRange))
            op2 = Int.random(in: 1...(op1 - 1))
            answer = op1 - op2
            displayText = "\(op1) - \(op2) = ?"
        case .multiply:
            op1 = Int.random(in: 2...min(12, max(3, maxRange / 4)))
            op2 = Int.random(in: 2...min(12, max(3, maxRange / max(1, op1))))
            answer = op1 * op2
            displayText = "\(op1) × \(op2) = ?"
        case .divide:
            op2 = Int.random(in: 2...9)
            answer = Int.random(in: 2...12)
            op1 = op2 * answer
            displayText = "\(op1) ÷ \(op2) = ?"
        }

        return ParentQuestion(
            operand1: op1,
            operand2: op2,
            parentOperation: op,
            correctAnswer: answer,
            displayText: displayText
        )
    }

    func generateChildQuestion(childLevel: DifficultyLevel) -> MathQuestion {
        let profile = LearningProfile(currentLevel: childLevel, subDifficulty: 3)
        return QuestionGenerator().generate(for: profile)
    }
}
