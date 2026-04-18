import Testing
@testable import NumberOrchard

@Test func everyNoomHasSkill() {
    for n in 1...20 {
        let skill = NoomSkillCatalog.skill(for: n)
        #expect(NoomSkill.allCases.contains(skill))
    }
}

@Test func skillDistributionCoversAllFiveArchetypes() {
    var seen: Set<NoomSkill> = []
    for n in 1...20 {
        seen.insert(NoomSkillCatalog.skill(for: n))
    }
    #expect(seen.count == NoomSkill.allCases.count,
            "each of the 5 skills should be assigned to at least one Noom")
}

@Test func skillLockedAtStageZero() {
    #expect(NoomSkill.isUnlocked(stage: 0) == false)
}

@Test func skillUnlockedAtStageOne() {
    #expect(NoomSkill.isUnlocked(stage: 1) == true)
    #expect(NoomSkill.isUnlocked(stage: 2) == true)
}

@Test func skillHasDisplayMetadata() {
    for skill in NoomSkill.allCases {
        #expect(!skill.displayName.isEmpty)
        #expect(!skill.emoji.isEmpty)
        #expect(!skill.explanation.isEmpty)
    }
}

@Test func matchTenComboSeedStartsAtOne() {
    let g = MatchTenGame(rows: 2, cols: 2, targetClears: 1, startingCombo: 1)
    #expect(g.combo == 1)
}

@Test func matchTenDefaultComboStartsAtZero() {
    let g = MatchTenGame(rows: 2, cols: 2, targetClears: 1)
    #expect(g.combo == 0)
}

// MARK: - Tier 2 scaling

@Test func tierForStageMapsCorrectly() {
    #expect(NoomSkill.tier(forStage: 0) == .none)
    #expect(NoomSkill.tier(forStage: 1) == .one)
    #expect(NoomSkill.tier(forStage: 2) == .two)
    #expect(NoomSkill.tier(forStage: 99) == .two)  // future-proof ceiling
}

@Test func xpBoostFractionDoublesAtTierTwo() {
    #expect(NoomSkill.xpBoostFraction(tier: .none) == 0.0)
    #expect(NoomSkill.xpBoostFraction(tier: .one) == 0.5)
    #expect(NoomSkill.xpBoostFraction(tier: .two) == 1.0)
}

@Test func luckyDropMultiplierDoublesAtTierTwo() {
    #expect(NoomSkill.luckyDropMultiplier(tier: .none) == 1.0)
    #expect(NoomSkill.luckyDropMultiplier(tier: .one) == 2.0)
    #expect(NoomSkill.luckyDropMultiplier(tier: .two) == 4.0)
}

@Test func diceBonusPointsDoubleAtTierTwo() {
    #expect(NoomSkill.diceBonusPoints(tier: .none) == 0)
    #expect(NoomSkill.diceBonusPoints(tier: .one) == 5)
    #expect(NoomSkill.diceBonusPoints(tier: .two) == 10)
}

@Test func comboSeedEscalatesAtTierTwo() {
    #expect(NoomSkill.comboSeed(tier: .none) == 0)
    #expect(NoomSkill.comboSeed(tier: .one) == 1)
    #expect(NoomSkill.comboSeed(tier: .two) == 2)
}

@Test func calmClockBonusDoublesAtTierTwo() {
    #expect(NoomSkill.calmClockBonusSeconds(tier: .none) == 0)
    #expect(NoomSkill.calmClockBonusSeconds(tier: .one) == 2)
    #expect(NoomSkill.calmClockBonusSeconds(tier: .two) == 4)
}

@Test func explanationStringsDifferByTier() {
    // Every skill's Tier-2 explanation should visibly differ from Tier-1,
    // otherwise the in-UI progression feels cosmetic.
    for skill in NoomSkill.allCases {
        let t1 = skill.explanation(tier: .one)
        let t2 = skill.explanation(tier: .two)
        #expect(t1 != t2,
                "\(skill) explanations should differ between tiers (got \(t1))")
    }
}
