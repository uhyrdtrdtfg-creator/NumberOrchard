import Foundation

enum MathOperation: String, Codable, Sendable {
    case add
    case subtract
}

enum GameMode: String, Codable, Sendable, CaseIterable {
    case pickFruit   // 摘果子 (加法)
    case shareFruit  // 分果果 (减法)
    case numberTrain // 数字火车 (凑十法)
    case balance     // 天平乐园 (等式)
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
        switch gameMode {
        case .pickFruit:
            return "篮子里有 \(operand1) 个，再摘 \(operand2) 个，一共几个？"
        case .shareFruit:
            return "盘子里有 \(operand1) 个，分给小兔 \(operand2) 个，还剩几个？"
        case .numberTrain:
            let total = operand1 + operand2
            return "火车有 \(total) 个座位，坐了 \(operand1) 个，还有几个空座？"
        case .balance:
            let total = correctAnswer
            return "天平左边有 \(total) 个，右边有 \(operand1) 个，再放几个能平衡？"
        }
    }
}
