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
        // For maxSum=20 (L5/L6), use extended ranges and optionally force carry
        if maxSum == 20 {
            // Phase 1 (sub 1-2): no carry (digit sum < 10)
            // Phase 2 (sub 3-5): allow carry
            let allowCarry = subDifficulty >= 3
            for _ in 0..<10 {
                let op1 = Int.random(in: 1...min(9, maxSum - 1))
                let maxOp2 = maxSum - op1
                guard maxOp2 >= 1 else { continue }
                let op2 = Int.random(in: 1...maxOp2)
                let unitsCarry = (op1 % 10 + op2 % 10) >= 10
                if allowCarry || !unitsCarry {
                    return (op1, op2)
                }
            }
            return (5, 5)
        }

        // Original L1-L4 logic
        let minOperand = 1
        let maxOperand = max(1, min(maxSum - 1, subDifficulty + 1))
        let op1 = Int.random(in: minOperand...maxOperand)
        let maxOp2 = maxSum - op1
        guard maxOp2 >= 1 else { return (1, 1) }
        let op2 = Int.random(in: 1...maxOp2)
        return (op1, op2)
    }

    private func generateSubtractionOperands(maxMinuend: Int, subDifficulty: Int) -> (Int, Int) {
        if maxMinuend == 20 {
            // Phase 1 (sub 1-2): no borrow (op1 units >= op2 units)
            // Phase 2 (sub 3-5): allow borrow
            let allowBorrow = subDifficulty >= 3
            for _ in 0..<10 {
                let op1 = Int.random(in: 11...maxMinuend)  // 11-20 minuend
                let op2 = Int.random(in: 1...(op1 - 1))
                let unitsBorrow = (op1 % 10) < (op2 % 10)
                if allowBorrow || !unitsBorrow {
                    return (op1, op2)
                }
            }
            return (15, 5)
        }

        // Original L1-L4 logic
        let minMinuend = max(2, subDifficulty)
        let op1 = Int.random(in: minMinuend...maxMinuend)
        let op2 = Int.random(in: 1...(op1))
        return (op1, op2)
    }

    /// Generate a question for a specific game mode.
    func generate(for profile: LearningProfile, gameMode: GameMode, recentQuestions: [MathQuestion] = []) -> MathQuestion {
        if gameMode == .pickFruit || gameMode == .shareFruit {
            let operation: MathOperation = gameMode == .pickFruit ? .add : .subtract
            let (op1, op2) = generateOperands(
                level: profile.currentLevel,
                subDifficulty: profile.subDifficulty,
                operation: operation
            )
            return MathQuestion(operand1: op1, operand2: op2, operation: operation, gameMode: gameMode)
        }

        if gameMode == .numberTrain {
            let totalSeats = profile.currentLevel.maxNumber <= 5 ? 5 : 10
            let occupied = Int.random(in: 1...(totalSeats - 1))
            let empty = totalSeats - occupied
            return MathQuestion(operand1: occupied, operand2: empty, operation: .add, gameMode: .numberTrain)
        }

        if gameMode == .balance {
            let maxTotal = min(profile.currentLevel.maxNumber, 10)
            let target = Int.random(in: 3...maxTotal)
            let rightFixed = Int.random(in: 1...(target - 1))
            let rightMissing = target - rightFixed
            return MathQuestion(operand1: rightFixed, operand2: rightMissing, operation: .add, gameMode: .balance)
        }

        return generate(for: profile, recentQuestions: recentQuestions)
    }
}
