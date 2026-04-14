import Foundation
import SwiftData

@Model
final class PetProgress {
    var noomNumber: Int
    var xp: Int
    var stage: Int        // 0 = baby, 1 = teen, 2 = adult
    var matureAt: Date?
    var isActive: Bool

    @Relationship(inverse: \ChildProfile.petProgress)
    var profile: ChildProfile?

    init(noomNumber: Int) {
        self.noomNumber = noomNumber
        self.xp = 0
        self.stage = 0
        self.matureAt = nil
        self.isActive = false
    }
}
