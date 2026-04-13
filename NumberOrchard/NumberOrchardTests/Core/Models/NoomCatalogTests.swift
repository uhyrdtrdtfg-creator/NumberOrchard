import Testing
@testable import NumberOrchard

@Test func catalogHasTenNooms() {
    #expect(NoomCatalog.all.count == 10)
}

@Test func noomNumbersAreOneThroughTen() {
    let numbers = NoomCatalog.all.map(\.number).sorted()
    #expect(numbers == Array(1...10))
}

@Test func noomNamesAreUnique() {
    let names = NoomCatalog.all.map(\.name)
    #expect(Set(names).count == names.count)
}

@Test func lookupByNumberWorks() {
    #expect(NoomCatalog.noom(for: 1)?.name == "小一")
    #expect(NoomCatalog.noom(for: 10)?.name == "十全")
    #expect(NoomCatalog.noom(for: 0) == nil)
    #expect(NoomCatalog.noom(for: 11) == nil)
}

@Test func everyNoomHasNonEmptyCatchphrase() {
    for noom in NoomCatalog.all {
        #expect(!noom.catchphrase.isEmpty, "Noom \(noom.number) missing catchphrase")
    }
}
