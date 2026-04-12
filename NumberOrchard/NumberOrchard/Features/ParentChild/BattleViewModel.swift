import SwiftUI
import Observation

enum BattleWinner: String, Sendable {
    case child
    case parent
    case tie
}

enum BattlePlayer {
    case child
    case parent
}

@Observable
@MainActor
final class BattleViewModel {
    let totalRounds = 5
    var currentRound: Int = 1
    var childScore: Int = 0
    var parentScore: Int = 0
    var childQuestion: MathQuestion?
    var parentQuestion: ParentQuestion?
    var childInput: String = ""
    var parentInput: String = ""
    var roundComplete: Bool = false
    var roundWinner: BattleWinner?
    var battleComplete: Bool = false
    var finalWinner: BattleWinner?
    var parentKeypadScale: Double = 1.0
    private var parentDifficultyMultiplier: Double = 1.0
    private var childLossStreak: Int = 0
    private var parentLossStreak: Int = 0

    private let childLevel: DifficultyLevel
    private let childGenerator = QuestionGenerator()
    private let parentGenerator = ParentQuestionGenerator()

    init(childLevel: DifficultyLevel) {
        self.childLevel = childLevel
        generateNewRound()
    }

    private func generateNewRound() {
        let childProfile = LearningProfile(currentLevel: childLevel, subDifficulty: 3)
        childQuestion = childGenerator.generate(for: childProfile)
        parentQuestion = parentGenerator.generate(forChildLevel: childLevel, difficultyMultiplier: parentDifficultyMultiplier)
        childInput = ""
        parentInput = ""
        roundComplete = false
        roundWinner = nil
    }

    func submitChild() {
        guard !roundComplete, let question = childQuestion else { return }
        guard let inputValue = Int(childInput) else { return }
        if inputValue == question.correctAnswer {
            childScore += 1
            roundWinner = .child
            parentLossStreak += 1
            childLossStreak = 0
            endRound()
        } else {
            childInput = ""
        }
    }

    func submitParent() {
        guard !roundComplete, let question = parentQuestion else { return }
        guard let inputValue = Int(parentInput) else { return }
        if inputValue == question.correctAnswer {
            parentScore += 1
            roundWinner = .parent
            childLossStreak += 1
            parentLossStreak = 0
            endRound()
        } else {
            parentInput = ""
        }
    }

    private func endRound() {
        roundComplete = true

        if childLossStreak >= 2 {
            parentDifficultyMultiplier = 1.5
            parentKeypadScale = 0.8
        } else if parentLossStreak >= 2 {
            parentDifficultyMultiplier = 0.8
            parentKeypadScale = 1.0
        } else {
            parentDifficultyMultiplier = 1.0
            parentKeypadScale = 1.0
        }
    }

    func nextRound() {
        guard roundComplete else { return }
        if currentRound >= totalRounds {
            finishBattle()
            return
        }
        currentRound += 1
        generateNewRound()
    }

    private func finishBattle() {
        battleComplete = true
        if childScore > parentScore { finalWinner = .child }
        else if parentScore > childScore { finalWinner = .parent }
        else { finalWinner = .tie }
    }

    func appendDigit(_ digit: String, to player: BattlePlayer) {
        switch player {
        case .child: childInput = String((childInput + digit).prefix(4))
        case .parent: parentInput = String((parentInput + digit).prefix(4))
        }
    }

    func clearInput(for player: BattlePlayer) {
        switch player {
        case .child: childInput = ""
        case .parent: parentInput = ""
        }
    }
}
