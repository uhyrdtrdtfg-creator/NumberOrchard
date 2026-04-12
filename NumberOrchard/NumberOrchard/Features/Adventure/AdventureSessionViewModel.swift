import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AdventureSessionViewModel {
    private let questionGenerator = QuestionGenerator()
    private let difficultyManager = DifficultyManager()
    private let treeCalculator = TreeGrowthCalculator()

    var currentQuestion: MathQuestion?
    var questionsCompleted: Int = 0
    var totalQuestions: Int = 5
    var consecutiveCorrect: Int = 0
    var isSessionComplete: Bool = false
    var experienceGained: Int = 0

    private var learningProfile: LearningProfile
    private var session: LearningSession
    private var profile: ChildProfile
    private var recentQuestions: [MathQuestion] = []

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.learningProfile = LearningProfile(from: profile)
        self.session = LearningSession(level: profile.difficultyLevel)
        modelContext.insert(session)
        profile.sessions.append(session)
        generateNextQuestion()
    }

    func generateNextQuestion() {
        guard questionsCompleted < totalQuestions else {
            isSessionComplete = true
            return
        }
        let next = questionGenerator.generate(for: learningProfile, recentQuestions: recentQuestions)
        currentQuestion = next
        recentQuestions.append(next)
        // Only keep last 5 for window
        if recentQuestions.count > 5 {
            recentQuestions.removeFirst(recentQuestions.count - 5)
        }
    }

    func handleAnswer(correct: Bool, responseTime: TimeInterval, usedHint: Bool) {
        guard let question = currentQuestion else { return }

        let record = QuestionRecord(
            question: question,
            userAnswer: correct ? question.correctAnswer : -1,
            responseTime: responseTime,
            usedHint: usedHint
        )
        session.records.append(record)

        learningProfile = difficultyManager.updateAfterAnswer(
            profile: learningProfile,
            isCorrect: correct,
            usedHint: usedHint
        )

        if correct {
            consecutiveCorrect += 1
            let exp = treeCalculator.experienceForCorrectAnswer(combo: consecutiveCorrect)
            experienceGained += exp
            profile.treeExperience += exp
            profile.treeStage = TreeGrowthCalculator.stageFor(experience: profile.treeExperience)
            profile.totalCorrect += 1

            // Play voice encouragement
            playCorrectVoice()
        } else {
            consecutiveCorrect = 0
            // Play wrong answer sound + voice
            AudioManager.shared.playSound("wrong.wav")
            AudioManager.shared.playVoice("wrong_hint.aiff")
        }

        profile.totalQuestions += 1
        questionsCompleted += 1

        if difficultyManager.shouldPromoteLevel(profile: learningProfile) {
            learningProfile = difficultyManager.promote(profile: learningProfile)
            profile.difficultyLevel = learningProfile.currentLevel
            profile.subDifficulty = learningProfile.subDifficulty
            // Play level up sound
            AudioManager.shared.playSound("level_up.wav")
        } else {
            profile.subDifficulty = learningProfile.subDifficulty
        }

        generateNextQuestion()
    }

    func finishSession() {
        session.durationSeconds = Date().timeIntervalSince(session.date)
        isSessionComplete = true
    }

    private func playCorrectVoice() {
        switch consecutiveCorrect {
        case 3:
            AudioManager.shared.playVoice("combo_03.aiff")
        case 5:
            AudioManager.shared.playVoice("combo_05.aiff")
        case 7:
            AudioManager.shared.playVoice("combo_07.aiff")
        default:
            // Random basic encouragement
            let index = Int.random(in: 1...5)
            AudioManager.shared.playVoice("correct_0\(index).aiff")
        }
    }
}
