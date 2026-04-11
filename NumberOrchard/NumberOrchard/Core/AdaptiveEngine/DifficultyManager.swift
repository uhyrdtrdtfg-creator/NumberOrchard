import Foundation

struct DifficultyManager: Sendable {

    func updateAfterAnswer(profile: LearningProfile, isCorrect: Bool, usedHint: Bool) -> LearningProfile {
        var p = profile
        p.levelQuestionCount += 1

        if isCorrect {
            p.levelCorrectCount += 1
            p.consecutiveCorrect += 1
            p.consecutiveWrong = 0

            if p.consecutiveCorrect >= 3 {
                p.subDifficulty = min(p.subDifficulty + 1, 5)
                p.consecutiveCorrect = 0
            }
        } else {
            p.consecutiveWrong += 1
            p.consecutiveCorrect = 0

            if p.consecutiveWrong >= 2 {
                p.subDifficulty = max(p.subDifficulty - 1, 1)
                p.consecutiveWrong = 0
            }
        }

        if usedHint {
            p.hintUsageCount += 1
        }

        return p
    }

    func shouldPromoteLevel(profile: LearningProfile) -> Bool {
        guard profile.currentLevel != .bigTree else { return false }
        guard profile.levelQuestionCount >= profile.currentLevel.minimumQuestionsForPromotion else {
            return false
        }
        return profile.levelAccuracy >= profile.currentLevel.promotionThreshold
    }

    func promote(profile: LearningProfile) -> LearningProfile {
        guard let nextLevel = DifficultyLevel(rawValue: profile.currentLevel.rawValue + 1) else {
            return profile
        }
        var p = profile
        p.currentLevel = nextLevel
        p.subDifficulty = 1
        p.levelCorrectCount = 0
        p.levelQuestionCount = 0
        p.consecutiveCorrect = 0
        p.consecutiveWrong = 0
        p.hintUsageCount = 0
        return p
    }
}
