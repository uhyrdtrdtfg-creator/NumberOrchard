import Foundation
import SwiftData

/// A wardrobe purchase. One row per (child, skin) combination the child
/// has bought. The `equippedOnNoomNumber` field is non-nil when the
/// child has put this hat on a specific Noom; otherwise the hat sits in
/// the closet. A Noom can wear at most one hat at a time — the VM
/// enforces that invariant by clearing other rows' `equippedOnNoomNumber`
/// before setting a new one.
@Model
final class CollectedSkin {
    var skinId: String
    var purchasedAt: Date
    var equippedOnNoomNumber: Int?

    @Relationship(inverse: \ChildProfile.collectedSkins)
    var profile: ChildProfile?

    init(skinId: String, equippedOnNoomNumber: Int? = nil) {
        self.skinId = skinId
        self.purchasedAt = Date()
        self.equippedOnNoomNumber = equippedOnNoomNumber
    }
}
