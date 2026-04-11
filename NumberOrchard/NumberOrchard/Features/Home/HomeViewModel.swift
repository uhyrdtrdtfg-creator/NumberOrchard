import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var showCheckIn = false
    var showParentalGate = false
    var profile: ChildProfile?

    func checkDailyLogin(profile: ChildProfile) {
        self.profile = profile
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastLogin = profile.lastLoginDate {
            let lastDay = calendar.startOfDay(for: lastLogin)
            if lastDay == today {
                showCheckIn = false
            } else if calendar.date(byAdding: .day, value: 1, to: lastDay) == today {
                profile.consecutiveLoginDays += 1
                profile.lastLoginDate = Date()
                profile.seeds += 1
                showCheckIn = true
            } else {
                profile.consecutiveLoginDays = 1
                profile.lastLoginDate = Date()
                profile.seeds += 1
                showCheckIn = true
            }
        } else {
            profile.consecutiveLoginDays = 1
            profile.lastLoginDate = Date()
            profile.seeds += 1
            showCheckIn = true
        }
    }

    var treeStageEmoji: String {
        guard let profile else { return "🌱" }
        switch profile.treeStage {
        case 0: return "🌱"
        case 1: return "🌿"
        case 2: return "🪴"
        case 3: return "🌳"
        case 4: return "🌲"
        case 5: return "🌸"
        case 6: return "🍎"
        default: return "🌱"
        }
    }

    var treeProgress: Double {
        guard let profile else { return 0 }
        return TreeGrowthCalculator.progressInCurrentStage(experience: profile.treeExperience)
    }
}
