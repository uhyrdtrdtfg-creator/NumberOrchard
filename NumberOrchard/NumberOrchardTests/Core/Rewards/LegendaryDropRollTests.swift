import Testing
@testable import NumberOrchard

@Test func legendaryRollRespectsLowRate() {
    // 0% rate should never drop.
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<100 {
        #expect(LegendaryDropRoll.roll(rate: 0.0, rng: &rng) == nil)
    }
}

@Test func legendaryRollRespectsHighRate() {
    // 100% rate should always drop a legendary fruit.
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<50 {
        let drop = LegendaryDropRoll.roll(rate: 1.0, rng: &rng)
        #expect(drop != nil)
        #expect(drop?.rarity == .legendary)
    }
}

@Test func legendaryRollApproximatesConfiguredRate() {
    // Over 5000 trials with rate 0.1, drops should fall roughly in [7%, 13%].
    var rng = SystemRandomNumberGenerator()
    var drops = 0
    for _ in 0..<5000 {
        if LegendaryDropRoll.roll(rate: 0.1, rng: &rng) != nil { drops += 1 }
    }
    let observed = Double(drops) / 5000.0
    #expect(observed > 0.07 && observed < 0.13,
            "observed rate \(observed) should be near 0.10 ± 3%")
}

@Test func legendaryPoolMatchesCatalogRarity() {
    let pool = LegendaryDropRoll.eligibleFruits
    #expect(!pool.isEmpty)
    #expect(pool.allSatisfy { $0.rarity == .legendary })
}
