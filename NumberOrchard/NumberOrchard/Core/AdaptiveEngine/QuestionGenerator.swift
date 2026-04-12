import Foundation

struct QuestionGenerator: Sendable {

    func generate(for profile: LearningProfile) -> MathQuestion {
        generate(for: profile, recentQuestions: [])
    }

    /// Generate a question, avoiding recent repeats.
    /// - Skip exact duplicates of the last 2 questions
    /// - Avoid answer repeating 3+ times in a row
    /// - Alternate operation (add/subtract) if both allowed and same operation appeared 3+ times in a row
    func generate(for profile: LearningProfile, recentQuestions: [MathQuestion]) -> MathQuestion {
        let forcedOperation = determineForcedOperation(
            level: profile.currentLevel,
            recent: recentQuestions
        )

        // Try up to 15 times to produce a question that's not a recent duplicate
        for _ in 0..<15 {
            let operation = forcedOperation ?? chooseOperation(for: profile.currentLevel)
            let (op1, op2) = generateOperands(
                level: profile.currentLevel,
                subDifficulty: profile.subDifficulty,
                operation: operation
            )
            let gameMode: GameMode = operation == .add ? .pickFruit : .shareFruit
            let candidate = MathQuestion(
                operand1: op1, operand2: op2,
                operation: operation, gameMode: gameMode
            )

            if isAcceptable(candidate: candidate, recent: recentQuestions) {
                return candidate
            }
        }

        // Fallback: accept whatever last candidate was generated
        let operation = forcedOperation ?? chooseOperation(for: profile.currentLevel)
        let (op1, op2) = generateOperands(
            level: profile.currentLevel,
            subDifficulty: profile.subDifficulty,
            operation: operation
        )
        let gameMode: GameMode = operation == .add ? .pickFruit : .shareFruit
        return MathQuestion(operand1: op1, operand2: op2, operation: operation, gameMode: gameMode)
    }

    /// Candidate is unacceptable if it exactly matches the last question,
    /// or if the same answer would appear 3+ times in a row.
    private func isAcceptable(candidate: MathQuestion, recent: [MathQuestion]) -> Bool {
        // Don't repeat the exact same equation as the last one
        if let last = recent.last,
           last.operand1 == candidate.operand1,
           last.operand2 == candidate.operand2,
           last.operation == candidate.operation {
            return false
        }
        // Avoid same answer 3 times in a row
        let lastTwoAnswers = recent.suffix(2).map(\.correctAnswer)
        if lastTwoAnswers.count == 2 && lastTwoAnswers.allSatisfy({ $0 == candidate.correctAnswer }) {
            return false
        }
        return true
    }

    /// If both operations allowed and the same one appeared 3+ times consecutively,
    /// force the other operation.
    private func determineForcedOperation(level: DifficultyLevel, recent: [MathQuestion]) -> MathOperation? {
        guard level.allowsSubtraction else { return .add }
        let lastThree = recent.suffix(3).map(\.operation)
        if lastThree.count == 3 && lastThree.allSatisfy({ $0 == .add }) {
            return .subtract
        }
        if lastThree.count == 3 && lastThree.allSatisfy({ $0 == .subtract }) {
            return .add
        }
        return nil
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
