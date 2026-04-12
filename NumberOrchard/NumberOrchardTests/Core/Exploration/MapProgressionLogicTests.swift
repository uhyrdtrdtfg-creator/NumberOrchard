import Testing
@testable import NumberOrchard

@Test func initialStationUnlocked() {
    let logic = MapProgressionLogic()
    let completed: Set<String> = []
    #expect(logic.isUnlocked(stationId: "L1-1", completedStations: completed) == true)
    #expect(logic.isUnlocked(stationId: "L1-2", completedStations: completed) == false)
}

@Test func completingStationUnlocksConnected() {
    let logic = MapProgressionLogic()
    let completed: Set<String> = ["L1-1"]
    #expect(logic.isUnlocked(stationId: "L1-2", completedStations: completed) == true)
    #expect(logic.isUnlocked(stationId: "L1-3", completedStations: completed) == false)
}

@Test func starRatingFromAccuracy() {
    let logic = MapProgressionLogic()
    #expect(logic.starsFor(accuracy: 1.0, usedHint: false) == 3)
    #expect(logic.starsFor(accuracy: 1.0, usedHint: true) == 2)
    #expect(logic.starsFor(accuracy: 0.8, usedHint: false) == 2)
    #expect(logic.starsFor(accuracy: 0.6, usedHint: false) == 1)
    #expect(logic.starsFor(accuracy: 0.0, usedHint: false) == 1)
}

@Test func starsOnlyIncreaseNeverDecrease() {
    let logic = MapProgressionLogic()
    #expect(logic.updateStars(current: 3, new: 2) == 3)
    #expect(logic.updateStars(current: 1, new: 3) == 3)
    #expect(logic.updateStars(current: 2, new: 2) == 2)
}

@Test func endStationUnlocksWhenAnyL6Complete() {
    let logic = MapProgressionLogic()
    #expect(logic.isUnlocked(stationId: "end", completedStations: ["L6-1"]) == true)
    #expect(logic.isUnlocked(stationId: "end", completedStations: ["L5-1"]) == false)
}
