import Foundation
import SwiftData

@Model
final class CollectedFruit {
    var fruitId: String
    var unlockedAt: Date
    var unlockedFromStationId: String?

    @Relationship(inverse: \ChildProfile.collectedFruits)
    var profile: ChildProfile?

    init(fruitId: String, unlockedFromStationId: String? = nil) {
        self.fruitId = fruitId
        self.unlockedAt = Date()
        self.unlockedFromStationId = unlockedFromStationId
    }
}
