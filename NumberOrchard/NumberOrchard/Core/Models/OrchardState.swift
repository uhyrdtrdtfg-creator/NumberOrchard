import Foundation

struct TreeGrowthCalculator: Sendable {
    static let stageThresholds = [0, 100, 300, 600, 1000, 1500, 2000]

    static func stageFor(experience: Int) -> Int {
        for i in stride(from: Self.stageThresholds.count - 1, through: 0, by: -1) {
            if experience >= Self.stageThresholds[i] {
                return i
            }
        }
        return 0
    }

    static func progressInCurrentStage(experience: Int) -> Double {
        let stage = stageFor(experience: experience)
        guard stage < stageThresholds.count - 1 else { return 1.0 }
        let current = stageThresholds[stage]
        let next = stageThresholds[stage + 1]
        return Double(experience - current) / Double(next - current)
    }

    func experienceForCorrectAnswer(combo: Int) -> Int {
        let base = 10
        let bonus = combo >= 3 ? 5 : 0
        return base + bonus
    }
}
