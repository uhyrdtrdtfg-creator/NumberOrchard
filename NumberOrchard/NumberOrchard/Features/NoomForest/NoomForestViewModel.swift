import SwiftUI
import Observation

@Observable
@MainActor
final class NoomForestViewModel {
    let profile: ChildProfile

    init(profile: ChildProfile) {
        self.profile = profile
    }

    var unlockedNumbers: Set<Int> {
        Set(profile.collectedNooms.map(\.noomNumber))
    }

    var unlockedCount: Int { unlockedNumbers.count }

    func isUnlocked(_ number: Int) -> Bool { unlockedNumbers.contains(number) }
}
