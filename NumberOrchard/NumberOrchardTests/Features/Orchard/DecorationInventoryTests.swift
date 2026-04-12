import Testing
@testable import NumberOrchard

@Test func catalogHas53Decorations() {
    #expect(DecorationCatalog.items.count == 53)
}

@Test func allSevenCategoriesPresent() {
    let categories = Set(DecorationCatalog.items.map(\.category))
    #expect(categories == Set(DecorationCategory.allCases))
}

@Test func decorationIdsAreUnique() {
    let ids = DecorationCatalog.items.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func purchaseDeductsStars() {
    let logic = DecorationPurchaseLogic()
    let item = DecorationCatalog.item(id: "daisy")!
    let result = logic.purchase(item: item, availableStars: 10)
    #expect(result.success == true)
    #expect(result.remainingStars == 5)
}

@Test func purchaseFailsWithInsufficientStars() {
    let logic = DecorationPurchaseLogic()
    let item = DecorationCatalog.item(id: "castle")!
    let result = logic.purchase(item: item, availableStars: 30)
    #expect(result.success == false)
    #expect(result.remainingStars == 30)
}
