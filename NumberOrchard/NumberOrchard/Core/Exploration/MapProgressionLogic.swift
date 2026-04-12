import Foundation

struct MapProgressionLogic: Sendable {

    /// Returns whether a station is currently accessible given what's been completed.
    func isUnlocked(stationId: String, completedStations: Set<String>) -> Bool {
        if stationId == MapCatalog.initialStationId { return true }

        if stationId == MapCatalog.endStationId {
            return MapCatalog.stations.contains { s in
                s.level == .harvest && completedStations.contains(s.id)
            }
        }

        return MapCatalog.stations.contains { s in
            completedStations.contains(s.id) && s.unlocks.contains(stationId)
        }
    }

    /// Compute star rating from accuracy and hint usage. Any completion gives at least 1 star.
    func starsFor(accuracy: Double, usedHint: Bool) -> Int {
        if accuracy >= 1.0 && !usedHint { return 3 }
        if accuracy >= 0.8 { return 2 }
        return 1
    }

    /// Only increase star rating — never decrease.
    func updateStars(current: Int, new: Int) -> Int {
        max(current, new)
    }
}
