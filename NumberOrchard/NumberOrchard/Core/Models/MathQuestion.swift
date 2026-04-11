import Foundation

enum MathOperation: String, Codable, Sendable {
    case add
    case subtract
}

enum GameMode: String, Codable, Sendable {
    case pickFruit
    case shareFruit
}

struct MathQuestion: Codable, Sendable, Equatable {
    let operand1: Int
    let operand2: Int
    let operation: MathOperation
    let gameMode: GameMode

    var correctAnswer: Int {
        switch operation {
        case .add: return operand1 + operand2
        case .subtract: return operand1 - operand2
        }
    }

    var displayText: String {
        switch operation {
        case .add:
            return "篮子里有 \(operand1) 个，再摘 \(operand2) 个，一共几个？"
        case .subtract:
            return "盘子里有 \(operand1) 个，分给小兔 \(operand2) 个，还剩几个？"
        }
    }
}
