import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AdventureSessionViewModel {
    private let questionGenerator = QuestionGenerator()
    private let difficultyManager = DifficultyManager()
    private let treeCalculator = TreeGrowthCalculator()
    private let rewardCalculator = RewardCalculator()
    private let mapLogic = MapProgressionLogic()

    var currentQuestion: MathQuestion?
    var questionsCompleted: Int = 0
    var totalQuestions: Int = 5
    var consecutiveCorrect: Int = 0
    var isSessionComplete: Bool = false
    var experienceGained: Int = 0
    var lastReward: StationReward?
    var newlyUnlockedFruit: FruitItem?

    private var learningProfile: LearningProfile
    private var session: LearningSession
    private var profile: ChildProfile
    private var recentQuestions: [MathQuestion] = []
    let station: Station?
    private var hintUsedThisSession: Bool = false
    private var modelContext: ModelContext

    init(profile: ChildProfile, station: Station?, modelContext: ModelContext) {
        self.profile = profile
        self.station = station
        self.modelContext = modelContext
        let effectiveLevel = station?.level ?? profile.difficultyLevel
        var lp = LearningProfile(from: profile)
        lp.currentLevel = effectiveLevel
        self.learningProfile = lp
        self.session = LearningSession(level: effectiveLevel)
        modelContext.insert(session)
        profile.sessions.append(session)
        generateNextQuestion()
    }

    func generateNextQuestion() {
        guard questionsCompleted < totalQuestions else {
            finalizeSession()
            return
        }
        let gameMode = chooseGameMode()
        let next = questionGenerator.generate(for: learningProfile, gameMode: gameMode, recentQuestions: recentQuestions)
        currentQuestion = next
        recentQuestions.append(next)
        if recentQuestions.count > 5 {
            recentQuestions.removeFirst(recentQuestions.count - 5)
        }
    }

    private func chooseGameMode() -> GameMode {
        let level = learningProfile.currentLevel
        let isAdditionOnly = !level.allowsSubtraction

        if isAdditionOnly {
            switch questionsCompleted {
            case 0, 2, 4: return .pickFruit
            case 1: return .numberTrain
            case 3: return level.maxNumber >= 10 ? .balance : .numberTrain
            default: return .pickFruit
            }
        } else {
            switch questionsCompleted {
            case 0: return .pickFruit
            case 1: return .shareFruit
            case 2: return .numberTrain
            case 3: return .balance
            case 4: return Bool.random() ? .pickFruit : .shareFruit
            default: return .pickFruit
            }
        }
    }

    func handleAnswer(correct: Bool, responseTime: TimeInterval, usedHint: Bool) {
        guard let question = currentQuestion else { return }
        if usedHint { hintUsedThisSession = true }

        let record = QuestionRecord(
            question: question,
            userAnswer: correct ? question.correctAnswer : -1,
            responseTime: responseTime,
            usedHint: usedHint
        )
        session.records.append(record)

        learningProfile = difficultyManager.updateAfterAnswer(
            profile: learningProfile,
            isCorrect: correct,
            usedHint: usedHint
        )

        if correct {
            consecutiveCorrect += 1
            let exp = treeCalculator.experienceForCorrectAnswer(combo: consecutiveCorrect)
            experienceGained += exp
            profile.treeExperience += exp
            profile.treeStage = TreeGrowthCalculator.stageFor(experience: profile.treeExperience)
            profile.totalCorrect += 1
            playCorrectVoice()
        } else {
            consecutiveCorrect = 0
            AudioManager.shared.playSound("wrong.wav")
        }

        profile.totalQuestions += 1
        questionsCompleted += 1

        if difficultyManager.shouldPromoteLevel(profile: learningProfile) {
            learningProfile = difficultyManager.promote(profile: learningProfile)
            profile.difficultyLevel = learningProfile.currentLevel
            profile.subDifficulty = learningProfile.subDifficulty
            AudioManager.shared.playSound("level_up.wav")
        } else {
            profile.subDifficulty = learningProfile.subDifficulty
        }

        generateNextQuestion()
    }

    private func finalizeSession() {
        session.durationSeconds = Date().timeIntervalSince(session.date)
        isSessionComplete = true
        if let station {
            applyStationRewards(station: station)
        }
    }

    private func applyStationRewards(station: Station) {
        guard !session.records.isEmpty else { return }
        let accuracy = Double(session.correctCount) / Double(session.records.count)
        let newStars = mapLogic.starsFor(accuracy: accuracy, usedHint: hintUsedThisSession)

        let existingProgress = profile.stationProgress.first { $0.stationId == station.id }
        let isFirstCompletion = existingProgress == nil || (existingProgress?.stars ?? 0) == 0

        let progress: StationProgress
        if let existing = existingProgress {
            progress = existing
            progress.stars = mapLogic.updateStars(current: existing.stars, new: newStars)
            progress.attemptsCount += 1
            progress.bestAccuracy = max(existing.bestAccuracy, accuracy)
        } else {
            progress = StationProgress(stationId: station.id, unlocked: true)
            progress.stars = newStars
            progress.bestAccuracy = accuracy
            progress.attemptsCount = 1
            profile.stationProgress.append(progress)
            modelContext.insert(progress)
        }

        let reward = rewardCalculator.calculate(stars: newStars, isFirstCompletion: isFirstCompletion, station: station)
        profile.stars += reward.starsEarned
        profile.seeds += reward.seedsEarned

        if let fruitId = reward.fruitIdEarned {
            let alreadyCollected = profile.collectedFruits.contains { $0.fruitId == fruitId }
            if !alreadyCollected {
                let fruit = CollectedFruit(fruitId: fruitId, unlockedFromStationId: station.id)
                profile.collectedFruits.append(fruit)
                modelContext.insert(fruit)
                newlyUnlockedFruit = FruitCatalog.fruit(id: fruitId)
            }
        }

        let completedIds = Set(profile.stationProgress.filter { $0.stars > 0 }.map(\.stationId))
        for otherStation in MapCatalog.stations {
            if mapLogic.isUnlocked(stationId: otherStation.id, completedStations: completedIds) {
                if !profile.stationProgress.contains(where: { $0.stationId == otherStation.id }) {
                    let sp = StationProgress(stationId: otherStation.id, unlocked: true)
                    profile.stationProgress.append(sp)
                    modelContext.insert(sp)
                }
            }
        }

        lastReward = reward
    }

    func finishSession() {
        if !isSessionComplete { finalizeSession() }
    }

    private func playCorrectVoice() {
        switch consecutiveCorrect {
        case 3: AudioManager.shared.playVoice("combo_03.aiff")
        case 5: AudioManager.shared.playVoice("combo_05.aiff")
        case 7: AudioManager.shared.playVoice("combo_07.aiff")
        default:
            let index = Int.random(in: 1...5)
            AudioManager.shared.playVoice("correct_0\(index).aiff")
        }
    }
}
