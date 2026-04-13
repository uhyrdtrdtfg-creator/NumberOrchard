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

    /// Next station the child should learn. Priority: first unlocked station with 0 stars;
    /// else first unlocked with <3 stars; else last unlocked station (all 3-starred — hover on frontier);
    /// else the first station in the catalog.
    var recommendedStationId: String {
        let stations = MapCatalog.stations
        if let cta = stations.first(where: { isUnlocked($0.id) && stars(for: $0.id) == 0 }) {
            return cta.id
        }
        if let incomplete = stations.first(where: { isUnlocked($0.id) && stars(for: $0.id) < 3 }) {
            return incomplete.id
        }
        if let lastUnlocked = stations.last(where: { isUnlocked($0.id) }) {
            return lastUnlocked.id
        }
        return stations.first?.id ?? ""
    }
}
