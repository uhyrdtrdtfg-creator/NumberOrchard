import Foundation

enum DifficultyLevel: Int, Codable, Comparable, CaseIterable, Sendable {
    case seed = 1       // L1: 5 以内加法
    case sprout = 2     // L2: 5 以内加减法
    case smallTree = 3  // L3: 10 以内加法
    case bigTree = 4    // L4: 10 以内加减法
    case bloom = 5      // L5: 20 以内加法 (含进位)
    case harvest = 6    // L6: 20 以内加减法 (含进退位)

    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .seed: return "种子"
        case .sprout: return "发芽"
        case .smallTree: return "小树"
        case .bigTree: return "大树"
        case .bloom: return "开花"
        case .harvest: return "结果"
        }
    }

    var maxNumber: Int {
        switch self {
        case .seed, .sprout: return 5
        case .smallTree, .bigTree: return 10
        case .bloom, .harvest: return 20
        }
    }

    var allowsSubtraction: Bool {
        switch self {
        case .seed, .smallTree, .bloom: return false
        case .sprout, .bigTree, .harvest: return true
        }
    }

    var promotionThreshold: Double {
        switch self {
        case .seed: return 0.80
        case .sprout: return 0.75
        case .smallTree: return 0.75
        case .bigTree: return 0.70
        case .bloom: return 0.70
        case .harvest: return 0.70
        }
    }

    var minimumQuestionsForPromotion: Int { 10 }
}
