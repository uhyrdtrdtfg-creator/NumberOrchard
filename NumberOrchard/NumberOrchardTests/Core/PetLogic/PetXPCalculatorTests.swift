import Testing
@testable import NumberOrchard

@Test func nonPreferredFruitGivesBaseXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "watermelon", noomNumber: 1) == 10)
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 5) == 10)
}

@Test func preferredFruitGivesDoubleXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 1) == 20)
    #expect(calc.xpFor(fruitId: "strawberry", noomNumber: 1) == 20)
    #expect(calc.xpFor(fruitId: "watermelon", noomNumber: 5) == 20)
}

@Test func unknownFruitGivesBaseXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "fake_fruit_xyz", noomNumber: 5) == 10)
}

@Test func unknownNoomNumberGivesBaseXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 999) == 10)
}
