import Testing
@testable import NumberOrchard

@Test func catalogHasTwentyNooms() {
    #expect(NoomCatalog.all.count == 20)
}

@Test func noomNumbersAreOneThroughTwenty() {
    let numbers = NoomCatalog.all.map(\.number).sorted()
    #expect(numbers == Array(1...20))
}

@Test func smallNoomsArePartitioned() {
    #expect(NoomCatalog.smallNooms.count == 10)
    #expect(NoomCatalog.smallNooms.allSatisfy { $0.number <= 10 })
}

@Test func bigNoomsArePartitioned() {
    #expect(NoomCatalog.bigNooms.count == 10)
    #expect(NoomCatalog.bigNooms.allSatisfy { $0.number >= 11 })
}

@Test func noomNamesAreUnique() {
    let names = NoomCatalog.all.map(\.name)
    #expect(Set(names).count == names.count)
}

@Test func lookupByNumberWorks() {
    #expect(NoomCatalog.noom(for: 1)?.name == "小一")
    #expect(NoomCatalog.noom(for: 10)?.name == "十全")
    #expect(NoomCatalog.noom(for: 11)?.name == "大十一")
    #expect(NoomCatalog.noom(for: 20)?.name == "廿宝")
    #expect(NoomCatalog.noom(for: 0) == nil)
    #expect(NoomCatalog.noom(for: 21) == nil)
}

@Test func everyNoomHasNonEmptyCatchphrase() {
    for noom in NoomCatalog.all {
        #expect(!noom.catchphrase.isEmpty, "Noom \(noom.number) missing catchphrase")
    }
}
