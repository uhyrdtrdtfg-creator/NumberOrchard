import Foundation

struct LearningProfile: Sendable {
    var currentLevel: DifficultyLevel
    var subDifficulty: Int  // 1-5 within current level
    var consecutiveCorrect: Int
    var consecutiveWrong: Int
    var levelCorrectCount: Int
    var levelQuestionCount: Int
    var hintUsageCount: Int

    var levelAccuracy: Double {
        guard levelQuestionCount > 0 else { return 0 }
        return Double(levelCorrectCount) / Double(levelQuestionCount)
    }

    var hintUsageRate: Double {
        guard levelQuestionCount > 0 else { return 0 }
        return Double(hintUsageCount) / Double(levelQuestionCount)
    }

    init(from profile: ChildProfile) {
        self.currentLevel = profile.difficultyLevel
        self.subDifficulty = profile.subDifficulty
        self.consecutiveCorrect = 0
        self.consecutiveWrong = 0
        self.levelCorrectCount = profile.totalCorrect
        self.levelQuestionCount = profile.totalQuestions
        self.hintUsageCount = 0
    }

    init(currentLevel: DifficultyLevel, subDifficulty: Int) {
        self.currentLevel = currentLevel
        self.subDifficulty = subDifficulty
        self.consecutiveCorrect = 0
        self.consecutiveWrong = 0
        self.levelCorrectCount = 0
        self.levelQuestionCount = 0
        self.hintUsageCount = 0
    }
}
