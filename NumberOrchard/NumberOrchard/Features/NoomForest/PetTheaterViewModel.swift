import SwiftUI
import Observation

/// Session logic for the Noom Math Theater feature.
///
/// Owns a list of 5 themed questions, tracks progress, and routes correct
/// answers into the existing `PetGardenViewModel.feedActivePet` flow so that
/// rewards (XP, evolution) share the same machinery as fruit feeding.
@Observable
@MainActor
final class PetTheaterViewModel {
    let garden: PetGardenViewModel
    private let generator = PetTheaterQuestionGenerator()
    private let difficulty: DifficultyLevel

    static let sessionQuestionCount = 5

    var questions: [PetTheaterQuestion] = []
    var currentIndex: Int = 0
    var correctCount: Int = 0
    var totalFruitsEaten: Int = 0
    var lastResult: Result? = nil
    var sessionComplete: Bool = false
    /// Legendary fruit dropped by the most recent correct answer, if any.
    /// Cleared on next `advance()`. View layer shows a celebration overlay.
    var lastLegendaryDrop: FruitItem? = nil

    enum Result { case correct, wrong }

    init(garden: PetGardenViewModel) {
        self.garden = garden
        self.difficulty = garden.profile.difficultyLevel
        loadQuestions()
    }

    private func loadQuestions() {
        guard let pet = garden.activePet,
              let noom = NoomCatalog.noom(for: pet.noomNumber)
        else { return }
        var rng = SystemRandomNumberGenerator()
        questions = generator.generateBatch(
            count: Self.sessionQuestionCount,
            noomNumber: pet.noomNumber,
            noomName: noom.name,
            difficulty: difficulty,
            rng: &rng
        )
    }

    var currentQuestion: PetTheaterQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    /// Submit an answer for the current question. Returns true if correct.
    /// On correct answers, feeds the active pet a preferred fruit for XP
    /// and rolls for a legendary-fruit easter-egg drop.
    @discardableResult
    func submit(_ answer: Int) -> Bool {
        guard let q = currentQuestion else { return false }
        if answer == q.answer {
            correctCount += 1
            totalFruitsEaten += q.answer
            garden.feedActivePet(fruitId: q.fruitId)
            lastResult = .correct
            rollLegendaryDrop()
            return true
        } else {
            lastResult = .wrong
            return false
        }
    }

    /// Roll for a rare legendary fruit. If it hits and the profile doesn't
    /// already own the dropped fruit, add it. Exposed to the view via
    /// `lastLegendaryDrop` for overlay display.
    ///
    /// Active pet's `luckyDrop` skill (unlocked at stage ≥ 1) doubles the
    /// drop rate — one of the reasons to favour keeping a lucky Noom as
    /// the active pet across sessions.
    private func rollLegendaryDrop() {
        var rng = SystemRandomNumberGenerator()
        let rate = garden.activeSkill == .luckyDrop
            ? LegendaryDropRoll.defaultRate * 2
            : LegendaryDropRoll.defaultRate
        guard let drop = LegendaryDropRoll.roll(rate: rate, rng: &rng) else { return }
        lastLegendaryDrop = drop
        let profile = garden.profile
        if !profile.collectedFruits.contains(where: { $0.fruitId == drop.id }) {
            let cf = CollectedFruit(fruitId: drop.id)
            profile.collectedFruits.append(cf)
        }
    }

    /// Advance to next question (called after correct answer's celebration).
    func advance() {
        currentIndex += 1
        lastResult = nil
        lastLegendaryDrop = nil
        if currentIndex >= questions.count {
            sessionComplete = true
            garden.profile.stars += 1
        }
    }

    /// Reset the wrong-answer state so the child can try again.
    func clearResult() { lastResult = nil }

    var progressText: String {
        "\(min(currentIndex + 1, questions.count)) / \(questions.count)"
    }
}
