import Testing
@testable import NumberOrchard

@Test func kitchenEmptyRecipeNotComplete() {
    let r = CookingRecipe(target: ["apple": 2, "strawberry": 3])
    #expect(r.isComplete == false)
    #expect(r.totalBasket == 0)
    #expect(r.totalTarget == 5)
}

@Test func kitchenExactMatchMarksComplete() {
    var r = CookingRecipe(target: ["apple": 2, "strawberry": 1])
    r.add("apple"); r.add("apple"); r.add("strawberry")
    #expect(r.isComplete == true)
    #expect(r.isOverfilled == false)
}

@Test func kitchenOverfillIsDetected() {
    var r = CookingRecipe(target: ["apple": 1])
    r.add("apple"); r.add("apple")
    #expect(r.isOverfilled == true)
    #expect(r.isComplete == false)
}

@Test func kitchenRemoveDecrements() {
    var r = CookingRecipe(target: ["apple": 2])
    r.add("apple"); r.add("apple")
    r.remove("apple")
    #expect(r.basket["apple"] == 1)
}

@Test func kitchenDumpEmptiesBasket() {
    var r = CookingRecipe(target: ["apple": 1, "strawberry": 1])
    r.add("apple"); r.add("strawberry")
    r.dumpBasket()
    #expect(r.totalBasket == 0)
}

@Test func kitchenGeneratorProducesValidRecipe() {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<30 {
        let r = CookingRecipeGenerator.makeRecipe(maxTotal: 7, rng: &rng)
        #expect(r.target.count >= 2 && r.target.count <= 3)
        let total = r.target.values.reduce(0, +)
        #expect(total >= 3 && total <= 7)
        for (id, count) in r.target {
            #expect(count >= 1)
            #expect(CookingRecipeGenerator.pantryIds.contains(id))
        }
    }
}
