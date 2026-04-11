import Testing
@testable import NumberOrchard

@Test func softReminderAt80Percent() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 10) == .none)
    #expect(manager.alertLevel(afterMinutes: 15) == .none)
    #expect(manager.alertLevel(afterMinutes: 16) == .soft)
    #expect(manager.alertLevel(afterMinutes: 19) == .soft)
}

@Test func gentleReminderAtLimit() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 20) == .gentle)
    #expect(manager.alertLevel(afterMinutes: 23) == .gentle)
}

@Test func forceLockAfterFiveMinutesOver() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 25) == .locked)
    #expect(manager.alertLevel(afterMinutes: 30) == .locked)
}

@Test func customTimeLimitWorks() {
    let manager = EyeCareManager(timeLimitMinutes: 10)

    #expect(manager.alertLevel(afterMinutes: 7) == .none)
    #expect(manager.alertLevel(afterMinutes: 8) == .soft)
    #expect(manager.alertLevel(afterMinutes: 10) == .gentle)
    #expect(manager.alertLevel(afterMinutes: 15) == .locked)
}
