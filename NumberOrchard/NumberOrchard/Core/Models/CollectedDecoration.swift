import Foundation
import SwiftData

@Model
final class CollectedDecoration {
    var itemId: String
    var acquiredAt: Date
    var isPlaced: Bool
    var positionX: Double  // 0.0 - 1.0
    var positionY: Double

    @Relationship(inverse: \ChildProfile.decorations)
    var profile: ChildProfile?

    init(itemId: String) {
        self.itemId = itemId
        self.acquiredAt = Date()
        self.isPlaced = false
        self.positionX = 0.5
        self.positionY = 0.5
    }
}
