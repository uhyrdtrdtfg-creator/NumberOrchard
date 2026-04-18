import Testing
@testable import NumberOrchard

@Test func skinCatalogHasSixHats() {
    #expect(NoomSkinCatalog.all.count == 6)
}

@Test func skinIdsAreUnique() {
    let ids = NoomSkinCatalog.all.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func skinLookupByIdWorks() {
    let expected = NoomSkinCatalog.all.first!
    #expect(NoomSkinCatalog.skin(id: expected.id)?.id == expected.id)
    #expect(NoomSkinCatalog.skin(id: "nonexistent") == nil)
}

@Test func skinCostsAreAscending() {
    // Keep the catalog ordered cheapest-first so the wardrobe grid
    // naturally surfaces affordable hats before premium ones.
    let costs = NoomSkinCatalog.all.map(\.cost)
    for i in 1..<costs.count {
        #expect(costs[i] >= costs[i - 1],
                "hat at index \(i) cost \(costs[i]) should be ≥ previous \(costs[i - 1])")
    }
}

@Test func skinGlyphsAreNonEmpty() {
    for skin in NoomSkinCatalog.all {
        #expect(!skin.glyph.isEmpty)
        #expect(!skin.name.isEmpty)
        #expect(!skin.flavour.isEmpty)
    }
}
