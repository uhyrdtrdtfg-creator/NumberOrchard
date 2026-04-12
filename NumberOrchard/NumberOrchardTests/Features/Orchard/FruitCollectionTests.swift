import Testing
@testable import NumberOrchard

@Test func catalogHas30Fruits() {
    #expect(FruitCatalog.fruits.count == 30)
}

@Test func fifteenCommonTenRareFiveLegendary() {
    #expect(FruitCatalog.fruits(rarity: .common).count == 15)
    #expect(FruitCatalog.fruits(rarity: .rare).count == 10)
    #expect(FruitCatalog.fruits(rarity: .legendary).count == 5)
}

@Test func fruitIdsAreUnique() {
    let ids = FruitCatalog.fruits.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func mapCatalogStationsMapToValidFruits() {
    for station in MapCatalog.stations {
        if let fruitId = station.starFruitId {
            #expect(FruitCatalog.fruit(id: fruitId) != nil, "Station \(station.id) references unknown fruit \(fruitId)")
        }
    }
}
