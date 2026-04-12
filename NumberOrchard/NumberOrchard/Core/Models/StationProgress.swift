import Foundation
import SwiftData

@Model
final class StationProgress {
    var stationId: String
    var stars: Int
    var bestAccuracy: Double
    var attemptsCount: Int
    var unlocked: Bool

    @Relationship(inverse: \ChildProfile.stationProgress)
    var profile: ChildProfile?

    init(stationId: String, unlocked: Bool = false) {
        self.stationId = stationId
        self.stars = 0
        self.bestAccuracy = 0
        self.attemptsCount = 0
        self.unlocked = unlocked
    }
}
