import Foundation
import SwiftData

@Model
final class LearningSession {
    var date: Date
    var durationSeconds: Double
    var level: Int

    @Relationship(deleteRule: .cascade)
    var records: [QuestionRecord] = []

    @Relationship(inverse: \ChildProfile.sessions)
    var profile: ChildProfile?

    init(level: DifficultyLevel) {
        self.date = Date()
        self.durationSeconds = 0
        self.level = level.rawValue
    }

    var correctCount: Int {
        records.filter(\.isCorrect).count
    }

    var accuracy: Double {
        guard !records.isEmpty else { return 0 }
        return Double(correctCount) / Double(records.count)
    }
}
