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
