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
    @discardableResult
    func submit(_ answer: Int) -> Bool {
        guard phase == .answering else { return false }
        let (a, b) = currentRoll
        let elapsed = Date().timeIntervalSince(roundStart)
        let correct = (answer == a + b)
        lastResult = correct
        if correct {
            correctCount += 1
            totalPoints += Self.points(for: elapsed, correct: true)
            if elapsed < fastestSeconds { fastestSeconds = elapsed }
        }
        phase = .resultShown
        return correct
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
