import Foundation

struct QuestionGenerator: Sendable {

    func generate(for profile: LearningProfile) -> MathQuestion {
        let operation = chooseOperation(for: profile.currentLevel)
        let (op1, op2) = generateOperands(
            level: profile.currentLevel,
            subDifficulty: profile.subDifficulty,
            operation: operation
        )
        let gameMode: GameMode = operation == .add ? .pickFruit : .shareFruit

        return MathQuestion(
            operand1: op1,
            operand2: op2,
            operation: operation,
            gameMode: gameMode
        )
    }

    private func chooseOperation(for level: DifficultyLevel) -> MathOperation {
        guard level.allowsSubtraction else { return .add }
        return Bool.random() ? .add : .subtract
    }

    private func generateOperands(
        level: DifficultyLevel,
        subDifficulty: Int,
        operation: MathOperation
    ) -> (Int, Int) {
        let maxNum = level.maxNumber

        switch operation {
        case .add:
            return generateAdditionOperands(maxSum: maxNum, subDifficulty: subDifficulty)
        case .subtract:
            return generateSubtractionOperands(maxMinuend: maxNum, subDifficulty: subDifficulty)
        }
    }

    private func generateAdditionOperands(maxSum: Int, subDifficulty: Int) -> (Int, Int) {
        let minOperand = 1
        let maxOperand = max(1, min(maxSum - 1, subDifficulty + 1))

        let op1 = Int.random(in: minOperand...maxOperand)
        let maxOp2 = maxSum - op1
        guard maxOp2 >= 1 else { return (1, 1) }
        let op2 = Int.random(in: 1...maxOp2)
        return (op1, op2)
    }

    private func generateSubtractionOperands(maxMinuend: Int, subDifficulty: Int) -> (Int, Int) {
        let minMinuend = max(2, subDifficulty)
        let op1 = Int.random(in: minMinuend...maxMinuend)
        let op2 = Int.random(in: 1...(op1))
        return (op1, op2)
    }
}
