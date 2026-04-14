import SwiftUI
import Observation

enum NoomForestTab: Sendable, CaseIterable, Hashable {
    case dex
    case garden

    var title: String {
        switch self {
        case .dex: return "📖 图鉴"
        case .garden: return "🌻 宠物花园"
        }
    }
}

@Observable
@MainActor
final class NoomForestViewModel {
    let profile: ChildProfile
    var selectedTab: NoomForestTab = .dex

    init(profile: ChildProfile) {
        self.profile = profile
    }

    var unlockedNumbers: Set<Int> {
        Set(profile.collectedNooms.map(\.noomNumber))
    }

    var unlockedCount: Int { unlockedNumbers.count }

    func isUnlocked(_ number: Int) -> Bool { unlockedNumbers.contains(number) }
}
