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
        currentQuestion = questionGenerator.generate(for: learningProfile)
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
        } else {
            consecutiveCorrect = 0
        }

        profile.totalQuestions += 1
        questionsCompleted += 1

        if difficultyManager.shouldPromoteLevel(profile: learningProfile) {
            learningProfile = difficultyManager.promote(profile: learningProfile)
            profile.difficultyLevel = learningProfile.currentLevel
            profile.subDifficulty = learningProfile.subDifficulty
        } else {
            profile.subDifficulty = learningProfile.subDifficulty
        }

        generateNextQuestion()
    }

    func finishSession() {
        session.durationSeconds = Date().timeIntervalSince(session.date)
        isSessionComplete = true
    }
}
