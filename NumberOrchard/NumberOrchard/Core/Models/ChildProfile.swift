import Foundation
import SwiftData

@Model
final class ChildProfile {
    var name: String
    var avatarIndex: Int
    var createdAt: Date

    var currentLevel: Int
    var subDifficulty: Int
    var totalCorrect: Int
    var totalQuestions: Int

    var treeExperience: Int
    var treeStage: Int
    var stars: Int
    var seeds: Int
    var consecutiveLoginDays: Int
    var lastLoginDate: Date?

    var dailyTimeLimitMinutes: Int

    @Relationship(deleteRule: .cascade)
    var sessions: [LearningSession] = []

    @Relationship(deleteRule: .cascade)
    var stationProgress: [StationProgress] = []

    @Relationship(deleteRule: .cascade)
    var decorations: [CollectedDecoration] = []

    @Relationship(deleteRule: .cascade)
    var collectedFruits: [CollectedFruit] = []

    @Relationship(deleteRule: .cascade)
    var collectedNooms: [CollectedNoom] = []

    init(name: String, avatarIndex: Int = 0) {
        self.name = name
        self.avatarIndex = avatarIndex
        self.createdAt = Date()
        self.currentLevel = DifficultyLevel.seed.rawValue
        self.subDifficulty = 1
        self.totalCorrect = 0
        self.totalQuestions = 0
        self.treeExperience = 0
        self.treeStage = 0
        self.stars = 0
        self.seeds = 0
        self.consecutiveLoginDays = 0
        self.lastLoginDate = nil
        self.dailyTimeLimitMinutes = 20
    }

    var difficultyLevel: DifficultyLevel {
        get { DifficultyLevel(rawValue: currentLevel) ?? .seed }
        set { currentLevel = newValue.rawValue }
    }
}
