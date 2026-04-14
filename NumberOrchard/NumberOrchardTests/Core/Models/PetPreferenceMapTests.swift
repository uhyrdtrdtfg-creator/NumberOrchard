import Testing
@testable import NumberOrchard

@Test func every1To20HasPreferences() {
    for n in 1...20 {
        let prefs = PetPreferenceMap.preferences[n]
        #expect(prefs != nil, "Noom \(n) missing preferences")
        #expect(!(prefs?.isEmpty ?? true), "Noom \(n) has empty preferences")
    }
}

@Test func preferenceFruitIdsExistInFruitCatalog() {
    for (noomNum, fruitIds) in PetPreferenceMap.preferences {
        for fruitId in fruitIds {
            #expect(FruitCatalog.fruit(id: fruitId) != nil,
                    "Noom \(noomNum) preference '\(fruitId)' not in FruitCatalog")
        }
    }
}

@Test func isPreferredReturnsTrueForMatching() {
    #expect(PetPreferenceMap.isPreferred(fruitId: "apple", for: 1) == true)
    #expect(PetPreferenceMap.isPreferred(fruitId: "watermelon", for: 5) == true)
}

@Test func isPreferredReturnsFalseForNonMatching() {
    #expect(PetPreferenceMap.isPreferred(fruitId: "watermelon", for: 1) == false)
    #expect(PetPreferenceMap.isPreferred(fruitId: "fake_fruit", for: 5) == false)
    #expect(PetPreferenceMap.isPreferred(fruitId: "apple", for: 999) == false)
}
