import Foundation

/// Per-Noom passive skills. Each owned Noom has one lifelong skill that
/// passively buffs the child's play session while that Noom is *active*
/// (the one displayed in the pet feeding area). Skills make the choice
/// of "which Noom to keep active" a meaningful strategic decision.
///
/// Skills unlock at `stage >= 1` (少年) — a reward for raising the pet
/// through evolutions rather than something the child gets for free on
/// first catch.
enum NoomSkill: String, Sendable, CaseIterable, Codable {
    /// +50% XP on every fruit feeding.
    case xpBoost
    /// Doubles the legendary-drop rate in theater + dice mini-games.
    case luckyDrop
    /// +5 bonus points on every correct 骰子速算 answer.
    case diceBonus
    /// Starts 凑十消消乐 sessions with combo = 1 instead of 0.
    case comboSeed
    /// Gives 2 more seconds of thinking time per question in theater.
    case calmClock

    var displayName: String {
        switch self {
        case .xpBoost:    return "经验加成"
        case .luckyDrop:  return "幸运掉落"
        case .diceBonus:  return "骰子奖励"
        case .comboSeed:  return "连击起手"
        case .calmClock:  return "从容思考"
        }
    }

    var emoji: String {
        switch self {
        case .xpBoost:    return "⬆️"
        case .luckyDrop:  return "🍀"
        case .diceBonus:  return "🎲"
        case .comboSeed:  return "🔥"
        case .calmClock:  return "⏳"
        }
    }

    /// One-liner the parent/child sees in the feeding area and diary.
    var explanation: String {
        switch self {
        case .xpBoost:    return "喂食多获得 50% 经验"
        case .luckyDrop:  return "稀有水果掉落率翻倍"
        case .diceBonus:  return "骰子速算每题 +5 分"
        case .comboSeed:  return "消消乐起手就有连击"
        case .calmClock:  return "数学剧场多给 2 秒"
        }
    }
}

/// Deterministic mapping from Noom number (1-20) to its skill. The 5
/// skills cycle so each appears 4 times across the catalog, ensuring
/// every strategic playstyle can be realised from the earliest Nooms.
enum NoomSkillCatalog {
    static func skill(for noomNumber: Int) -> NoomSkill {
        switch noomNumber {
        // Small Nooms — gentle bumps to keep early play engaging.
        case 1:  return .xpBoost
        case 2:  return .luckyDrop
        case 3:  return .diceBonus
        case 4:  return .comboSeed
        case 5:  return .calmClock
        case 6:  return .xpBoost
        case 7:  return .luckyDrop
        case 8:  return .diceBonus
        case 9:  return .comboSeed
        case 10: return .calmClock
        // Big Nooms — same skill pool, kids re-encounter their favourite.
        case 11: return .xpBoost
        case 12: return .luckyDrop
        case 13: return .diceBonus
        case 14: return .comboSeed
        case 15: return .calmClock
        case 16: return .xpBoost
        case 17: return .luckyDrop
        case 18: return .diceBonus
        case 19: return .comboSeed
        case 20: return .calmClock
        default: return .xpBoost
        }
    }
}

/// Runtime gate: is the skill unlocked based on the pet's stage?
/// Hidden until Teen (stage 1); visible in the pet card but inert at Baby.
extension NoomSkill {
    static func isUnlocked(stage: Int) -> Bool { stage >= 1 }
}
