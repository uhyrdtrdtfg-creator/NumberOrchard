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
    /// Default thinking budget per question (seconds). Shown as an optional
    /// countdown pill at the top of the theater. Kids can take as long as
    /// they want — the timer never auto-submits — but the tick encourages
    /// quick answers.
    static let baseThinkSeconds: TimeInterval = 10
    /// Bonus seconds granted when the active Noom has the `calmClock` skill.
    static let calmClockBonusSeconds: TimeInterval = 2

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

    /// Total thinking budget for the current question, scaled by the
    /// active Noom's `calmClock` skill. Tier 1 = +2s, Tier 2 = +4s.
    /// Non-reactive; view reads once per question and drives its own
    /// countdown animation.
    var thinkBudgetSeconds: TimeInterval {
        let bonus = garden.activeSkill == .calmClock
            ? NoomSkill.calmClockBonusSeconds(tier: garden.activeSkillTier)
            : 0
        return Self.baseThinkSeconds + bonus
    }

    /// Exposed for the view's "⏳ +Ns 从容" badge.
    var calmClockBonus: TimeInterval {
        garden.activeSkill == .calmClock
            ? NoomSkill.calmClockBonusSeconds(tier: garden.activeSkillTier)
            : 0
    }

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
    /// Active pet's `luckyDrop` skill scales the drop rate by tier:
    /// Tier 1 (少年) = ×2, Tier 2 (成年) = ×4.
    private func rollLegendaryDrop() {
        var rng = SystemRandomNumberGenerator()
        let multiplier = garden.activeSkill == .luckyDrop
            ? NoomSkill.luckyDropMultiplier(tier: garden.activeSkillTier)
            : 1.0
        guard let drop = LegendaryDropRoll.roll(
            rate: LegendaryDropRoll.defaultRate * multiplier,
            rng: &rng
        ) else { return }
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
