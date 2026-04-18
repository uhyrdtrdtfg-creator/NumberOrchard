import Testing
import Foundation
@testable import NumberOrchard

@Test func gachaClaimableWhenNeverClaimed() {
    #expect(DailyGachaLogic.isClaimable(lastClaim: nil) == true)
}

@Test func gachaNotClaimableSameDay() {
    let cal = Calendar.current
    let base = Date()
    let sameDay = cal.date(bySettingHour: 23, minute: 59, second: 0, of: base)!
    let earlier = cal.date(bySettingHour: 0, minute: 1, second: 0, of: base)!
    #expect(DailyGachaLogic.isClaimable(lastClaim: earlier, now: sameDay, calendar: cal) == false)
}

@Test func gachaClaimableNextDay() {
    let cal = Calendar.current
    let today = Date()
    let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
    #expect(DailyGachaLogic.isClaimable(lastClaim: yesterday, now: today, calendar: cal) == true)
}

@Test func nextClaimDateIsDayAfterLastClaim() {
    let cal = Calendar.current
    let noonToday = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    let next = DailyGachaLogic.nextClaimDate(lastClaim: noonToday, calendar: cal)!
    let expected = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: noonToday))!
    #expect(cal.isDate(next, inSameDayAs: expected))
}

@Test func rollReturnsFromPool() {
    var rng = SystemRandomNumberGenerator()
    let pool = NoomSkinCatalog.gachaEligible()
    let drop = DailyGachaLogic.roll(pool: pool, rng: &rng)
    #expect(drop != nil)
    if let d = drop { #expect(pool.contains(d)) }
}

@Test func rollFromEmptyPoolReturnsNil() {
    var rng = SystemRandomNumberGenerator()
    #expect(DailyGachaLogic.roll(pool: [], rng: &rng) == nil)
}
