import Testing
@testable import NumberOrchard

@Test func oneStarGrants3StarsAnd1Seed() {
    let calc = RewardCalculator()
    let reward = calc.calculate(stars: 1, isFirstCompletion: true, station: MapCatalog.station(id: "L1-1")!)
    #expect(reward.starsEarned == 3)
    #expect(reward.seedsEarned == 1)
}

@Test func twoStarsGrantsBonus() {
    let calc = RewardCalculator()
    let reward = calc.calculate(stars: 2, isFirstCompletion: true, station: MapCatalog.station(id: "L1-1")!)
    #expect(reward.starsEarned == 5)
    #expect(reward.seedsEarned == 1)
}

@Test func threeStarsGrantsFruit() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let reward = calc.calculate(stars: 3, isFirstCompletion: true, station: station)
    #expect(reward.starsEarned == 8)
    #expect(reward.fruitIdEarned == "apple")
}

@Test func subsequentCompletionGivesNoExtraFruit() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let reward = calc.calculate(stars: 3, isFirstCompletion: false, station: station)
    #expect(reward.starsEarned == 8)  // stars reward still given
    #expect(reward.fruitIdEarned == nil)
    #expect(reward.seedsEarned == 0)
}

@Test func rewardIsDeterministic() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let r1 = calc.calculate(stars: 2, isFirstCompletion: true, station: station)
    let r2 = calc.calculate(stars: 2, isFirstCompletion: true, station: station)
    #expect(r1.starsEarned == r2.starsEarned)
}
