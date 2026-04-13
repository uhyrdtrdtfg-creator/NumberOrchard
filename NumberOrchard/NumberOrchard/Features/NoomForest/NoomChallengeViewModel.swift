import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class NoomChallengeViewModel {
    let totalQuestions = 5
    var questionsCompleted: Int = 0
    var currentChallenge: NoomChallengeType?
    var isSessionComplete: Bool = false

    var newlyUnlockedNooms: [Noom] = []
    var starsEarned: Int = 0
    var seedsEarned: Int = 0

    private var session: [NoomChallengeType] = []
    private let profile: ChildProfile
    private let modelContext: ModelContext

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        let alreadyUnlocked = Set(profile.collectedNooms.map(\.noomNumber))
        self.session = NoomQuestionGenerator().generateSession(alreadyUnlocked: alreadyUnlocked)
        currentChallenge = session.first
    }

    func handleCompletion(unlockedNumbers: [Int]) {
        for n in unlockedNumbers where (1...10).contains(n) {
            if let existing = profile.collectedNooms.first(where: { $0.noomNumber == n }) {
                existing.encounterCount += 1
            } else {
                let cn = CollectedNoom(noomNumber: n)
                profile.collectedNooms.append(cn)
                modelContext.insert(cn)
                if let noom = NoomCatalog.noom(for: n) {
                    newlyUnlockedNooms.append(noom)
                }
                starsEarned += 1
            }
        }

        questionsCompleted += 1
        if questionsCompleted >= totalQuestions {
            starsEarned += 5
            seedsEarned += 1
            profile.stars += starsEarned
            profile.seeds += seedsEarned
            isSessionComplete = true
            currentChallenge = nil
        } else {
            currentChallenge = session[questionsCompleted]
        }
    }
}
