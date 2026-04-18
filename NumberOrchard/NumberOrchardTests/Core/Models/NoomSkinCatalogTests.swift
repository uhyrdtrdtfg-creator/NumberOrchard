import Testing
@testable import NumberOrchard

@Test func skinCatalogSizeMatchesCurrentRoster() {
    // Catalog grew past the original 6 hats when collars were added.
    // Guard just the current size so the test flags intentional roster
    // changes.
    #expect(NoomSkinCatalog.all.count == 10)
}

@Test func catalogContainsBothSlots() {
    let hats = NoomSkinCatalog.all.filter { $0.slot == .hat }
    let collars = NoomSkinCatalog.all.filter { $0.slot == .collar }
    #expect(hats.count >= 1)
    #expect(collars.count >= 1)
}

@Test func gachaPoolExcludesPremiumAndLockedItems() {
    let pool = NoomSkinCatalog.gachaEligible()
    for skin in pool {
        #expect(skin.unlockStage == 0,
                "gacha should not roll stage-gated items (\(skin.id))")
        #expect(skin.cost <= 10,
                "gacha pool should cap cost at 10 (\(skin.id)=\(skin.cost))")
    }
}

@Test func premiumItemsRequireAdultStage() {
    // Sanity: the 15+ star hats should be adult-only so the child has
    // a reason to raise pets to stage 2 before buying them.
    let pricy = NoomSkinCatalog.all.filter { $0.cost >= 15 }
    #expect(!pricy.isEmpty)
    for skin in pricy {
        #expect(skin.unlockStage == 2, "\(skin.id) should be adult-gated")
    }
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

@Test func skinCostsAreAscendingWithinEachSlot() {
    // Within each slot the catalog is ordered cheapest-first so the
    // wardrobe grid naturally surfaces affordable items before premium
    // ones. (Global ordering doesn't hold — collars start fresh after
    // hats — so we assert per-slot.)
    for slot in NoomSkin.Slot.allCases {
        let costs = NoomSkinCatalog.all.filter { $0.slot == slot }.map(\.cost)
        for i in 1..<costs.count {
            #expect(costs[i] >= costs[i - 1],
                    "\(slot) index \(i) cost \(costs[i]) should be ≥ previous \(costs[i - 1])")
        }
    }
}

@Test func skinGlyphsAreNonEmpty() {
    for skin in NoomSkinCatalog.all {
        #expect(!skin.glyph.isEmpty)
        #expect(!skin.name.isEmpty)
        #expect(!skin.flavour.isEmpty)
    }
}
