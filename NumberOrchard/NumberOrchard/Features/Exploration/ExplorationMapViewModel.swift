import SwiftUI
import Observation

@Observable
@MainActor
final class ExplorationMapViewModel {
    let profile: ChildProfile
    private let mapLogic = MapProgressionLogic()

    init(profile: ChildProfile) {
        self.profile = profile
    }

    var completedStationIds: Set<String> {
        Set(profile.stationProgress.filter { $0.stars > 0 }.map(\.stationId))
    }

    func stars(for stationId: String) -> Int {
        profile.stationProgress.first { $0.stationId == stationId }?.stars ?? 0
    }

    func isUnlocked(_ stationId: String) -> Bool {
        mapLogic.isUnlocked(stationId: stationId, completedStations: completedStationIds)
    }
}
