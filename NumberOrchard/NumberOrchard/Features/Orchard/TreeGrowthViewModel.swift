import SwiftUI

@Observable
@MainActor
final class TreeGrowthViewModel {
    let profile: ChildProfile

    init(profile: ChildProfile) {
        self.profile = profile
    }

    var currentStage: Int { profile.treeStage }

    var stageName: String {
        let names = ["种子", "发芽", "小苗", "小树", "大树", "开花", "结果"]
        guard currentStage < names.count else { return "结果" }
        return names[currentStage]
    }

    var stageEmoji: String {
        let emojis = ["🌱", "🌿", "🪴", "🌳", "🌲", "🌸", "🍎"]
        guard currentStage < emojis.count else { return "🍎" }
        return emojis[currentStage]
    }

    var progress: Double {
        TreeGrowthCalculator.progressInCurrentStage(experience: profile.treeExperience)
    }

    var experienceText: String {
        let thresholds = TreeGrowthCalculator.stageThresholds
        guard currentStage < thresholds.count - 1 else { return "已满级" }
        let current = profile.treeExperience - thresholds[currentStage]
        let needed = thresholds[currentStage + 1] - thresholds[currentStage]
        return "\(current) / \(needed)"
    }
}
