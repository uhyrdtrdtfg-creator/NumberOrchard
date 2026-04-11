import Foundation
import Observation

enum EyeCareAlertLevel: Sendable {
    case none
    case soft     // 80% of time limit reached
    case gentle   // time limit reached
    case locked   // 5 minutes past limit
}

@Observable
@MainActor
final class EyeCareManager {
    let timeLimitMinutes: Int
    private(set) var sessionStartTime: Date?
    private(set) var hasUsedExtension = false

    init(timeLimitMinutes: Int = 20) {
        self.timeLimitMinutes = timeLimitMinutes
    }

    func startSession() {
        sessionStartTime = Date()
    }

    var elapsedMinutes: Double {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start) / 60.0
    }

    func alertLevel(afterMinutes minutes: Double) -> EyeCareAlertLevel {
        let limit = Double(timeLimitMinutes)
        if minutes >= limit + 5 {
            return .locked
        } else if minutes >= limit {
            return .gentle
        } else if minutes >= limit * 0.8 {
            return .soft
        }
        return .none
    }

    var currentAlertLevel: EyeCareAlertLevel {
        alertLevel(afterMinutes: elapsedMinutes)
    }

    func useExtension() {
        guard !hasUsedExtension else { return }
        hasUsedExtension = true
    }
}
