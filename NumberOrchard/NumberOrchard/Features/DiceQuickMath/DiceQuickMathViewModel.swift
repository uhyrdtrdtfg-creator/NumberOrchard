import SwiftUI
import SwiftData
import Observation

/// Session state for 骰子速算 — 5 rounds of two-dice addition.
/// Awards stars to the child profile based on how quickly they answered.
@Observable
@MainActor
final class DiceQuickMathViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext

    static let sessionRoundCount = 5
    static let rollDuration: TimeInterval = 1.0

    enum Phase { case rolling, answering, resultShown, complete }

    /// Pure scoring rules. Faster = more points. Exposed for tests.
    nonisolated static func points(for seconds: TimeInterval, correct: Bool) -> Int {
        guard correct else { return 0 }
        if seconds <= 3 { return 20 }
        if seconds <= 6 { return 10 }
        return 5
    }

    /// Stars awarded from total points at end of session. Exposed for tests.
    /// 80+ = 3★, 40+ = 2★, any participation = 1★.
    nonisolated static func stars(forTotalPoints total: Int) -> Int {
        if total >= 80 { return 3 }
        if total >= 40 { return 2 }
        return 1
    }

    var phase: Phase = .rolling
    var currentRound: Int = 0            // 0-based index into rolls
    var rolls: [(Int, Int)] = []          // (die1, die2) pre-generated for the session
    var totalPoints: Int = 0
    var correctCount: Int = 0
    var fastestSeconds: TimeInterval = .infinity
    var lastResult: Bool? = nil
    /// Legendary fruit dropped by the last correct answer, if any.
    /// Cleared on advance; view layer shows a banner when non-nil.
    var lastLegendaryDrop: FruitItem? = nil

    private var roundStart: Date = .distantPast

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        var rng = SystemRandomNumberGenerator()
        rolls = (0..<Self.sessionRoundCount).map { _ in
            (Int.random(in: 1...6, using: &rng), Int.random(in: 1...6, using: &rng))
        }
    }

    var currentRoll: (Int, Int) { rolls[min(currentRound, rolls.count - 1)] }

    /// Call after the on-screen rolling animation completes to enter answer mode.
    func startAnswering() {
        phase = .answering
        roundStart = Date()
    }

    /// Submit the child's typed answer. Returns true if correct.
    /// Correct answers additionally roll for a legendary-fruit easter-egg
    /// drop (1% chance, or 2% if the active Noom has the luckyDrop skill)
    /// and add it to the profile's collection if won.
    ///
    /// The active Noom's `diceBonus` skill adds a flat +5 points on every
    /// correct answer; `luckyDrop` doubles the easter-egg drop rate.
    @discardableResult
    func submit(_ answer: Int) -> Bool {
        guard phase == .answering else { return false }
        let (a, b) = currentRoll
        let elapsed = Date().timeIntervalSince(roundStart)
        let correct = (answer == a + b)
        lastResult = correct
        if correct {
            correctCount += 1
            var pts = Self.points(for: elapsed, correct: true)
            if activeSkill == .diceBonus { pts += 5 }
            totalPoints += pts
            if elapsed < fastestSeconds { fastestSeconds = elapsed }
            rollLegendaryDrop()
        }
        phase = .resultShown
        return correct
    }

    /// Currently-active Noom's unlocked skill, if any. Resolved lazily
    /// against the profile at call time so switching the active pet while
    /// the game is open takes effect on the next submission.
    private var activeSkill: NoomSkill? {
        let active = profile.petProgress.first(where: { $0.isActive })
            ?? profile.petProgress.first
        guard let pet = active, NoomSkill.isUnlocked(stage: pet.stage) else { return nil }
        return NoomSkillCatalog.skill(for: pet.noomNumber)
    }

    private func rollLegendaryDrop() {
        var rng = SystemRandomNumberGenerator()
        let rate = activeSkill == .luckyDrop
            ? LegendaryDropRoll.defaultRate * 2
            : LegendaryDropRoll.defaultRate
        guard let drop = LegendaryDropRoll.roll(rate: rate, rng: &rng) else { return }
        lastLegendaryDrop = drop
        if !profile.collectedFruits.contains(where: { $0.fruitId == drop.id }) {
            let cf = CollectedFruit(fruitId: drop.id)
            profile.collectedFruits.append(cf)
        }
    }

    /// Advance to the next round (called after a short result display).
    func advance() {
        if correctCount + (lastResult == false ? 1 : 0) >= Self.sessionRoundCount
            || currentRound + 1 >= rolls.count {
            finishSession()
            return
        }
        currentRound += 1
        lastResult = nil
        lastLegendaryDrop = nil
        phase = .rolling
    }

    /// Allow a wrong-answer retry without penalty (keep same roll, reset timer).
    func retryCurrent() {
        guard phase == .resultShown, lastResult == false else { return }
        lastResult = nil
        phase = .answering
        roundStart = Date()
    }

    private func finishSession() {
        phase = .complete
        profile.stars += Self.stars(forTotalPoints: totalPoints)
    }

    var progressText: String {
        "\(min(currentRound + 1, rolls.count)) / \(rolls.count)"
    }

    var sessionFastestDisplay: String {
        fastestSeconds == .infinity ? "—" : String(format: "%.1f s", fastestSeconds)
    }
}
