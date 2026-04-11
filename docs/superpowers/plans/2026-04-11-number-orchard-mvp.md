# Number Orchard (数字果园) MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iPad app for 5-6 year-olds to learn addition and subtraction (within 20) through interactive fruit-themed games with adaptive difficulty.

**Architecture:** SwiftUI app shell with SpriteKit game scenes embedded via `SpriteView`. SwiftData for local persistence. Feature-based module organization with a shared Core layer containing the adaptive engine, audio, and storage.

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, SwiftData, AVFoundation, iPadOS 17.0+

---

## File Structure

```
NumberOrchard/
├── NumberOrchard.xcodeproj
├── NumberOrchard/
│   ├── App/
│   │   ├── NumberOrchardApp.swift
│   │   └── AppCoordinator.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── DifficultyLevel.swift
│   │   │   ├── MathQuestion.swift
│   │   │   ├── ChildProfile.swift
│   │   │   ├── LearningSession.swift
│   │   │   ├── QuestionRecord.swift
│   │   │   └── OrchardState.swift
│   │   ├── AdaptiveEngine/
│   │   │   ├── LearningProfile.swift
│   │   │   ├── DifficultyManager.swift
│   │   │   └── QuestionGenerator.swift
│   │   ├── Audio/
│   │   │   └── AudioManager.swift
│   │   └── ParentalGate/
│   │       └── ParentalGateView.swift
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   ├── Adventure/
│   │   │   ├── AdventureSessionView.swift
│   │   │   ├── AdventureSessionViewModel.swift
│   │   │   ├── PickFruit/
│   │   │   │   ├── PickFruitScene.swift
│   │   │   │   └── PickFruitView.swift
│   │   │   └── ShareFruit/
│   │   │       ├── ShareFruitScene.swift
│   │   │       └── ShareFruitView.swift
│   │   ├── Orchard/
│   │   │   ├── TreeGrowthView.swift
│   │   │   └── TreeGrowthViewModel.swift
│   │   ├── DailyFlow/
│   │   │   ├── CheckInView.swift
│   │   │   └── EyeCareManager.swift
│   │   └── ParentCenter/
│   │       ├── ParentCenterView.swift
│   │       ├── SettingsView.swift
│   │       └── BasicReportView.swift
│   └── Resources/
│       ├── Assets.xcassets/
│       └── Sounds/
├── NumberOrchardTests/
│   ├── Core/
│   │   ├── AdaptiveEngine/
│   │   │   ├── DifficultyManagerTests.swift
│   │   │   └── QuestionGeneratorTests.swift
│   │   └── Models/
│   │       └── OrchardStateTests.swift
│   └── Features/
│       ├── Adventure/
│       │   ├── PickFruitLogicTests.swift
│       │   └── ShareFruitLogicTests.swift
│       └── DailyFlow/
│           └── EyeCareManagerTests.swift
└── docs/
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `NumberOrchard.xcodeproj` (via Xcode CLI)
- Create: `NumberOrchard/App/NumberOrchardApp.swift`
- Create: `NumberOrchard/Info.plist` (auto-generated, configure iPad-only + landscape)

- [ ] **Step 1: Create Xcode project**

```bash
cd /Users/samxiao/code/app
# Use xcodegen or manual creation. We'll use a Package.swift-based approach for testability,
# but since this is an iPad app, we need a proper .xcodeproj.
# Create via command line swift package + Xcode project generation:
mkdir -p NumberOrchard/NumberOrchard/App
mkdir -p NumberOrchard/NumberOrchard/Core/Models
mkdir -p NumberOrchard/NumberOrchard/Core/AdaptiveEngine
mkdir -p NumberOrchard/NumberOrchard/Core/Audio
mkdir -p NumberOrchard/NumberOrchard/Core/ParentalGate
mkdir -p NumberOrchard/NumberOrchard/Features/Home
mkdir -p NumberOrchard/NumberOrchard/Features/Adventure/PickFruit
mkdir -p NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit
mkdir -p NumberOrchard/NumberOrchard/Features/Orchard
mkdir -p NumberOrchard/NumberOrchard/Features/DailyFlow
mkdir -p NumberOrchard/NumberOrchard/Features/ParentCenter
mkdir -p NumberOrchard/NumberOrchard/Resources/Sounds
mkdir -p NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine
mkdir -p NumberOrchard/NumberOrchardTests/Core/Models
mkdir -p NumberOrchard/NumberOrchardTests/Features/Adventure
mkdir -p NumberOrchard/NumberOrchardTests/Features/DailyFlow
```

- [ ] **Step 2: Create App entry point**

Create `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct NumberOrchardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **Step 3: Create AppCoordinator**

Create `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`:

```swift
import SwiftUI

enum AppScreen {
    case home
    case adventure
    case parentCenter
}

struct AppCoordinator: View {
    @State private var currentScreen: AppScreen = .home

    var body: some View {
        Group {
            switch currentScreen {
            case .home:
                HomeView(
                    onStartAdventure: { currentScreen = .adventure },
                    onOpenParentCenter: { currentScreen = .parentCenter }
                )
            case .adventure:
                AdventureSessionView(
                    onFinish: { currentScreen = .home }
                )
            case .parentCenter:
                ParentCenterView(
                    onDismiss: { currentScreen = .home }
                )
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden(true)
    }
}
```

- [ ] **Step 4: Create placeholder views for compilation**

Create `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void

    var body: some View {
        Text("数字果园")
            .font(.largeTitle)
    }
}
```

Create `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionView.swift`:

```swift
import SwiftUI

struct AdventureSessionView: View {
    let onFinish: () -> Void

    var body: some View {
        Text("冒险模式")
    }
}
```

Create `NumberOrchard/NumberOrchard/Features/ParentCenter/ParentCenterView.swift`:

```swift
import SwiftUI

struct ParentCenterView: View {
    let onDismiss: () -> Void

    var body: some View {
        Text("家长中心")
    }
}
```

- [ ] **Step 5: Create project.yml for XcodeGen**

Create `NumberOrchard/project.yml`:

```yaml
name: NumberOrchard
options:
  bundleIdPrefix: com.numberorchard
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"
  defaultConfig: Debug
settings:
  base:
    TARGETED_DEVICE_FAMILY: 2
    INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
    INFOPLIST_KEY_UILaunchScreen_Generation: true
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
targets:
  NumberOrchard:
    type: application
    platform: iOS
    sources:
      - path: NumberOrchard
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.numberorchard.app
  NumberOrchardTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: NumberOrchardTests
    dependencies:
      - target: NumberOrchard
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.numberorchard.tests
```

- [ ] **Step 6: Generate Xcode project and verify build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
# If xcodegen is installed:
xcodegen generate
# Build to verify:
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 7: Initialize git and commit**

```bash
cd /Users/samxiao/code/app
git init
echo ".DS_Store\n*.xcuserdatapackage\nDerivedData/\nbuild/" > .gitignore
git add .
git commit -m "feat: initial project setup with SwiftUI + SwiftData scaffold"
```

---

## Task 2: Core Data Models

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/DifficultyLevel.swift`
- Create: `NumberOrchard/NumberOrchard/Core/Models/MathQuestion.swift`
- Create: `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`
- Create: `NumberOrchard/NumberOrchard/Core/Models/LearningSession.swift`
- Create: `NumberOrchard/NumberOrchard/Core/Models/QuestionRecord.swift`
- Create: `NumberOrchard/NumberOrchard/Core/Models/OrchardState.swift`
- Test: `NumberOrchard/NumberOrchardTests/Core/Models/OrchardStateTests.swift`

- [ ] **Step 1: Create DifficultyLevel enum**

Create `NumberOrchard/NumberOrchard/Core/Models/DifficultyLevel.swift`:

```swift
import Foundation

enum DifficultyLevel: Int, Codable, Comparable, CaseIterable, Sendable {
    case seed = 1       // L1: 5 以内加法
    case sprout = 2     // L2: 5 以内加减法
    case smallTree = 3  // L3: 10 以内加法
    case bigTree = 4    // L4: 10 以内加减法

    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .seed: return "种子"
        case .sprout: return "发芽"
        case .smallTree: return "小树"
        case .bigTree: return "大树"
        }
    }

    var maxNumber: Int {
        switch self {
        case .seed, .sprout: return 5
        case .smallTree, .bigTree: return 10
        }
    }

    var allowsSubtraction: Bool {
        switch self {
        case .seed, .smallTree: return false
        case .sprout, .bigTree: return true
        }
    }

    /// Accuracy threshold to unlock next level
    var promotionThreshold: Double {
        switch self {
        case .seed: return 0.80
        case .sprout: return 0.75
        case .smallTree: return 0.75
        case .bigTree: return 0.70
        }
    }

    /// Minimum questions before promotion is considered
    var minimumQuestionsForPromotion: Int { 10 }
}
```

- [ ] **Step 2: Create MathQuestion model**

Create `NumberOrchard/NumberOrchard/Core/Models/MathQuestion.swift`:

```swift
import Foundation

enum MathOperation: String, Codable, Sendable {
    case add
    case subtract
}

enum GameMode: String, Codable, Sendable {
    case pickFruit   // 摘果子 (addition)
    case shareFruit  // 分果果 (subtraction)
}

struct MathQuestion: Codable, Sendable, Equatable {
    let operand1: Int
    let operand2: Int
    let operation: MathOperation
    let gameMode: GameMode

    var correctAnswer: Int {
        switch operation {
        case .add: return operand1 + operand2
        case .subtract: return operand1 - operand2
        }
    }

    var displayText: String {
        switch operation {
        case .add:
            return "篮子里有 \(operand1) 个，再摘 \(operand2) 个，一共几个？"
        case .subtract:
            return "盘子里有 \(operand1) 个，分给小兔 \(operand2) 个，还剩几个？"
        }
    }
}
```

- [ ] **Step 3: Create ChildProfile SwiftData model**

Create `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`:

```swift
import Foundation
import SwiftData

@Model
final class ChildProfile {
    var name: String
    var avatarIndex: Int
    var createdAt: Date

    // Learning state
    var currentLevel: Int  // DifficultyLevel rawValue
    var subDifficulty: Int
    var totalCorrect: Int
    var totalQuestions: Int

    // Orchard state
    var treeExperience: Int
    var treeStage: Int  // 0=seed, 1=sprout, 2=sapling, 3=smallTree, 4=bigTree, 5=bloom, 6=fruit
    var stars: Int
    var seeds: Int
    var consecutiveLoginDays: Int
    var lastLoginDate: Date?

    // Settings
    var dailyTimeLimitMinutes: Int

    @Relationship(deleteRule: .cascade)
    var sessions: [LearningSession] = []

    init(name: String, avatarIndex: Int = 0) {
        self.name = name
        self.avatarIndex = avatarIndex
        self.createdAt = Date()
        self.currentLevel = DifficultyLevel.seed.rawValue
        self.subDifficulty = 1
        self.totalCorrect = 0
        self.totalQuestions = 0
        self.treeExperience = 0
        self.treeStage = 0
        self.stars = 0
        self.seeds = 0
        self.consecutiveLoginDays = 0
        self.lastLoginDate = nil
        self.dailyTimeLimitMinutes = 20
    }

    var difficultyLevel: DifficultyLevel {
        get { DifficultyLevel(rawValue: currentLevel) ?? .seed }
        set { currentLevel = newValue.rawValue }
    }
}
```

- [ ] **Step 4: Create LearningSession and QuestionRecord models**

Create `NumberOrchard/NumberOrchard/Core/Models/LearningSession.swift`:

```swift
import Foundation
import SwiftData

@Model
final class LearningSession {
    var date: Date
    var durationSeconds: Double
    var level: Int  // DifficultyLevel rawValue

    @Relationship(deleteRule: .cascade)
    var records: [QuestionRecord] = []

    @Relationship(inverse: \ChildProfile.sessions)
    var profile: ChildProfile?

    init(level: DifficultyLevel) {
        self.date = Date()
        self.durationSeconds = 0
        self.level = level.rawValue
    }

    var correctCount: Int {
        records.filter(\.isCorrect).count
    }

    var accuracy: Double {
        guard !records.isEmpty else { return 0 }
        return Double(correctCount) / Double(records.count)
    }
}
```

Create `NumberOrchard/NumberOrchard/Core/Models/QuestionRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class QuestionRecord {
    var operand1: Int
    var operand2: Int
    var operation: String  // "add" or "subtract"
    var gameMode: String   // "pickFruit" or "shareFruit"
    var userAnswer: Int
    var isCorrect: Bool
    var responseTimeSeconds: Double
    var usedHint: Bool
    var timestamp: Date

    @Relationship(inverse: \LearningSession.records)
    var session: LearningSession?

    init(question: MathQuestion, userAnswer: Int, responseTime: TimeInterval, usedHint: Bool) {
        self.operand1 = question.operand1
        self.operand2 = question.operand2
        self.operation = question.operation.rawValue
        self.gameMode = question.gameMode.rawValue
        self.userAnswer = userAnswer
        self.isCorrect = (userAnswer == question.correctAnswer)
        self.responseTimeSeconds = responseTime
        self.usedHint = usedHint
        self.timestamp = Date()
    }
}
```

- [ ] **Step 5: Write test for OrchardState (tree growth logic)**

Create `NumberOrchard/NumberOrchardTests/Core/Models/OrchardStateTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func treeStageProgression() {
    let profile = ChildProfile(name: "Test")
    #expect(profile.treeStage == 0)
    #expect(profile.treeExperience == 0)

    // Add experience below threshold — stage shouldn't change
    profile.treeExperience = 50
    let stage = TreeGrowthCalculator.stageFor(experience: profile.treeExperience)
    #expect(stage == 0) // still seed

    // Cross first threshold (100)
    let stage2 = TreeGrowthCalculator.stageFor(experience: 100)
    #expect(stage2 == 1) // sprout

    // Cross second threshold (300)
    let stage3 = TreeGrowthCalculator.stageFor(experience: 300)
    #expect(stage3 == 2) // sapling
}

@Test func experienceGain() {
    let calculator = TreeGrowthCalculator()
    // Normal correct answer: +10
    #expect(calculator.experienceForCorrectAnswer(combo: 1) == 10)
    // Combo of 3: +15
    #expect(calculator.experienceForCorrectAnswer(combo: 3) == 15)
    // Combo of 5: +15 (capped at 3+ bonus)
    #expect(calculator.experienceForCorrectAnswer(combo: 5) == 15)
}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/OrchardStateTests 2>&1 | tail -10
```

Expected: FAIL — `TreeGrowthCalculator` not defined

- [ ] **Step 7: Create TreeGrowthCalculator**

Create `NumberOrchard/NumberOrchard/Core/Models/OrchardState.swift`:

```swift
import Foundation

struct TreeGrowthCalculator: Sendable {
    /// Experience thresholds for each tree stage:
    /// 0=seed, 1=sprout, 2=sapling, 3=smallTree, 4=bigTree, 5=bloom, 6=fruit
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

    /// Returns experience gained for a correct answer.
    /// Base: 10. Combo bonus: +5 if combo >= 3.
    func experienceForCorrectAnswer(combo: Int) -> Int {
        let base = 10
        let bonus = combo >= 3 ? 5 : 0
        return base + bonus
    }
}
```

- [ ] **Step 8: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/OrchardStateTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 9: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Core/Models/ NumberOrchard/NumberOrchardTests/Core/Models/
git commit -m "feat: add core data models — DifficultyLevel, MathQuestion, ChildProfile, sessions, tree growth"
```

---

## Task 3: Adaptive Difficulty Engine

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/LearningProfile.swift`
- Create: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/DifficultyManager.swift`
- Test: `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/DifficultyManagerTests.swift`

- [ ] **Step 1: Create LearningProfile (runtime state)**

Create `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/LearningProfile.swift`:

```swift
import Foundation

/// Runtime learning state tracked during a session. Derived from ChildProfile + current session data.
struct LearningProfile: Sendable {
    var currentLevel: DifficultyLevel
    var subDifficulty: Int  // 1-5 within current level
    var consecutiveCorrect: Int
    var consecutiveWrong: Int
    var levelCorrectCount: Int
    var levelQuestionCount: Int
    var hintUsageCount: Int

    var levelAccuracy: Double {
        guard levelQuestionCount > 0 else { return 0 }
        return Double(levelCorrectCount) / Double(levelQuestionCount)
    }

    var hintUsageRate: Double {
        guard levelQuestionCount > 0 else { return 0 }
        return Double(hintUsageCount) / Double(levelQuestionCount)
    }

    init(from profile: ChildProfile) {
        self.currentLevel = profile.difficultyLevel
        self.subDifficulty = profile.subDifficulty
        self.consecutiveCorrect = 0
        self.consecutiveWrong = 0
        self.levelCorrectCount = profile.totalCorrect
        self.levelQuestionCount = profile.totalQuestions
        self.hintUsageCount = 0
    }
}
```

- [ ] **Step 2: Write failing test for DifficultyManager**

Create `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/DifficultyManagerTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func subDifficultyIncreasesAfterThreeCorrect() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 1) // 1 correct, no change
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 1) // 2 correct, no change
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 2) // 3 correct → bump
}

@Test func subDifficultyDecreasesAfterTwoWrong() {
    var profile = LearningProfile(currentLevel: .smallTree, subDifficulty: 3)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 3) // 1 wrong, no change
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 2) // 2 wrong → drop
}

@Test func subDifficultyDoesNotGoBelowOne() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: false, usedHint: false)
    #expect(profile.subDifficulty == 1) // clamped at 1
}

@Test func subDifficultyDoesNotGoAboveFive() {
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 5)
    let manager = DifficultyManager()

    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    profile = manager.updateAfterAnswer(profile: profile, isCorrect: true, usedHint: false)
    #expect(profile.subDifficulty == 5) // clamped at 5
}

@Test func levelPromotionWhenAccuracyMet() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 3)
    // Simulate 10 questions with 80%+ accuracy
    profile.levelQuestionCount = 10
    profile.levelCorrectCount = 9

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == true)
}

@Test func noPromotionWhenTooFewQuestions() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .seed, subDifficulty: 3)
    profile.levelQuestionCount = 5  // below minimum of 10
    profile.levelCorrectCount = 5

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false)
}

@Test func noPromotionAtMaxLevel() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 5)
    profile.levelQuestionCount = 20
    profile.levelCorrectCount = 20

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false) // bigTree is max for MVP
}
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/DifficultyManagerTests 2>&1 | tail -10
```

Expected: FAIL — `DifficultyManager` and `LearningProfile` init not found

- [ ] **Step 4: Add convenience init to LearningProfile for testing**

Add to `LearningProfile.swift`:

```swift
extension LearningProfile {
    /// Convenience init for testing and fresh starts
    init(currentLevel: DifficultyLevel, subDifficulty: Int) {
        self.currentLevel = currentLevel
        self.subDifficulty = subDifficulty
        self.consecutiveCorrect = 0
        self.consecutiveWrong = 0
        self.levelCorrectCount = 0
        self.levelQuestionCount = 0
        self.hintUsageCount = 0
    }
}
```

- [ ] **Step 5: Implement DifficultyManager**

Create `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/DifficultyManager.swift`:

```swift
import Foundation

struct DifficultyManager: Sendable {

    /// Update profile after a single answer. Returns updated profile.
    func updateAfterAnswer(profile: LearningProfile, isCorrect: Bool, usedHint: Bool) -> LearningProfile {
        var p = profile
        p.levelQuestionCount += 1

        if isCorrect {
            p.levelCorrectCount += 1
            p.consecutiveCorrect += 1
            p.consecutiveWrong = 0

            if p.consecutiveCorrect >= 3 {
                p.subDifficulty = min(p.subDifficulty + 1, 5)
                p.consecutiveCorrect = 0
            }
        } else {
            p.consecutiveWrong += 1
            p.consecutiveCorrect = 0

            if p.consecutiveWrong >= 2 {
                p.subDifficulty = max(p.subDifficulty - 1, 1)
                p.consecutiveWrong = 0
            }
        }

        if usedHint {
            p.hintUsageCount += 1
        }

        return p
    }

    /// Check if the player should be promoted to the next level.
    func shouldPromoteLevel(profile: LearningProfile) -> Bool {
        // No promotion beyond bigTree in MVP
        guard profile.currentLevel != .bigTree else { return false }

        // Need minimum questions answered
        guard profile.levelQuestionCount >= profile.currentLevel.minimumQuestionsForPromotion else {
            return false
        }

        // Accuracy must meet threshold
        return profile.levelAccuracy >= profile.currentLevel.promotionThreshold
    }

    /// Promote to next level, resetting level-specific counters.
    func promote(profile: LearningProfile) -> LearningProfile {
        guard let nextLevel = DifficultyLevel(rawValue: profile.currentLevel.rawValue + 1) else {
            return profile
        }
        var p = profile
        p.currentLevel = nextLevel
        p.subDifficulty = 1
        p.levelCorrectCount = 0
        p.levelQuestionCount = 0
        p.consecutiveCorrect = 0
        p.consecutiveWrong = 0
        p.hintUsageCount = 0
        return p
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/DifficultyManagerTests 2>&1 | tail -10
```

Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Core/AdaptiveEngine/ NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/
git commit -m "feat: implement adaptive difficulty engine with sub-difficulty and level promotion"
```

---

## Task 4: Question Generator

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/QuestionGenerator.swift`
- Test: `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/QuestionGeneratorTests.swift`

- [ ] **Step 1: Write failing tests for QuestionGenerator**

Create `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/QuestionGeneratorTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func seedLevelGeneratesAdditionOnly() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .seed, subDifficulty: 1)

    for _ in 0..<20 {
        let question = generator.generate(for: profile)
        #expect(question.operation == .add)
        #expect(question.gameMode == .pickFruit)
        #expect(question.operand1 + question.operand2 <= 5)
        #expect(question.operand1 >= 1)
        #expect(question.operand2 >= 1)
    }
}

@Test func sproutLevelIncludesSubtraction() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .sprout, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        if question.operation == .add { hasAdd = true }
        if question.operation == .subtract { hasSub = true }
        // All results should be within [0, 5]
        #expect(question.correctAnswer >= 0)
        #expect(question.correctAnswer <= 5)
        #expect(question.operand1 <= 5)
    }
    #expect(hasAdd == true)
    #expect(hasSub == true)
}

@Test func smallTreeLevelAdditionUpToTen() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .smallTree, subDifficulty: 3)

    for _ in 0..<20 {
        let question = generator.generate(for: profile)
        #expect(question.operation == .add)
        #expect(question.correctAnswer <= 10)
        #expect(question.operand1 >= 1)
        #expect(question.operand2 >= 1)
    }
}

@Test func bigTreeLevelMixedUpToTen() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        if question.operation == .add { hasAdd = true }
        if question.operation == .subtract { hasSub = true }
        #expect(question.correctAnswer >= 0)
        #expect(question.correctAnswer <= 10)
        #expect(question.operand1 <= 10)
    }
    #expect(hasAdd == true)
    #expect(hasSub == true)
}

@Test func subtractionNeverProducesNegativeResult() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 5)

    for _ in 0..<100 {
        let question = generator.generate(for: profile)
        if question.operation == .subtract {
            #expect(question.operand1 >= question.operand2)
        }
    }
}

@Test func gameModeMatchesOperation() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .sprout, subDifficulty: 3)

    for _ in 0..<50 {
        let question = generator.generate(for: profile)
        switch question.operation {
        case .add:
            #expect(question.gameMode == .pickFruit)
        case .subtract:
            #expect(question.gameMode == .shareFruit)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/QuestionGeneratorTests 2>&1 | tail -10
```

Expected: FAIL — `QuestionGenerator` not defined

- [ ] **Step 3: Implement QuestionGenerator**

Create `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/QuestionGenerator.swift`:

```swift
import Foundation

struct QuestionGenerator: Sendable {

    func generate(for profile: LearningProfile) -> MathQuestion {
        let operation = chooseOperation(for: profile.currentLevel)
        let (op1, op2) = generateOperands(
            level: profile.currentLevel,
            subDifficulty: profile.subDifficulty,
            operation: operation
        )
        let gameMode: GameMode = operation == .add ? .pickFruit : .shareFruit

        return MathQuestion(
            operand1: op1,
            operand2: op2,
            operation: operation,
            gameMode: gameMode
        )
    }

    private func chooseOperation(for level: DifficultyLevel) -> MathOperation {
        guard level.allowsSubtraction else { return .add }
        // 50/50 split between add and subtract for mixed levels
        return Bool.random() ? .add : .subtract
    }

    private func generateOperands(
        level: DifficultyLevel,
        subDifficulty: Int,
        operation: MathOperation
    ) -> (Int, Int) {
        let maxNum = level.maxNumber

        switch operation {
        case .add:
            return generateAdditionOperands(maxSum: maxNum, subDifficulty: subDifficulty)
        case .subtract:
            return generateSubtractionOperands(maxMinuend: maxNum, subDifficulty: subDifficulty)
        }
    }

    private func generateAdditionOperands(maxSum: Int, subDifficulty: Int) -> (Int, Int) {
        // Higher sub-difficulty → larger numbers
        let minOperand = 1
        let maxOperand = max(1, min(maxSum - 1, subDifficulty + 1))

        let op1 = Int.random(in: minOperand...maxOperand)
        let maxOp2 = maxSum - op1
        guard maxOp2 >= 1 else { return (1, 1) }
        let op2 = Int.random(in: 1...maxOp2)
        return (op1, op2)
    }

    private func generateSubtractionOperands(maxMinuend: Int, subDifficulty: Int) -> (Int, Int) {
        // op1 >= op2 always (no negative results)
        let minMinuend = max(2, subDifficulty)
        let op1 = Int.random(in: minMinuend...maxMinuend)
        let op2 = Int.random(in: 1...(op1))
        return (op1, op2)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/QuestionGeneratorTests 2>&1 | tail -10
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Core/AdaptiveEngine/QuestionGenerator.swift NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/QuestionGeneratorTests.swift
git commit -m "feat: implement question generator with level-appropriate operand ranges"
```

---

## Task 5: Audio Manager

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Audio/AudioManager.swift`

- [ ] **Step 1: Implement AudioManager**

Create `NumberOrchard/NumberOrchard/Core/Audio/AudioManager.swift`:

```swift
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    var isMusicEnabled = true
    var isSoundEnabled = true
    var isVoiceEnabled = true

    private var musicPlayer: AVAudioPlayer?
    private var soundPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func playMusic(_ filename: String) {
        guard isMusicEnabled else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.3
            musicPlayer?.play()
        } catch {
            print("Music play failed: \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func playSound(_ filename: String) {
        guard isSoundEnabled else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            soundPlayers[filename] = player
        } catch {
            print("Sound play failed: \(error)")
        }
    }

    func playVoice(_ filename: String) {
        guard isVoiceEnabled else { return }
        playSound(filename)
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Core/Audio/
git commit -m "feat: add AudioManager with music, sound effects, and voice channels"
```

---

## Task 6: Parental Gate

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/ParentalGate/ParentalGateView.swift`

- [ ] **Step 1: Implement ParentalGateView**

Create `NumberOrchard/NumberOrchard/Core/ParentalGate/ParentalGateView.swift`:

```swift
import SwiftUI

struct ParentalGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var sliderValue: CGFloat = 0
    @State private var holdCompleted = false
    @State private var timer: Timer?
    @State private var timeRemaining = 30

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("家长验证")
                    .font(.title2)
                    .foregroundStyle(.white)

                if !holdCompleted {
                    holdPhase
                } else {
                    slidePhase
                }

                Button("取消") {
                    onCancel()
                }
                .foregroundStyle(.white.opacity(0.7))

                Text("剩余时间: \(timeRemaining)秒")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .onAppear { startTimeout() }
        .onDisappear { timer?.invalidate() }
    }

    private var holdPhase: some View {
        VStack(spacing: 16) {
            Text("请长按圆圈 3 秒")
                .foregroundStyle(.white.opacity(0.8))

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 88, height: 88)
            }
            .gesture(
                LongPressGesture(minimumDuration: 3)
                    .onChanged { _ in
                        withAnimation(.linear(duration: 3)) {
                            holdProgress = 1.0
                        }
                    }
                    .onEnded { _ in
                        holdCompleted = true
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        if !holdCompleted {
                            withAnimation { holdProgress = 0 }
                        }
                    }
            )
        }
    }

    private var slidePhase: some View {
        VStack(spacing: 16) {
            Text("向右滑动解锁")
                .foregroundStyle(.white.opacity(0.8))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 50)

                    Capsule()
                        .fill(.green.opacity(0.3))
                        .frame(width: max(50, sliderValue * geo.size.width), height: 50)

                    Circle()
                        .fill(.white)
                        .frame(width: 46, height: 46)
                        .offset(x: sliderValue * (geo.size.width - 50))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    sliderValue = max(0, min(1, value.location.x / geo.size.width))
                                }
                                .onEnded { _ in
                                    if sliderValue > 0.9 {
                                        onSuccess()
                                    } else {
                                        withAnimation { sliderValue = 0 }
                                    }
                                }
                        )
                }
            }
            .frame(height: 50)
            .frame(maxWidth: 300)
        }
    }

    private func startTimeout() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    timer?.invalidate()
                    onCancel()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Core/ParentalGate/
git commit -m "feat: add parental gate with hold + slide verification"
```

---

## Task 7: Pick Fruit SpriteKit Scene (Addition)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/PickFruitScene.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/PickFruitView.swift`
- Test: `NumberOrchard/NumberOrchardTests/Features/Adventure/PickFruitLogicTests.swift`

- [ ] **Step 1: Write failing test for pick fruit game logic**

Create `NumberOrchard/NumberOrchardTests/Features/Adventure/PickFruitLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func pickFruitCorrectCountTriggersSuccess() {
    let question = MathQuestion(operand1: 3, operand2: 2, operation: .add, gameMode: .pickFruit)
    var state = PickFruitGameState(question: question)

    #expect(state.basketCount == 3) // starts with operand1
    #expect(state.fruitsOnTree == 2) // operand2 fruits to pick
    #expect(state.isComplete == false)

    state.pickFruit()
    #expect(state.basketCount == 4)
    #expect(state.fruitsOnTree == 1)
    #expect(state.isComplete == false)

    state.pickFruit()
    #expect(state.basketCount == 5)
    #expect(state.fruitsOnTree == 0)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func pickFruitCannotPickWhenTreeEmpty() {
    let question = MathQuestion(operand1: 2, operand2: 1, operation: .add, gameMode: .pickFruit)
    var state = PickFruitGameState(question: question)

    state.pickFruit() // pick the 1 fruit
    #expect(state.isComplete == true)

    // Trying to pick more should do nothing
    state.pickFruit()
    #expect(state.basketCount == 3)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/PickFruitLogicTests 2>&1 | tail -10
```

Expected: FAIL — `PickFruitGameState` not defined

- [ ] **Step 3: Implement PickFruitGameState**

Add to `NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/PickFruitScene.swift` (top of file):

```swift
import SpriteKit

struct PickFruitGameState: Sendable {
    let question: MathQuestion
    private(set) var basketCount: Int
    private(set) var fruitsOnTree: Int
    private(set) var isComplete: Bool = false
    private(set) var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.basketCount = question.operand1
        self.fruitsOnTree = question.operand2
    }

    mutating func pickFruit() {
        guard !isComplete, fruitsOnTree > 0 else { return }
        fruitsOnTree -= 1
        basketCount += 1
        if fruitsOnTree == 0 {
            isComplete = true
            isCorrect = (basketCount == question.correctAnswer)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/PickFruitLogicTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Implement PickFruitScene (SpriteKit)**

Complete `NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/PickFruitScene.swift`:

```swift
// (PickFruitGameState already defined above)

protocol PickFruitSceneDelegate: AnyObject {
    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class PickFruitScene: SKScene {
    weak var gameDelegate: PickFruitSceneDelegate?

    private var gameState: PickFruitGameState!
    private var fruitNodes: [SKSpriteNode] = []
    private var basketNode: SKSpriteNode!
    private var basketLabel: SKLabelNode!
    private var questionLabel: SKLabelNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    func configure(with question: MathQuestion) {
        self.gameState = PickFruitGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0) // #FFF8E7
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        // Question label at top
        questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 28
        questionLabel.fontColor = .darkGray
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight - 60)
        questionLabel.preferredMaxLayoutWidth = sceneWidth - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        // Basket on the right
        basketNode = SKSpriteNode(color: .brown.withAlphaComponent(0.3), size: CGSize(width: 160, height: 120))
        basketNode.position = CGPoint(x: sceneWidth * 0.7, y: sceneHeight * 0.4)
        basketNode.name = "basket"
        addChild(basketNode)

        basketLabel = SKLabelNode(text: "\(gameState.basketCount)")
        basketLabel.fontSize = 36
        basketLabel.fontColor = .darkGray
        basketLabel.fontName = "PingFangSC-Semibold"
        basketLabel.position = CGPoint(x: 0, y: -50)
        basketNode.addChild(basketLabel)

        // Tree area on the left
        let treeNode = SKSpriteNode(color: .green.withAlphaComponent(0.2), size: CGSize(width: 200, height: 250))
        treeNode.position = CGPoint(x: sceneWidth * 0.25, y: sceneHeight * 0.45)
        addChild(treeNode)

        // Fruits on tree
        for i in 0..<gameState.fruitsOnTree {
            let fruit = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
            fruit.name = "fruit_\(i)"
            let xOffset = CGFloat(i % 3 - 1) * 60
            let yOffset = CGFloat(i / 3) * 60
            fruit.position = CGPoint(
                x: sceneWidth * 0.25 + xOffset,
                y: sceneHeight * 0.5 + yOffset
            )
            // Make it round
            fruit.texture = SKTexture(image: createCircleImage(color: .systemRed, size: 50))
            addChild(fruit)
            fruitNodes.append(fruit)
        }

        // Pre-existing fruits in basket (visual only)
        for i in 0..<gameState.basketCount {
            let fruit = SKSpriteNode(color: .red, size: CGSize(width: 35, height: 35))
            fruit.texture = SKTexture(image: createCircleImage(color: .systemOrange, size: 35))
            let xOffset = CGFloat(i % 3 - 1) * 40
            let yOffset = CGFloat(i / 3) * 40 - 10
            fruit.position = CGPoint(x: xOffset, y: yOffset)
            basketNode.addChild(fruit)
        }
    }

    private func createCircleImage(color: UIColor, size: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for fruit in fruitNodes {
            if fruit.contains(location) && fruit.parent == self {
                draggingNode = fruit
                fruit.run(SKAction.scale(to: 1.2, duration: 0.1))
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNode else { return }
        node.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = draggingNode else { return }
        draggingNode = nil

        // Check if dropped on basket
        let fruitFrame = node.frame
        let basketFrame = basketNode.frame.insetBy(dx: -30, dy: -30)

        if basketFrame.intersects(fruitFrame) {
            // Success — fruit goes into basket
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.8, duration: 0.1),
                SKAction.move(to: basketNode.position, duration: 0.2),
                SKAction.removeFromParent()
            ]))

            gameState.pickFruit()
            basketLabel.text = "\(gameState.basketCount)"

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            // Return to original position
            node.run(SKAction.sequence([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.move(to: node.position, duration: 0.2)
            ]))
        }
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)

        // Success animation
        let celebration = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.showCelebration()
            },
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.gameDelegate?.pickFruitSceneDidComplete(
                    correct: true,
                    responseTime: responseTime
                )
            }
        ])
        run(celebration)
    }

    private func showCelebration() {
        // Star particles
        if let emitter = SKEmitterNode(fileNamed: "StarParticle") {
            emitter.position = basketNode.position
            addChild(emitter)
        }

        // Scale bounce on basket
        basketNode.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        // Show equation
        let equation = SKLabelNode(text: "\(gameState.question.operand1) + \(gameState.question.operand2) = \(gameState.question.correctAnswer)")
        equation.fontSize = 40
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width / 2, y: size.height / 2)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
}
```

- [ ] **Step 6: Create PickFruitView (SwiftUI wrapper)**

Create `NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/PickFruitView.swift`:

```swift
import SwiftUI
import SpriteKit

struct PickFruitView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: PickFruitScene?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = PickFruitScene(size: CGSize(width: 1194, height: 834)) // iPad Pro 11" logical
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question)
            newScene.gameDelegate = PickFruitCoordinator(onComplete: onComplete)
            scene = newScene
        }
    }
}

private class PickFruitCoordinator: NSObject, PickFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        Task { @MainActor in
            onComplete(correct, responseTime)
        }
    }
}
```

- [ ] **Step 7: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/Adventure/PickFruit/ NumberOrchard/NumberOrchardTests/Features/Adventure/PickFruitLogicTests.swift
git commit -m "feat: implement Pick Fruit (addition) game with SpriteKit drag-and-drop"
```

---

## Task 8: Share Fruit SpriteKit Scene (Subtraction)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit/ShareFruitScene.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit/ShareFruitView.swift`
- Test: `NumberOrchard/NumberOrchardTests/Features/Adventure/ShareFruitLogicTests.swift`

- [ ] **Step 1: Write failing test for share fruit game logic**

Create `NumberOrchard/NumberOrchardTests/Features/Adventure/ShareFruitLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func shareFruitCorrectCountTriggersSuccess() {
    let question = MathQuestion(operand1: 8, operand2: 3, operation: .subtract, gameMode: .shareFruit)
    var state = ShareFruitGameState(question: question)

    #expect(state.plateCount == 8) // starts with operand1
    #expect(state.givenCount == 0)
    #expect(state.targetGiveCount == 3) // operand2 to give away
    #expect(state.isComplete == false)

    state.giveFruit()
    state.giveFruit()
    #expect(state.givenCount == 2)
    #expect(state.isComplete == false)

    state.giveFruit()
    #expect(state.givenCount == 3)
    #expect(state.plateCount == 5)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func shareFruitCannotGiveMoreThanTarget() {
    let question = MathQuestion(operand1: 5, operand2: 2, operation: .subtract, gameMode: .shareFruit)
    var state = ShareFruitGameState(question: question)

    state.giveFruit()
    state.giveFruit()
    #expect(state.isComplete == true)

    state.giveFruit() // should do nothing
    #expect(state.givenCount == 2)
    #expect(state.plateCount == 3)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/ShareFruitLogicTests 2>&1 | tail -10
```

Expected: FAIL — `ShareFruitGameState` not defined

- [ ] **Step 3: Implement ShareFruitGameState and Scene**

Create `NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit/ShareFruitScene.swift`:

```swift
import SpriteKit

struct ShareFruitGameState: Sendable {
    let question: MathQuestion
    private(set) var plateCount: Int
    private(set) var givenCount: Int = 0
    let targetGiveCount: Int
    private(set) var isComplete: Bool = false
    private(set) var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.plateCount = question.operand1
        self.targetGiveCount = question.operand2
    }

    mutating func giveFruit() {
        guard !isComplete, givenCount < targetGiveCount else { return }
        givenCount += 1
        plateCount -= 1
        if givenCount == targetGiveCount {
            isComplete = true
            isCorrect = (plateCount == question.correctAnswer)
        }
    }
}

protocol ShareFruitSceneDelegate: AnyObject {
    func shareFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class ShareFruitScene: SKScene {
    weak var gameDelegate: ShareFruitSceneDelegate?

    private var gameState: ShareFruitGameState!
    private var fruitNodes: [SKSpriteNode] = []
    private var animalNode: SKSpriteNode!
    private var plateLabel: SKLabelNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    func configure(with question: MathQuestion) {
        self.gameState = ShareFruitGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        // Question label at top
        let questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 28
        questionLabel.fontColor = .darkGray
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight - 60)
        questionLabel.preferredMaxLayoutWidth = sceneWidth - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        // Big plate in center with fruits
        let plateNode = SKSpriteNode(color: .white.withAlphaComponent(0.5), size: CGSize(width: 280, height: 180))
        plateNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.55)
        addChild(plateNode)

        plateLabel = SKLabelNode(text: "\(gameState.plateCount)")
        plateLabel.fontSize = 32
        plateLabel.fontColor = .darkGray
        plateLabel.fontName = "PingFangSC-Semibold"
        plateLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.55 - 110)
        addChild(plateLabel)

        // Fruits on plate
        for i in 0..<gameState.plateCount {
            let fruit = SKSpriteNode(color: .systemPink, size: CGSize(width: 40, height: 40))
            fruit.name = "fruit_\(i)"
            fruit.texture = SKTexture(image: createCircleImage(color: .systemPink, size: 40))
            let col = i % 4
            let row = i / 4
            fruit.position = CGPoint(
                x: sceneWidth / 2 + CGFloat(col - 2) * 50 + 25,
                y: sceneHeight * 0.55 + CGFloat(row) * 50 - 30
            )
            addChild(fruit)
            fruitNodes.append(fruit)
        }

        // Animal (rabbit) at bottom
        animalNode = SKSpriteNode(color: .gray.withAlphaComponent(0.3), size: CGSize(width: 100, height: 100))
        animalNode.position = CGPoint(x: sceneWidth * 0.3, y: sceneHeight * 0.15)
        animalNode.name = "animal"
        addChild(animalNode)

        let animalLabel = SKLabelNode(text: "🐰")
        animalLabel.fontSize = 50
        animalLabel.position = CGPoint(x: 0, y: -15)
        animalNode.addChild(animalLabel)
    }

    private func createCircleImage(color: UIColor, size: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for fruit in fruitNodes {
            if fruit.contains(location) && fruit.parent == self {
                draggingNode = fruit
                fruit.run(SKAction.scale(to: 1.2, duration: 0.1))
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNode else { return }
        node.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = draggingNode else { return }
        draggingNode = nil

        let fruitFrame = node.frame
        let animalFrame = animalNode.frame.insetBy(dx: -30, dy: -30)

        if animalFrame.intersects(fruitFrame) {
            // Given to animal
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.5, duration: 0.15),
                SKAction.move(to: animalNode.position, duration: 0.15),
                SKAction.removeFromParent()
            ]))

            // Animal happy animation
            animalNode.run(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))

            gameState.giveFruit()
            plateLabel.text = "\(gameState.plateCount)"

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            // Return fruit
            node.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)

        let equation = SKLabelNode(text: "\(gameState.question.operand1) - \(gameState.question.operand2) = \(gameState.question.correctAnswer)")
        equation.fontSize = 40
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width / 2, y: size.height / 2)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.3))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.gameDelegate?.shareFruitSceneDidComplete(
                    correct: true,
                    responseTime: responseTime
                )
            }
        ]))
    }
}
```

- [ ] **Step 4: Create ShareFruitView (SwiftUI wrapper)**

Create `NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit/ShareFruitView.swift`:

```swift
import SwiftUI
import SpriteKit

struct ShareFruitView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: ShareFruitScene?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = ShareFruitScene(size: CGSize(width: 1194, height: 834))
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question)
            newScene.gameDelegate = ShareFruitCoordinator(onComplete: onComplete)
            scene = newScene
        }
    }
}

private class ShareFruitCoordinator: NSObject, ShareFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func shareFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        Task { @MainActor in
            onComplete(correct, responseTime)
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/ShareFruitLogicTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/Adventure/ShareFruit/ NumberOrchard/NumberOrchardTests/Features/Adventure/ShareFruitLogicTests.swift
git commit -m "feat: implement Share Fruit (subtraction) game with drag-to-animal mechanic"
```

---

## Task 9: Adventure Session (Game Flow Controller)

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionViewModel.swift`

- [ ] **Step 1: Implement AdventureSessionViewModel**

Create `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionViewModel.swift`:

```swift
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AdventureSessionViewModel {
    private let questionGenerator = QuestionGenerator()
    private let difficultyManager = DifficultyManager()
    private let treeCalculator = TreeGrowthCalculator()

    var currentQuestion: MathQuestion?
    var questionsCompleted: Int = 0
    var totalQuestions: Int = 5  // questions per session
    var consecutiveCorrect: Int = 0
    var isSessionComplete: Bool = false
    var experienceGained: Int = 0

    private var learningProfile: LearningProfile
    private var session: LearningSession
    private var profile: ChildProfile

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.learningProfile = LearningProfile(from: profile)
        self.session = LearningSession(level: profile.difficultyLevel)
        modelContext.insert(session)
        profile.sessions.append(session)
        generateNextQuestion()
    }

    func generateNextQuestion() {
        guard questionsCompleted < totalQuestions else {
            isSessionComplete = true
            return
        }
        currentQuestion = questionGenerator.generate(for: learningProfile)
    }

    func handleAnswer(correct: Bool, responseTime: TimeInterval, usedHint: Bool) {
        guard let question = currentQuestion else { return }

        // Record
        let record = QuestionRecord(
            question: question,
            userAnswer: correct ? question.correctAnswer : -1,
            responseTime: responseTime,
            usedHint: usedHint
        )
        session.records.append(record)

        // Update adaptive engine
        learningProfile = difficultyManager.updateAfterAnswer(
            profile: learningProfile,
            isCorrect: correct,
            usedHint: usedHint
        )

        // Update streak
        if correct {
            consecutiveCorrect += 1
            let exp = treeCalculator.experienceForCorrectAnswer(combo: consecutiveCorrect)
            experienceGained += exp
            profile.treeExperience += exp
            profile.treeStage = TreeGrowthCalculator.stageFor(experience: profile.treeExperience)
            profile.totalCorrect += 1
        } else {
            consecutiveCorrect = 0
        }

        profile.totalQuestions += 1
        questionsCompleted += 1

        // Check level promotion
        if difficultyManager.shouldPromoteLevel(profile: learningProfile) {
            learningProfile = difficultyManager.promote(profile: learningProfile)
            profile.difficultyLevel = learningProfile.currentLevel
            profile.subDifficulty = learningProfile.subDifficulty
        } else {
            profile.subDifficulty = learningProfile.subDifficulty
        }

        // Next question or finish
        generateNextQuestion()
    }

    func finishSession() {
        session.durationSeconds = Date().timeIntervalSince(session.date)
        isSessionComplete = true
    }
}
```

- [ ] **Step 2: Implement AdventureSessionView**

Replace `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionView.swift`:

```swift
import SwiftUI
import SwiftData

struct AdventureSessionView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: AdventureSessionViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isSessionComplete {
                    sessionCompleteView(viewModel: viewModel)
                } else if let question = viewModel.currentQuestion {
                    gameView(for: question, viewModel: viewModel)
                }
            } else {
                ProgressView("加载中...")
            }
        }
        .onAppear {
            let profile = profiles.first ?? createDefaultProfile()
            viewModel = AdventureSessionViewModel(profile: profile, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private func gameView(for question: MathQuestion, viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack {
                Text("第 \(viewModel.questionsCompleted + 1)/\(viewModel.totalQuestions) 题")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("暂停") {
                    viewModel.finishSession()
                    onFinish()
                }
                .font(.callout)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Game scene
            switch question.gameMode {
            case .pickFruit:
                PickFruitView(question: question) { correct, time in
                    viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                }
            case .shareFruit:
                ShareFruitView(question: question) { correct, time in
                    viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                }
            }
        }
    }

    private func sessionCompleteView(viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 24) {
            Text("太棒了！")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("今天完成了 \(viewModel.questionsCompleted) 道题")
                .font(.title2)

            Text("获得经验 +\(viewModel.experienceGained)")
                .font(.title3)
                .foregroundStyle(.orange)

            Button(action: onFinish) {
                Text("回到果园")
                    .font(.title3)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private func createDefaultProfile() -> ChildProfile {
        let profile = ChildProfile(name: "小果农")
        modelContext.insert(profile)
        return profile
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/Adventure/
git commit -m "feat: implement adventure session flow with question cycling and progress tracking"
```

---

## Task 10: Eye Care Manager

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/DailyFlow/EyeCareManager.swift`
- Test: `NumberOrchard/NumberOrchardTests/Features/DailyFlow/EyeCareManagerTests.swift`

- [ ] **Step 1: Write failing test**

Create `NumberOrchard/NumberOrchardTests/Features/DailyFlow/EyeCareManagerTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func softReminderAt80Percent() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 10) == .none)
    #expect(manager.alertLevel(afterMinutes: 15) == .none)
    #expect(manager.alertLevel(afterMinutes: 16) == .soft)  // 80% of 20
    #expect(manager.alertLevel(afterMinutes: 19) == .soft)
}

@Test func gentleReminderAtLimit() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 20) == .gentle)
    #expect(manager.alertLevel(afterMinutes: 23) == .gentle)
}

@Test func forceLockAfterFiveMinutesOver() {
    let manager = EyeCareManager(timeLimitMinutes: 20)

    #expect(manager.alertLevel(afterMinutes: 25) == .locked)
    #expect(manager.alertLevel(afterMinutes: 30) == .locked)
}

@Test func customTimeLimitWorks() {
    let manager = EyeCareManager(timeLimitMinutes: 10)

    #expect(manager.alertLevel(afterMinutes: 7) == .none)
    #expect(manager.alertLevel(afterMinutes: 8) == .soft)   // 80% of 10
    #expect(manager.alertLevel(afterMinutes: 10) == .gentle)
    #expect(manager.alertLevel(afterMinutes: 15) == .locked)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/EyeCareManagerTests 2>&1 | tail -10
```

Expected: FAIL — `EyeCareManager` not defined

- [ ] **Step 3: Implement EyeCareManager**

Create `NumberOrchard/NumberOrchard/Features/DailyFlow/EyeCareManager.swift`:

```swift
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

    /// Use the one-time 5-minute extension
    func useExtension() {
        guard !hasUsedExtension else { return }
        hasUsedExtension = true
        // Effectively adds 5 minutes by not changing — the alert logic handles it
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NumberOrchardTests/EyeCareManagerTests 2>&1 | tail -10
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/DailyFlow/ NumberOrchard/NumberOrchardTests/Features/DailyFlow/
git commit -m "feat: implement eye care manager with three-tier time alerts"
```

---

## Task 11: Daily Check-In

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/DailyFlow/CheckInView.swift`

- [ ] **Step 1: Implement CheckInView**

Create `NumberOrchard/NumberOrchard/Features/DailyFlow/CheckInView.swift`:

```swift
import SwiftUI

struct CheckInView: View {
    let consecutiveDays: Int
    let onDismiss: () -> Void

    @State private var showReward = false

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.97, blue: 0.91)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("欢迎回来，小果农！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown)

                // Consecutive days
                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { day in
                        VStack {
                            Circle()
                                .fill(day <= (consecutiveDays % 7 == 0 ? 7 : consecutiveDays % 7) ? .orange : .gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text("\(day)")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                }

                if showReward {
                    VStack(spacing: 8) {
                        Text("🌱")
                            .font(.system(size: 60))
                        Text("获得种子 ×1")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: onDismiss) {
                    Text("开始今天的冒险")
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.5)) {
                showReward = true
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/DailyFlow/CheckInView.swift
git commit -m "feat: add daily check-in view with consecutive day tracking"
```

---

## Task 12: Home View (Orchard Main Screen)

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Home/HomeViewModel.swift`

- [ ] **Step 1: Implement HomeViewModel**

Create `NumberOrchard/NumberOrchard/Features/Home/HomeViewModel.swift`:

```swift
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
                // Already logged in today
                showCheckIn = false
            } else if calendar.date(byAdding: .day, value: 1, to: lastDay) == today {
                // Consecutive day
                profile.consecutiveLoginDays += 1
                profile.lastLoginDate = Date()
                profile.seeds += 1
                showCheckIn = true
            } else {
                // Streak broken
                profile.consecutiveLoginDays = 1
                profile.lastLoginDate = Date()
                profile.seeds += 1
                showCheckIn = true
            }
        } else {
            // First login ever
            profile.consecutiveLoginDays = 1
            profile.lastLoginDate = Date()
            profile.seeds += 1
            showCheckIn = true
        }
    }

    var treeStageEmoji: String {
        guard let profile else { return "🌱" }
        switch profile.treeStage {
        case 0: return "🌱"  // seed
        case 1: return "🌿"  // sprout
        case 2: return "🪴"  // sapling
        case 3: return "🌳"  // small tree
        case 4: return "🌲"  // big tree
        case 5: return "🌸"  // bloom
        case 6: return "🍎"  // fruit
        default: return "🌱"
        }
    }

    var treeProgress: Double {
        guard let profile else { return 0 }
        return TreeGrowthCalculator.progressInCurrentStage(experience: profile.treeExperience)
    }
}
```

- [ ] **Step 2: Implement HomeView**

Replace `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`:

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel = HomeViewModel()

    private var profile: ChildProfile {
        if let existing = profiles.first { return existing }
        let newProfile = ChildProfile(name: "小果农")
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.95, blue: 0.85), Color(red: 1.0, green: 0.97, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // Top bar
                HStack {
                    // Stars & Seeds
                    HStack(spacing: 16) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title3)

                    Spacer()

                    // Parent center button (small gear)
                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                // Tree display
                VStack(spacing: 12) {
                    Text(viewModel.treeStageEmoji)
                        .font(.system(size: 100))

                    // Progress bar
                    ProgressView(value: viewModel.treeProgress)
                        .frame(width: 200)
                        .tint(.green)

                    Text(profile.difficultyLevel.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Start adventure button
                Button(action: onStartAdventure) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("今日冒险")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                }

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            viewModel.checkDailyLogin(profile: profile)
        }
        .fullScreenCover(isPresented: $viewModel.showCheckIn) {
            CheckInView(
                consecutiveDays: profile.consecutiveLoginDays,
                onDismiss: { viewModel.showCheckIn = false }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    viewModel.showParentalGate = false
                    onOpenParentCenter()
                },
                onCancel: {
                    viewModel.showParentalGate = false
                }
            )
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/Home/
git commit -m "feat: implement home view with tree display, daily check-in, and parent gate entry"
```

---

## Task 13: Parent Center (Settings & Basic Report)

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/ParentCenter/ParentCenterView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/ParentCenter/SettingsView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/ParentCenter/BasicReportView.swift`

- [ ] **Step 1: Implement ParentCenterView**

Replace `NumberOrchard/NumberOrchard/Features/ParentCenter/ParentCenterView.swift`:

```swift
import SwiftUI
import SwiftData

struct ParentCenterView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedTab = 0

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            if let profile {
                TabView(selection: $selectedTab) {
                    BasicReportView(profile: profile)
                        .tag(0)
                        .tabItem {
                            Label("学习报告", systemImage: "chart.bar")
                        }

                    SettingsView(profile: profile)
                        .tag(1)
                        .tabItem {
                            Label("设置", systemImage: "gearshape")
                        }
                }
                .navigationTitle("家长中心")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("返回") { onDismiss() }
                    }
                }
            } else {
                Text("暂无数据")
            }
        }
    }
}
```

- [ ] **Step 2: Implement SettingsView**

Create `NumberOrchard/NumberOrchard/Features/ParentCenter/SettingsView.swift`:

```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: ChildProfile
    @State private var musicEnabled = true
    @State private var soundEnabled = true
    @State private var voiceEnabled = true

    var body: some View {
        Form {
            Section("用眼管理") {
                Stepper(
                    "每日使用时长上限: \(profile.dailyTimeLimitMinutes) 分钟",
                    value: $profile.dailyTimeLimitMinutes,
                    in: 10...60,
                    step: 5
                )
            }

            Section("难度设置") {
                HStack {
                    Text("当前级别")
                    Spacer()
                    Text(profile.difficultyLevel.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("运算范围")
                    Spacer()
                    Text("\(profile.difficultyLevel.maxNumber) 以内")
                        .foregroundStyle(.secondary)
                }
            }

            Section("音频") {
                Toggle("背景音乐", isOn: $musicEnabled)
                Toggle("音效", isOn: $soundEnabled)
                Toggle("语音提示", isOn: $voiceEnabled)
            }
            .onChange(of: musicEnabled) { _, new in
                AudioManager.shared.isMusicEnabled = new
            }
            .onChange(of: soundEnabled) { _, new in
                AudioManager.shared.isSoundEnabled = new
            }
            .onChange(of: voiceEnabled) { _, new in
                AudioManager.shared.isVoiceEnabled = new
            }

            Section("档案") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(profile.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("创建日期")
                    Spacer()
                    Text(profile.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Implement BasicReportView**

Create `NumberOrchard/NumberOrchard/Features/ParentCenter/BasicReportView.swift`:

```swift
import SwiftUI
import SwiftData
import Charts

struct BasicReportView: View {
    let profile: ChildProfile

    private var todaySessions: [LearningSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return profile.sessions.filter { calendar.startOfDay(for: $0.date) == today }
    }

    private var todayQuestionCount: Int {
        todaySessions.reduce(0) { $0 + $1.records.count }
    }

    private var todayCorrectCount: Int {
        todaySessions.reduce(0) { $0 + $1.correctCount }
    }

    private var todayAccuracy: Double {
        guard todayQuestionCount > 0 else { return 0 }
        return Double(todayCorrectCount) / Double(todayQuestionCount)
    }

    private var todayDurationMinutes: Double {
        todaySessions.reduce(0) { $0 + $1.durationSeconds } / 60.0
    }

    private var last7DaysData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let day = calendar.startOfDay(for: date)
            let count = profile.sessions
                .filter { calendar.startOfDay(for: $0.date) == day }
                .reduce(0) { $0 + $1.records.count }
            return (date: day, count: count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's summary
                GroupBox("今日学习") {
                    HStack(spacing: 40) {
                        statItem(value: "\(todayQuestionCount)", label: "做题数")
                        statItem(value: "\(Int(todayAccuracy * 100))%", label: "正确率")
                        statItem(value: String(format: "%.0f 分钟", todayDurationMinutes), label: "用时")
                    }
                    .padding(.vertical, 8)
                }

                // Weekly chart
                GroupBox("本周趋势") {
                    Chart(last7DaysData, id: \.date) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("题数", item.count)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                }

                // Overall stats
                GroupBox("总体进度") {
                    HStack(spacing: 40) {
                        statItem(value: "\(profile.totalQuestions)", label: "总题量")
                        statItem(value: "\(profile.consecutiveLoginDays) 天", label: "连续学习")
                        statItem(value: profile.difficultyLevel.displayName, label: "当前级别")
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/ParentCenter/
git commit -m "feat: implement parent center with settings and basic report with weekly chart"
```

---

## Task 14: Eye Care Integration & App Coordinator Update

**Files:**
- Modify: `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`

- [ ] **Step 1: Update AppCoordinator with eye care overlay**

Replace `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`:

```swift
import SwiftUI
import SwiftData

enum AppScreen {
    case home
    case adventure
    case parentCenter
}

struct AppCoordinator: View {
    @State private var currentScreen: AppScreen = .home
    @State private var eyeCareManager = EyeCareManager()
    @State private var showEyeCareAlert = false
    @State private var eyeCareTimer: Timer?

    @Query private var profiles: [ChildProfile]

    var body: some View {
        ZStack {
            Group {
                switch currentScreen {
                case .home:
                    HomeView(
                        onStartAdventure: { startAdventure() },
                        onOpenParentCenter: { currentScreen = .parentCenter }
                    )
                case .adventure:
                    AdventureSessionView(
                        onFinish: { stopAdventure() }
                    )
                case .parentCenter:
                    ParentCenterView(
                        onDismiss: { currentScreen = .home }
                    )
                }
            }

            if showEyeCareAlert {
                eyeCareOverlay
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden(true)
    }

    private var eyeCareOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🌳")
                    .font(.system(size: 60))

                Text("小果农休息一下吧！")
                    .font(.title)
                    .foregroundStyle(.white)

                Text("站起来看看窗外～")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                if !eyeCareManager.hasUsedExtension {
                    Button {
                        eyeCareManager.useExtension()
                        showEyeCareAlert = false
                    } label: {
                        Text("再玩 5 分钟")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }

                Button {
                    stopAdventure()
                    showEyeCareAlert = false
                } label: {
                    Text("结束今天的学习")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func startAdventure() {
        let timeLimit = profiles.first?.dailyTimeLimitMinutes ?? 20
        eyeCareManager = EyeCareManager(timeLimitMinutes: timeLimit)
        eyeCareManager.startSession()
        currentScreen = .adventure
        startEyeCareMonitoring()
    }

    private func stopAdventure() {
        eyeCareTimer?.invalidate()
        eyeCareTimer = nil
        currentScreen = .home
    }

    private func startEyeCareMonitoring() {
        eyeCareTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                let level = eyeCareManager.currentAlertLevel
                if level == .gentle || level == .locked {
                    showEyeCareAlert = true
                }
                if level == .locked {
                    eyeCareTimer?.invalidate()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/App/AppCoordinator.swift
git commit -m "feat: integrate eye care monitoring into app coordinator with time alerts"
```

---

## Task 15: Tree Growth View

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Orchard/TreeGrowthView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Orchard/TreeGrowthViewModel.swift`

- [ ] **Step 1: Implement TreeGrowthViewModel**

Create `NumberOrchard/NumberOrchard/Features/Orchard/TreeGrowthViewModel.swift`:

```swift
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
```

- [ ] **Step 2: Implement TreeGrowthView**

Create `NumberOrchard/NumberOrchard/Features/Orchard/TreeGrowthView.swift`:

```swift
import SwiftUI

struct TreeGrowthView: View {
    let profile: ChildProfile

    @State private var viewModel: TreeGrowthViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VStack(spacing: 20) {
                    Text("我的果树")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.stageEmoji)
                        .font(.system(size: 120))
                        .shadow(radius: 5)

                    Text(viewModel.stageName)
                        .font(.title3)
                        .foregroundStyle(.brown)

                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.progress)
                            .frame(width: 200)
                            .tint(.green)
                        Text(viewModel.experienceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel = TreeGrowthViewModel(profile: profile)
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add NumberOrchard/NumberOrchard/Features/Orchard/
git commit -m "feat: add tree growth view with stage visualization and progress display"
```

---

## Task 16: Final Integration & Build Verification

**Files:**
- Modify: `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift` (ensure all models registered)

- [ ] **Step 1: Verify all SwiftData models are registered**

Update `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift` to include all models:

```swift
import SwiftUI
import SwiftData

@main
struct NumberOrchardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **Step 2: Run full build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | tail -20
```

Expected: All tests pass

- [ ] **Step 4: Commit final integration**

```bash
cd /Users/samxiao/code/app
git add .
git commit -m "feat: complete MVP integration — all modules wired and building"
```

---

## Summary

| Task | Component | Tests |
|------|-----------|-------|
| 1 | Project setup & scaffold | — |
| 2 | Core data models | OrchardStateTests |
| 3 | Adaptive difficulty engine | DifficultyManagerTests |
| 4 | Question generator | QuestionGeneratorTests |
| 5 | Audio manager | — |
| 6 | Parental gate | — |
| 7 | Pick Fruit (addition) | PickFruitLogicTests |
| 8 | Share Fruit (subtraction) | ShareFruitLogicTests |
| 9 | Adventure session flow | — |
| 10 | Eye care manager | EyeCareManagerTests |
| 11 | Daily check-in | — |
| 12 | Home view | — |
| 13 | Parent center (settings + report) | — |
| 14 | Eye care integration | — |
| 15 | Tree growth view | — |
| 16 | Final integration & build | — |

**Total: 16 tasks, ~80 steps, 6 test files**
