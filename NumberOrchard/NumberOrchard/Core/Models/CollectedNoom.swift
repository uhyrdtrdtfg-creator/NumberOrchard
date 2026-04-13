import Foundation
import SwiftData

@Model
final class CollectedNoom {
    var noomNumber: Int
    var unlockedAt: Date
    var encounterCount: Int

    @Relationship(inverse: \ChildProfile.collectedNooms)
    var profile: ChildProfile?

    init(noomNumber: Int) {
        self.noomNumber = noomNumber
        self.unlockedAt = Date()
        self.encounterCount = 1
    }
}
