import Foundation
import SwiftData

@Model
final class QuestionRecord {
    var operand1: Int
    var operand2: Int
    var operation: String
    var gameMode: String
    var userAnswer: Int
    var isCorrect: Bool
    var responseTimeSeconds: Double
    var usedHint: Bool
    var timestamp: Date

    @Relationship(inverse: \LearningSession.records)
    var session: LearningSession?

    init(question: MathQuestion, userAnswer: Int, responseTime: TimeInterval, usedHint: Bool) {
        self.operand1 = question.operand1
        self.operand2 = question.operand2
        self.operation = question.operation.rawValue
        self.gameMode = question.gameMode.rawValue
        self.userAnswer = userAnswer
        self.isCorrect = (userAnswer == question.correctAnswer)
        self.responseTimeSeconds = responseTime
        self.usedHint = usedHint
        self.timestamp = Date()
    }
}
