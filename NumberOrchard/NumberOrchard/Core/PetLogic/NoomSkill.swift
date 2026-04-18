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

    /// Two tiers of skill power. Tier 1 unlocks at Teen (stage 1), Tier 2
    /// at Adult (stage 2). All game-side callers should resolve the
    /// effective tier via `tier(forStage:)` rather than branching on
    /// `stage` directly — future tiers (e.g. a legendary form) slot in
    /// here by extending the enum.
    enum Tier: Int, Sendable, Comparable {
        case none = 0   // baby / skill locked
        case one  = 1   // teen
        case two  = 2   // adult
        static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    static func tier(forStage stage: Int) -> Tier {
        switch stage {
        case 0: return .none
        case 1: return .one
        default: return .two
        }
    }

    /// Effect magnitude at each tier. Values are the *actual* numbers
    /// used by the game systems — not the narrative copy. See
    /// `explanation(forTier:)` for the human string.
    // XP boost — fractional multiplier applied on top of base XP.
    // Tier 1 = +50% → 0.50, Tier 2 = +100% → 1.00.
    static func xpBoostFraction(tier: Tier) -> Double {
        switch tier {
        case .none: return 0.0
        case .one:  return 0.50
        case .two:  return 1.00
        }
    }

    // Legendary drop rate multiplier on top of the default rate.
    static func luckyDropMultiplier(tier: Tier) -> Double {
        switch tier {
        case .none: return 1.0
        case .one:  return 2.0
        case .two:  return 4.0
        }
    }

    // Flat bonus points per correct dice answer.
    static func diceBonusPoints(tier: Tier) -> Int {
        switch tier {
        case .none: return 0
        case .one:  return 5
        case .two:  return 10
        }
    }

    // Starting combo for MatchTen.
    static func comboSeed(tier: Tier) -> Int {
        switch tier {
        case .none: return 0
        case .one:  return 1
        case .two:  return 2
        }
    }

    // Extra thinking seconds in the Theater countdown.
    static func calmClockBonusSeconds(tier: Tier) -> TimeInterval {
        switch tier {
        case .none: return 0
        case .one:  return 2
        case .two:  return 4
        }
    }

    /// Human-readable explanation for the pet-card / diary / parent report.
    /// Falls back to Tier 1 wording if called with `.none`.
    func explanation(tier: Tier) -> String {
        switch (self, tier) {
        case (.xpBoost,   .two):  return "喂食多获得 100% 经验 (已成年)"
        case (.xpBoost,   _):     return "喂食多获得 50% 经验"
        case (.luckyDrop, .two):  return "稀有掉落率 ×4 (已成年)"
        case (.luckyDrop, _):     return "稀有水果掉落率翻倍"
        case (.diceBonus, .two):  return "骰子每题 +10 分 (已成年)"
        case (.diceBonus, _):     return "骰子速算每题 +5 分"
        case (.comboSeed, .two):  return "消消乐起手 ×2 连击 (已成年)"
        case (.comboSeed, _):     return "消消乐起手就有连击"
        case (.calmClock, .two):  return "数学剧场多给 4 秒 (已成年)"
        case (.calmClock, _):     return "数学剧场多给 2 秒"
        }
    }
}
