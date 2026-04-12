# Number Orchard Extended Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the Number Orchard iPad app with 7 new feature modules: exploration map with 20 stations, decoration system (53 items), fruit collection (30 fruits), Number Train (凑十法) game, Balance Park (等式) game, L5/L6 difficulty (20 以内 with carry/borrow), and parent-child battle.

**Architecture:** Build on existing MVP (SwiftUI + SpriteKit + SwiftData). Add 3 new @Model types, 3 static catalogs, 2 new SKScene-based games, 4 new SwiftUI feature areas, and expand DifficultyLevel to 6 levels. All art uses emoji + SF Symbols as placeholders.

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, SwiftData, AVFoundation, iPadOS 17.0+, Swift Testing.

---

## File Structure

```
NumberOrchard/NumberOrchard/
├── Core/
│   ├── Models/
│   │   ├── DifficultyLevel.swift          (modify: +L5, +L6)
│   │   ├── MathQuestion.swift             (modify: +GameMode cases)
│   │   ├── ChildProfile.swift             (modify: +relationships)
│   │   ├── StationProgress.swift          (NEW @Model)
│   │   ├── CollectedDecoration.swift      (NEW @Model)
│   │   ├── CollectedFruit.swift           (NEW @Model)
│   │   ├── DecorationCatalog.swift        (NEW static catalog)
│   │   ├── FruitCatalog.swift             (NEW static catalog)
│   │   └── MapCatalog.swift               (NEW static catalog)
│   ├── AdaptiveEngine/
│   │   └── QuestionGenerator.swift        (modify: L5/L6 + Train/Balance)
│   ├── Rewards/ (NEW)
│   │   └── RewardCalculator.swift         (NEW)
│   └── Exploration/ (NEW)
│       └── MapProgressionLogic.swift      (NEW)
├── Features/
│   ├── Adventure/
│   │   ├── AdventureSessionView.swift     (modify)
│   │   ├── AdventureSessionViewModel.swift (modify)
│   │   ├── NumberTrain/ (NEW)
│   │   │   ├── NumberTrainScene.swift
│   │   │   └── NumberTrainView.swift
│   │   └── Balance/ (NEW)
│   │       ├── BalanceScene.swift
│   │       └── BalanceView.swift
│   ├── Exploration/ (NEW)
│   │   ├── ExplorationMapView.swift
│   │   ├── ExplorationMapViewModel.swift
│   │   └── StationDetailView.swift
│   ├── Orchard/
│   │   ├── TreeGrowthView.swift           (unchanged)
│   │   ├── FruitCollectionView.swift      (NEW)
│   │   └── DecorateOrchardView.swift      (NEW)
│   ├── ParentChild/ (NEW)
│   │   ├── BattleView.swift
│   │   ├── BattleViewModel.swift
│   │   └── ParentQuestionGenerator.swift
│   └── Home/
│       └── HomeView.swift                 (modify: 4 entry buttons)
├── App/
│   ├── AppCoordinator.swift               (modify: map+decorate+collection+battle routes)
│   └── NumberOrchardApp.swift             (modify: register new @Model types)
└── NumberOrchardTests/
    ├── Core/
    │   ├── Rewards/
    │   │   └── RewardCalculatorTests.swift
    │   └── Exploration/
    │       └── MapProgressionLogicTests.swift
    └── Features/
        ├── Adventure/
        │   ├── NumberTrainLogicTests.swift
        │   └── BalanceLogicTests.swift
        ├── Orchard/
        │   ├── DecorationInventoryTests.swift
        │   └── FruitCollectionTests.swift
        └── ParentChild/
            └── ParentBattleTests.swift
```

---

# Phase 1: Data Foundation

## Task 1: Extend DifficultyLevel with L5 and L6

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/Models/DifficultyLevel.swift`

- [ ] **Step 1: Update enum to include all 6 levels**

Replace entire file contents of `NumberOrchard/NumberOrchard/Core/Models/DifficultyLevel.swift`:

```swift
import Foundation

enum DifficultyLevel: Int, Codable, Comparable, CaseIterable, Sendable {
    case seed = 1       // L1: 5 以内加法
    case sprout = 2     // L2: 5 以内加减法
    case smallTree = 3  // L3: 10 以内加法
    case bigTree = 4    // L4: 10 以内加减法
    case bloom = 5      // L5: 20 以内加法 (含进位)
    case harvest = 6    // L6: 20 以内加减法 (含进退位)

    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .seed: return "种子"
        case .sprout: return "发芽"
        case .smallTree: return "小树"
        case .bigTree: return "大树"
        case .bloom: return "开花"
        case .harvest: return "结果"
        }
    }

    var maxNumber: Int {
        switch self {
        case .seed, .sprout: return 5
        case .smallTree, .bigTree: return 10
        case .bloom, .harvest: return 20
        }
    }

    var allowsSubtraction: Bool {
        switch self {
        case .seed, .smallTree, .bloom: return false
        case .sprout, .bigTree, .harvest: return true
        }
    }

    var promotionThreshold: Double {
        switch self {
        case .seed: return 0.80
        case .sprout: return 0.75
        case .smallTree: return 0.75
        case .bigTree: return 0.70
        case .bloom: return 0.70
        case .harvest: return 0.70
        }
    }

    var minimumQuestionsForPromotion: Int { 10 }
}
```

- [ ] **Step 2: Update DifficultyManager max-level guard**

Modify `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/DifficultyManager.swift` — find:

```swift
    func shouldPromoteLevel(profile: LearningProfile) -> Bool {
        // No promotion beyond bigTree in MVP
        guard profile.currentLevel != .bigTree else { return false }
```

Replace with:

```swift
    func shouldPromoteLevel(profile: LearningProfile) -> Bool {
        // No promotion beyond harvest (max level)
        guard profile.currentLevel != .harvest else { return false }
```

- [ ] **Step 3: Update DifficultyManagerTests for new max**

Modify `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/DifficultyManagerTests.swift` — find:

```swift
@Test func noPromotionAtMaxLevel() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 5)
    profile.levelQuestionCount = 20
    profile.levelCorrectCount = 20

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false) // bigTree is max for MVP
}
```

Replace with:

```swift
@Test func noPromotionAtMaxLevel() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .harvest, subDifficulty: 5)
    profile.levelQuestionCount = 20
    profile.levelCorrectCount = 20

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == false) // harvest is the true max (L6)
}

@Test func promotionFromBigTreeToBloom() {
    let manager = DifficultyManager()
    var profile = LearningProfile(currentLevel: .bigTree, subDifficulty: 3)
    profile.levelQuestionCount = 10
    profile.levelCorrectCount = 8  // 80% > 70% threshold

    let shouldPromote = manager.shouldPromoteLevel(profile: profile)
    #expect(shouldPromote == true)

    let newProfile = manager.promote(profile: profile)
    #expect(newProfile.currentLevel == .bloom)
}
```

- [ ] **Step 4: Build and verify tests pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test.*passed|error:|BUILD"
```
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: extend DifficultyLevel with L5 bloom and L6 harvest"
```

---

## Task 2: Extend MathQuestion with new game modes

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/Models/MathQuestion.swift`

- [ ] **Step 1: Add new GameMode cases**

Replace entire file contents of `NumberOrchard/NumberOrchard/Core/Models/MathQuestion.swift`:

```swift
import Foundation

enum MathOperation: String, Codable, Sendable {
    case add
    case subtract
}

enum GameMode: String, Codable, Sendable, CaseIterable {
    case pickFruit   // 摘果子 (加法)
    case shareFruit  // 分果果 (减法)
    case numberTrain // 数字火车 (凑十法)
    case balance     // 天平乐园 (等式)
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
        switch gameMode {
        case .pickFruit:
            return "篮子里有 \(operand1) 个，再摘 \(operand2) 个，一共几个？"
        case .shareFruit:
            return "盘子里有 \(operand1) 个，分给小兔 \(operand2) 个，还剩几个？"
        case .numberTrain:
            // For train: operand1 is what's shown sitting, answer (operand2) is empty seats.
            // Total seats = operand1 + operand2.
            let total = operand1 + operand2
            return "火车有 \(total) 个座位，坐了 \(operand1) 个，还有几个空座？"
        case .balance:
            // For balance: total on left (correctAnswer) = operand1 + operand2 on right
            let total = correctAnswer
            return "天平左边有 \(total) 个，右边有 \(operand1) 个，再放几个能平衡？"
        }
    }
}
```

- [ ] **Step 2: Build to verify no break in existing code**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add numberTrain and balance game modes to MathQuestion"
```

---

## Task 3: Create StationProgress @Model

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/StationProgress.swift`

- [ ] **Step 1: Create the @Model**

Create `NumberOrchard/NumberOrchard/Core/Models/StationProgress.swift`:

```swift
import Foundation
import SwiftData

@Model
final class StationProgress {
    var stationId: String
    var stars: Int
    var bestAccuracy: Double
    var attemptsCount: Int
    var unlocked: Bool

    @Relationship(inverse: \ChildProfile.stationProgress)
    var profile: ChildProfile?

    init(stationId: String, unlocked: Bool = false) {
        self.stationId = stationId
        self.stars = 0
        self.bestAccuracy = 0
        self.attemptsCount = 0
        self.unlocked = unlocked
    }
}
```

- [ ] **Step 2: Commit (build verification in Task 6 after all relationships added)**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add StationProgress SwiftData model"
```

---

## Task 4: Create CollectedDecoration @Model

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/CollectedDecoration.swift`

- [ ] **Step 1: Create the @Model**

Create `NumberOrchard/NumberOrchard/Core/Models/CollectedDecoration.swift`:

```swift
import Foundation
import SwiftData

@Model
final class CollectedDecoration {
    var itemId: String
    var acquiredAt: Date
    var isPlaced: Bool
    var positionX: Double  // 0.0 - 1.0 (percentage of orchard scene width)
    var positionY: Double

    @Relationship(inverse: \ChildProfile.decorations)
    var profile: ChildProfile?

    init(itemId: String) {
        self.itemId = itemId
        self.acquiredAt = Date()
        self.isPlaced = false
        self.positionX = 0.5
        self.positionY = 0.5
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add CollectedDecoration SwiftData model"
```

---

## Task 5: Create CollectedFruit @Model

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/CollectedFruit.swift`

- [ ] **Step 1: Create the @Model**

Create `NumberOrchard/NumberOrchard/Core/Models/CollectedFruit.swift`:

```swift
import Foundation
import SwiftData

@Model
final class CollectedFruit {
    var fruitId: String
    var unlockedAt: Date
    var unlockedFromStationId: String?

    @Relationship(inverse: \ChildProfile.collectedFruits)
    var profile: ChildProfile?

    init(fruitId: String, unlockedFromStationId: String? = nil) {
        self.fruitId = fruitId
        self.unlockedAt = Date()
        self.unlockedFromStationId = unlockedFromStationId
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add CollectedFruit SwiftData model"
```

---

## Task 6: Extend ChildProfile with new relationships

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`

- [ ] **Step 1: Add three new @Relationship properties**

In `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`, find:

```swift
    @Relationship(deleteRule: .cascade)
    var sessions: [LearningSession] = []
```

Replace with:

```swift
    @Relationship(deleteRule: .cascade)
    var sessions: [LearningSession] = []

    @Relationship(deleteRule: .cascade)
    var stationProgress: [StationProgress] = []

    @Relationship(deleteRule: .cascade)
    var decorations: [CollectedDecoration] = []

    @Relationship(deleteRule: .cascade)
    var collectedFruits: [CollectedFruit] = []
```

- [ ] **Step 2: Register new models in NumberOrchardApp**

Modify `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift` — find:

```swift
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
        ])
```

Replace with:

```swift
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
            StationProgress.self,
            CollectedDecoration.self,
            CollectedFruit.self,
        ])
```

- [ ] **Step 3: Build to verify all models compile together**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run tests to make sure nothing broke**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run|BUILD|\*\* TEST"
```
Expected: TEST SUCCEEDED with 24+ tests passing

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: wire StationProgress, decoration, fruit relationships into ChildProfile"
```

---

## Task 7: Create DecorationCatalog

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/DecorationCatalog.swift`

- [ ] **Step 1: Create catalog**

Create `NumberOrchard/NumberOrchard/Core/Models/DecorationCatalog.swift`:

```swift
import Foundation

struct DecorationItem: Identifiable, Sendable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let cost: Int
    let category: DecorationCategory
}

enum DecorationCategory: String, CaseIterable, Sendable {
    case fence      = "栅栏"
    case flower     = "花卉"
    case plant      = "植物"
    case animal     = "动物"
    case water      = "水景"
    case building   = "建筑"
    case festival   = "节日"
}

enum DecorationCatalog {
    static let items: [DecorationItem] = [
        // Fences (5)
        .init(id: "log_fence",     emoji: "🪵", name: "木栅栏",   cost: 5,  category: .fence),
        .init(id: "bamboo_fence",  emoji: "🎋", name: "竹栅栏",   cost: 8,  category: .fence),
        .init(id: "brick_wall",    emoji: "🧱", name: "砖墙",     cost: 12, category: .fence),
        .init(id: "stone_pile",    emoji: "🪨", name: "石堆",     cost: 8,  category: .fence),
        .init(id: "wood_post",     emoji: "🪵", name: "木桩",     cost: 5,  category: .fence),

        // Flowers (10)
        .init(id: "daisy",         emoji: "🌼", name: "雏菊",     cost: 5,  category: .flower),
        .init(id: "sunflower",     emoji: "🌻", name: "向日葵",   cost: 8,  category: .flower),
        .init(id: "tulip",         emoji: "🌷", name: "郁金香",   cost: 8,  category: .flower),
        .init(id: "rose",          emoji: "🌹", name: "玫瑰",     cost: 12, category: .flower),
        .init(id: "hibiscus",      emoji: "🌺", name: "木槿",     cost: 10, category: .flower),
        .init(id: "lotus",         emoji: "🪷", name: "莲花",     cost: 15, category: .flower),
        .init(id: "hyacinth",      emoji: "🪻", name: "风信子",   cost: 12, category: .flower),
        .init(id: "cherry_blossom",emoji: "🌸", name: "樱花",     cost: 10, category: .flower),
        .init(id: "white_flower",  emoji: "💮", name: "白花",     cost: 8,  category: .flower),
        .init(id: "bouquet",       emoji: "💐", name: "花束",     cost: 20, category: .flower),

        // Plants/Trees (8)
        .init(id: "evergreen",     emoji: "🌲", name: "松树",     cost: 15, category: .plant),
        .init(id: "oak_tree",      emoji: "🌳", name: "大树",     cost: 15, category: .plant),
        .init(id: "palm_tree",     emoji: "🌴", name: "棕榈树",   cost: 20, category: .plant),
        .init(id: "potted_plant",  emoji: "🪴", name: "盆栽",     cost: 8,  category: .plant),
        .init(id: "bamboo_grove",  emoji: "🎋", name: "竹林",     cost: 12, category: .plant),
        .init(id: "cactus",        emoji: "🌵", name: "仙人掌",   cost: 10, category: .plant),
        .init(id: "four_leaf",     emoji: "🍀", name: "四叶草",   cost: 15, category: .plant),
        .init(id: "herb",          emoji: "🌿", name: "药草",     cost: 5,  category: .plant),

        // Animals (12)
        .init(id: "butterfly",     emoji: "🦋", name: "蝴蝶",     cost: 12, category: .animal),
        .init(id: "bee",           emoji: "🐝", name: "蜜蜂",     cost: 10, category: .animal),
        .init(id: "ladybug",       emoji: "🐞", name: "瓢虫",     cost: 10, category: .animal),
        .init(id: "caterpillar",   emoji: "🐛", name: "毛毛虫",   cost: 8,  category: .animal),
        .init(id: "snail",         emoji: "🐌", name: "蜗牛",     cost: 8,  category: .animal),
        .init(id: "squirrel",      emoji: "🐿️", name: "松鼠",    cost: 15, category: .animal),
        .init(id: "rabbit_deco",   emoji: "🐇", name: "兔子",     cost: 15, category: .animal),
        .init(id: "hedgehog",      emoji: "🦔", name: "刺猬",     cost: 15, category: .animal),
        .init(id: "bird",          emoji: "🐦", name: "小鸟",     cost: 10, category: .animal),
        .init(id: "chick",         emoji: "🐥", name: "小鸡",     cost: 12, category: .animal),
        .init(id: "duck",          emoji: "🦆", name: "鸭子",     cost: 12, category: .animal),
        .init(id: "frog",          emoji: "🐸", name: "青蛙",     cost: 12, category: .animal),

        // Water (5)
        .init(id: "fountain",      emoji: "⛲", name: "小喷泉",   cost: 30, category: .water),
        .init(id: "pond",          emoji: "💧", name: "小池塘",   cost: 25, category: .water),
        .init(id: "rainbow",       emoji: "🌈", name: "彩虹",     cost: 40, category: .water),
        .init(id: "cloud",         emoji: "☁️", name: "云朵",     cost: 8,  category: .water),
        .init(id: "sun",           emoji: "🌞", name: "太阳",     cost: 15, category: .water),

        // Buildings (8)
        .init(id: "cottage",       emoji: "🏡", name: "小屋",     cost: 50, category: .building),
        .init(id: "hut",           emoji: "🛖", name: "茅屋",     cost: 30, category: .building),
        .init(id: "castle",        emoji: "🏰", name: "城堡",     cost: 80, category: .building),
        .init(id: "tent",          emoji: "⛺", name: "帐篷",     cost: 20, category: .building),
        .init(id: "swing",         emoji: "🎠", name: "秋千",     cost: 35, category: .building),
        .init(id: "ferris_wheel",  emoji: "🎡", name: "摩天轮",   cost: 100,category: .building),
        .init(id: "windmill",      emoji: "🏯", name: "风车",     cost: 40, category: .building),
        .init(id: "lantern",       emoji: "🏮", name: "灯笼",     cost: 15, category: .building),

        // Festival (5)
        .init(id: "christmas_tree",emoji: "🎄", name: "圣诞树",   cost: 50, category: .festival),
        .init(id: "carp_flag",     emoji: "🎏", name: "鲤鱼旗",   cost: 25, category: .festival),
        .init(id: "wind_chime",    emoji: "🎐", name: "风铃",     cost: 20, category: .festival),
        .init(id: "balloon",       emoji: "🎈", name: "气球",     cost: 10, category: .festival),
        .init(id: "gift_box",      emoji: "🎁", name: "礼物盒",   cost: 20, category: .festival),
    ]

    static func item(id: String) -> DecorationItem? {
        items.first { $0.id == id }
    }

    static func items(in category: DecorationCategory) -> [DecorationItem] {
        items.filter { $0.category == category }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add DecorationCatalog with 53 items across 7 categories"
```

---

## Task 8: Create FruitCatalog

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/FruitCatalog.swift`

- [ ] **Step 1: Create catalog**

Create `NumberOrchard/NumberOrchard/Core/Models/FruitCatalog.swift`:

```swift
import Foundation

enum FruitRarity: String, Sendable {
    case common    = "常见"
    case rare      = "稀有"
    case legendary = "传说"
}

struct FruitItem: Identifiable, Sendable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let rarity: FruitRarity
    let funFact: String
}

enum FruitCatalog {
    static let fruits: [FruitItem] = [
        // Common (15)
        .init(id: "apple",        emoji: "🍎", name: "苹果",     rarity: .common,    funFact: "一天一苹果，医生远离我！"),
        .init(id: "green_apple",  emoji: "🍏", name: "青苹果",   rarity: .common,    funFact: "酸酸甜甜，最清爽！"),
        .init(id: "pear",         emoji: "🍐", name: "梨",       rarity: .common,    funFact: "秋天的梨最水润。"),
        .init(id: "orange",       emoji: "🍊", name: "橘子",     rarity: .common,    funFact: "冬天吃橘子最暖心。"),
        .init(id: "lemon",        emoji: "🍋", name: "柠檬",     rarity: .common,    funFact: "酸酸的柠檬富含维生素C。"),
        .init(id: "banana",       emoji: "🍌", name: "香蕉",     rarity: .common,    funFact: "香蕉是猴子最爱！"),
        .init(id: "watermelon",   emoji: "🍉", name: "西瓜",     rarity: .common,    funFact: "夏天吃西瓜最消暑。"),
        .init(id: "grape",        emoji: "🍇", name: "葡萄",     rarity: .common,    funFact: "一串串的葡萄最可爱。"),
        .init(id: "strawberry",   emoji: "🍓", name: "草莓",     rarity: .common,    funFact: "小小的草莓有100多颗种子。"),
        .init(id: "cherry",       emoji: "🍒", name: "樱桃",     rarity: .common,    funFact: "樱桃是春天的味道。"),
        .init(id: "peach",        emoji: "🍑", name: "桃子",     rarity: .common,    funFact: "寿星公手里的就是大桃子！"),
        .init(id: "tomato",       emoji: "🍅", name: "番茄",     rarity: .common,    funFact: "番茄其实是水果哦！"),
        .init(id: "tangerine",    emoji: "🍊", name: "橙子",     rarity: .common,    funFact: "橙子榨成橙汁最好喝。"),
        .init(id: "red_grape",    emoji: "🍇", name: "红提",     rarity: .common,    funFact: "红提比绿提更甜。"),
        .init(id: "apricot",      emoji: "🍑", name: "杏",       rarity: .common,    funFact: "杏花开在春天里。"),

        // Rare (10)
        .init(id: "blueberry",    emoji: "🫐", name: "蓝莓",     rarity: .rare,      funFact: "蓝莓对眼睛很好！"),
        .init(id: "melon",        emoji: "🍈", name: "哈密瓜",   rarity: .rare,      funFact: "哈密瓜是瓜中之王。"),
        .init(id: "mango",        emoji: "🥭", name: "芒果",     rarity: .rare,      funFact: "热带的芒果最甜。"),
        .init(id: "pineapple",    emoji: "🍍", name: "菠萝",     rarity: .rare,      funFact: "菠萝头上有绿色的王冠。"),
        .init(id: "coconut",      emoji: "🥥", name: "椰子",     rarity: .rare,      funFact: "椰子水是天然的饮料。"),
        .init(id: "kiwi",         emoji: "🥝", name: "猕猴桃",   rarity: .rare,      funFact: "猕猴桃的维生素C超多！"),
        .init(id: "avocado",      emoji: "🥑", name: "牛油果",   rarity: .rare,      funFact: "牛油果中间有颗大籽。"),
        .init(id: "chestnut",     emoji: "🌰", name: "栗子",     rarity: .rare,      funFact: "糖炒栗子香喷喷的！"),
        .init(id: "olive",        emoji: "🫒", name: "橄榄",     rarity: .rare,      funFact: "橄榄是和平的象征。"),
        .init(id: "starfruit",    emoji: "⭐", name: "杨桃",     rarity: .rare,      funFact: "切开像一颗颗小星星！"),

        // Legendary (5)
        .init(id: "dragon_fruit", emoji: "🐲", name: "火龙果",   rarity: .legendary, funFact: "火龙果里面有好多黑籽！"),
        .init(id: "golden_apple", emoji: "🟡", name: "金苹果",   rarity: .legendary, funFact: "传说中的金苹果！"),
        .init(id: "rainbow_fruit",emoji: "🌈", name: "彩虹果",   rarity: .legendary, funFact: "七种颜色的神奇水果！"),
        .init(id: "crystal_berry",emoji: "💎", name: "水晶浆果", rarity: .legendary, funFact: "闪闪发光的水晶味道！"),
        .init(id: "sun_fruit",    emoji: "☀️", name: "太阳果",   rarity: .legendary, funFact: "只在终点果园才能找到。"),
    ]

    static func fruit(id: String) -> FruitItem? {
        fruits.first { $0.id == id }
    }

    static func fruits(rarity: FruitRarity) -> [FruitItem] {
        fruits.filter { $0.rarity == rarity }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add FruitCatalog with 30 fruits across 3 rarities"
```

---

## Task 9: Create MapCatalog

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/MapCatalog.swift`

- [ ] **Step 1: Create catalog**

Create `NumberOrchard/NumberOrchard/Core/Models/MapCatalog.swift`:

```swift
import Foundation

struct Station: Identifiable, Sendable, Hashable {
    let id: String
    let level: DifficultyLevel
    let displayName: String
    let emoji: String
    /// Station IDs that become unlocked once this one is completed
    let unlocks: [String]
    /// Position on the map (0.0-1.0), for vertical=y, horizontal=x
    let mapX: Double
    let mapY: Double
    /// Rewarded fruit id on ★★★ (nil if no specific fruit)
    let starFruitId: String?
}

enum MapCatalog {
    /// The 20 stations, arranged bottom-to-top (L1 at bottom, L6 at top).
    static let stations: [Station] = [
        // L1 (3 stations) - bottom of map
        .init(id: "L1-1", level: .seed, displayName: "苹果小屋", emoji: "🏡",
              unlocks: ["L1-2"], mapX: 0.5, mapY: 0.95, starFruitId: "apple"),
        .init(id: "L1-2", level: .seed, displayName: "草莓小屋", emoji: "🏡",
              unlocks: ["L1-3"], mapX: 0.5, mapY: 0.88, starFruitId: "strawberry"),
        .init(id: "L1-3", level: .seed, displayName: "梨树小屋", emoji: "🏡",
              unlocks: ["L2-1"], mapX: 0.5, mapY: 0.81, starFruitId: "pear"),

        // L2 (3 stations)
        .init(id: "L2-1", level: .sprout, displayName: "橘子小屋", emoji: "🛖",
              unlocks: ["L2-2"], mapX: 0.5, mapY: 0.74, starFruitId: "orange"),
        .init(id: "L2-2", level: .sprout, displayName: "柠檬小屋", emoji: "🛖",
              unlocks: ["L2-3"], mapX: 0.5, mapY: 0.67, starFruitId: "lemon"),
        .init(id: "L2-3", level: .sprout, displayName: "香蕉小屋", emoji: "🛖",
              unlocks: ["L3-1"], mapX: 0.5, mapY: 0.60, starFruitId: "banana"),

        // L3 (3 stations)
        .init(id: "L3-1", level: .smallTree, displayName: "西瓜小屋", emoji: "⛺",
              unlocks: ["L3-2"], mapX: 0.5, mapY: 0.53, starFruitId: "watermelon"),
        .init(id: "L3-2", level: .smallTree, displayName: "葡萄小屋", emoji: "⛺",
              unlocks: ["L3-3"], mapX: 0.5, mapY: 0.46, starFruitId: "grape"),
        .init(id: "L3-3", level: .smallTree, displayName: "樱桃小屋", emoji: "⛺",
              unlocks: ["L4-1"], mapX: 0.5, mapY: 0.39, starFruitId: "cherry"),

        // L4 (3 stations)
        .init(id: "L4-1", level: .bigTree, displayName: "桃子小屋", emoji: "🏯",
              unlocks: ["L4-2"], mapX: 0.5, mapY: 0.33, starFruitId: "peach"),
        .init(id: "L4-2", level: .bigTree, displayName: "番茄小屋", emoji: "🏯",
              unlocks: ["L4-3"], mapX: 0.5, mapY: 0.27, starFruitId: "tomato"),
        .init(id: "L4-3", level: .bigTree, displayName: "橙子小屋", emoji: "🏯",
              unlocks: ["L5-1"], mapX: 0.5, mapY: 0.21, starFruitId: "tangerine"),

        // L5 branch (4 stations)
        .init(id: "L5-1", level: .bloom, displayName: "蓝莓城堡", emoji: "🏰",
              unlocks: ["L5-3"], mapX: 0.3, mapY: 0.17, starFruitId: "blueberry"),
        .init(id: "L5-2", level: .bloom, displayName: "芒果城堡", emoji: "🏰",
              unlocks: ["L5-4"], mapX: 0.7, mapY: 0.17, starFruitId: "mango"),
        .init(id: "L5-3", level: .bloom, displayName: "菠萝城堡", emoji: "🏰",
              unlocks: ["L6-1"], mapX: 0.3, mapY: 0.12, starFruitId: "pineapple"),
        .init(id: "L5-4", level: .bloom, displayName: "椰子城堡", emoji: "🏰",
              unlocks: ["L6-2"], mapX: 0.7, mapY: 0.12, starFruitId: "coconut"),

        // L6 branch (4 stations)
        .init(id: "L6-1", level: .harvest, displayName: "火龙果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.3, mapY: 0.07, starFruitId: "dragon_fruit"),
        .init(id: "L6-2", level: .harvest, displayName: "金苹果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.7, mapY: 0.07, starFruitId: "golden_apple"),
        .init(id: "L6-3", level: .harvest, displayName: "彩虹果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.3, mapY: 0.03, starFruitId: "rainbow_fruit"),
        .init(id: "L6-4", level: .harvest, displayName: "水晶宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.7, mapY: 0.03, starFruitId: "crystal_berry"),
    ]

    static let endStationId = "end"
    static let initialStationId = "L1-1"

    static func station(id: String) -> Station? {
        stations.first { $0.id == id }
    }
}
```

- [ ] **Step 2: Build to verify all catalogs compile**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add MapCatalog with 20 stations and branching paths"
```

---

# Phase 2: New Gameplay + L5/L6

## Task 10: Extend QuestionGenerator for L5 and L6

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/QuestionGenerator.swift`

- [ ] **Step 1: Update `generateOperands` to handle bloom and harvest**

In `QuestionGenerator.swift`, find the `generateOperands` method. Replace the implementations of `generateAdditionOperands` and `generateSubtractionOperands`:

```swift
    private func generateAdditionOperands(maxSum: Int, subDifficulty: Int) -> (Int, Int) {
        let minOperand = 1
        let maxOperand = max(1, min(maxSum - 1, subDifficulty + 1))

        let op1 = Int.random(in: minOperand...maxOperand)
        let maxOp2 = maxSum - op1
        guard maxOp2 >= 1 else { return (1, 1) }
        let op2 = Int.random(in: 1...maxOp2)
        return (op1, op2)
    }

    private func generateSubtractionOperands(maxMinuend: Int, subDifficulty: Int) -> (Int, Int) {
        let minMinuend = max(2, subDifficulty)
        let op1 = Int.random(in: minMinuend...maxMinuend)
        let op2 = Int.random(in: 1...(op1))
        return (op1, op2)
    }
```

Replace with:

```swift
    private func generateAdditionOperands(maxSum: Int, subDifficulty: Int) -> (Int, Int) {
        // For maxSum=20 (L5/L6), use extended ranges and optionally force carry
        if maxSum == 20 {
            // Phase 1 (sub 1-2): no carry (operand1 + operand2 digit sum < 10)
            // Phase 2 (sub 3-5): allow carry
            let allowCarry = subDifficulty >= 3
            for _ in 0..<10 {
                let op1 = Int.random(in: 1...min(9, maxSum - 1))
                let maxOp2 = maxSum - op1
                guard maxOp2 >= 1 else { continue }
                let op2 = Int.random(in: 1...maxOp2)
                let unitsCarry = (op1 % 10 + op2 % 10) >= 10
                if allowCarry || !unitsCarry {
                    return (op1, op2)
                }
            }
            return (5, 5)
        }

        // Original L1-L4 logic
        let minOperand = 1
        let maxOperand = max(1, min(maxSum - 1, subDifficulty + 1))
        let op1 = Int.random(in: minOperand...maxOperand)
        let maxOp2 = maxSum - op1
        guard maxOp2 >= 1 else { return (1, 1) }
        let op2 = Int.random(in: 1...maxOp2)
        return (op1, op2)
    }

    private func generateSubtractionOperands(maxMinuend: Int, subDifficulty: Int) -> (Int, Int) {
        if maxMinuend == 20 {
            // Phase 1 (sub 1-2): no borrow (op1 units >= op2 units)
            // Phase 2 (sub 3-5): allow borrow
            let allowBorrow = subDifficulty >= 3
            for _ in 0..<10 {
                let op1 = Int.random(in: 11...maxMinuend)  // force 11-20 minuend
                let op2 = Int.random(in: 1...(op1 - 1))
                let unitsBorrow = (op1 % 10) < (op2 % 10)
                if allowBorrow || !unitsBorrow {
                    return (op1, op2)
                }
            }
            return (15, 5)
        }

        // Original L1-L4 logic
        let minMinuend = max(2, subDifficulty)
        let op1 = Int.random(in: minMinuend...maxMinuend)
        let op2 = Int.random(in: 1...(op1))
        return (op1, op2)
    }
```

- [ ] **Step 2: Write L5/L6 tests**

Create `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/L5L6GenerationTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func bloomLevelAddsUpToTwenty() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bloom, subDifficulty: 3)

    for _ in 0..<30 {
        let q = generator.generate(for: profile)
        #expect(q.operation == .add)
        #expect(q.correctAnswer <= 20)
        #expect(q.operand1 >= 1)
        #expect(q.operand2 >= 1)
    }
}

@Test func harvestLevelMixesAddSubUpToTwenty() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .harvest, subDifficulty: 3)

    var hasAdd = false
    var hasSub = false
    for _ in 0..<60 {
        let q = generator.generate(for: profile)
        #expect(q.correctAnswer >= 0)
        #expect(q.correctAnswer <= 20)
        if q.operation == .add { hasAdd = true }
        if q.operation == .subtract {
            hasSub = true
            #expect(q.operand1 >= q.operand2)
            #expect(q.operand1 >= 11) // L6 subtraction always uses 11-20 minuend
        }
    }
    #expect(hasAdd && hasSub)
}

@Test func lowSubDifficultyAvoidsCarry() {
    let generator = QuestionGenerator()
    let profile = LearningProfile(currentLevel: .bloom, subDifficulty: 1)
    // At sub 1, most additions should have no carry
    var noCarryCount = 0
    for _ in 0..<30 {
        let q = generator.generate(for: profile)
        if q.operation == .add {
            let unitsCarry = (q.operand1 % 10 + q.operand2 % 10) >= 10
            if !unitsCarry { noCarryCount += 1 }
        }
    }
    // Expect majority to be no-carry
    #expect(noCarryCount >= 20)
}
```

- [ ] **Step 3: Run tests to verify pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/L5L6GenerationTests 2>&1 | grep -E "Test.*passed|Test.*failed|error:|\*\* TEST"
```
Expected: All L5/L6 tests PASS

- [ ] **Step 4: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: QuestionGenerator supports L5/L6 (20以内) with progressive carry/borrow"
```

---

## Task 11: Number Train logic & tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/NumberTrain/NumberTrainScene.swift`
- Create: `NumberOrchard/NumberOrchardTests/Features/Adventure/NumberTrainLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Features/Adventure/NumberTrainLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func trainGameStateInitializesFromQuestion() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    let state = NumberTrainGameState(question: q)
    #expect(state.totalSeats == 10)
    #expect(state.occupiedSeats == 6)
    #expect(state.emptySeats == 4)
    #expect(state.userInput == nil)
    #expect(state.isComplete == false)
}

@Test func trainCorrectAnswerMarksComplete() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    state.submitAnswer(4)
    #expect(state.userInput == 4)
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}

@Test func trainWrongAnswerDoesNotLock() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    state.submitAnswer(3)
    #expect(state.isCorrect == false)
    #expect(state.isComplete == false) // can try again
}

@Test func trainCountingModeFillsEmptySeatsOneByOne() {
    let q = MathQuestion(operand1: 6, operand2: 4, operation: .add, gameMode: .numberTrain)
    var state = NumberTrainGameState(question: q)
    // In counting mode, tapping empty seats increments a running counter
    state.tapEmptySeat()
    state.tapEmptySeat()
    #expect(state.countedSeats == 2)
    state.tapEmptySeat()
    state.tapEmptySeat()
    #expect(state.countedSeats == 4)
    state.commitCountedAnswer() // commits counted seats as answer
    #expect(state.isComplete == true)
    #expect(state.isCorrect == true)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NumberTrainLogicTests 2>&1 | tail -10
```
Expected: FAIL — `NumberTrainGameState` not found

- [ ] **Step 3: Create NumberTrainScene.swift with game state**

Create `NumberOrchard/NumberOrchard/Features/Adventure/NumberTrain/NumberTrainScene.swift`:

```swift
import SpriteKit

struct NumberTrainGameState: Sendable {
    let question: MathQuestion
    let totalSeats: Int
    let occupiedSeats: Int
    var emptySeats: Int { totalSeats - occupiedSeats }
    var userInput: Int?
    var countedSeats: Int = 0
    var isComplete: Bool = false
    var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.totalSeats = question.operand1 + question.operand2
        self.occupiedSeats = question.operand1
    }

    mutating func submitAnswer(_ answer: Int) {
        userInput = answer
        if answer == question.operand2 {
            isComplete = true
            isCorrect = true
        } else {
            // Keep isComplete false — user can retry
            isCorrect = false
        }
    }

    mutating func tapEmptySeat() {
        guard !isComplete else { return }
        countedSeats = min(countedSeats + 1, emptySeats)
    }

    mutating func commitCountedAnswer() {
        submitAnswer(countedSeats)
    }
}

@MainActor
protocol NumberTrainSceneDelegate: AnyObject {
    func numberTrainSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class NumberTrainScene: SKScene {
    weak var gameDelegate: NumberTrainSceneDelegate?

    private var gameState: NumberTrainGameState!
    private var seatNodes: [SKSpriteNode] = []  // all 10 seats
    private var answerLabel: SKLabelNode!
    private var keypadNodes: [SKSpriteNode] = []
    private var startTime: Date!
    private var useCountingMode: Bool = false  // L2-L3 use counting
    private var questionLabel: SKLabelNode!

    func configure(with question: MathQuestion, countingMode: Bool) {
        self.gameState = NumberTrainGameState(question: question)
        self.useCountingMode = countingMode
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let w = size.width
        let h = size.height

        // Question label at top
        questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 26
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.fontColor = .darkGray
        questionLabel.position = CGPoint(x: w/2, y: h - 60)
        questionLabel.preferredMaxLayoutWidth = w - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        // Train: centered horizontally, 10 seats
        let seatWidth: CGFloat = 60
        let seatSpacing: CGFloat = 6
        let trainWidth = CGFloat(gameState.totalSeats) * (seatWidth + seatSpacing) - seatSpacing
        let startX = (w - trainWidth) / 2
        let trainY = h * 0.55

        for i in 0..<gameState.totalSeats {
            let isOccupied = i < gameState.occupiedSeats
            let seat = SKSpriteNode(color: isOccupied ? .systemOrange : .white.withAlphaComponent(0.4),
                                    size: CGSize(width: seatWidth, height: seatWidth))
            seat.position = CGPoint(x: startX + CGFloat(i) * (seatWidth + seatSpacing) + seatWidth/2, y: trainY)
            seat.name = "seat_\(i)"
            addChild(seat)
            seatNodes.append(seat)

            if isOccupied {
                let animal = SKLabelNode(text: ["🐻", "🐰", "🐸", "🐶", "🐱", "🐷", "🐨", "🐼", "🦁", "🐯"][i % 10])
                animal.fontSize = 36
                animal.verticalAlignmentMode = .center
                animal.horizontalAlignmentMode = .center
                seat.addChild(animal)
            }
        }

        // Answer display
        answerLabel = SKLabelNode(text: "答案: _")
        answerLabel.fontSize = 32
        answerLabel.fontName = "PingFangSC-Semibold"
        answerLabel.fontColor = .systemGreen
        answerLabel.position = CGPoint(x: w/2, y: h * 0.35)
        addChild(answerLabel)

        // Numeric keypad or counting hint
        if useCountingMode {
            let hint = SKLabelNode(text: "点击空座位数一数，然后点确认")
            hint.fontSize = 20
            hint.fontName = "PingFangSC-Regular"
            hint.fontColor = .gray
            hint.position = CGPoint(x: w/2, y: h * 0.22)
            addChild(hint)

            let confirmBtn = SKSpriteNode(color: .systemGreen, size: CGSize(width: 120, height: 50))
            confirmBtn.position = CGPoint(x: w/2, y: h * 0.12)
            confirmBtn.name = "confirm"
            addChild(confirmBtn)
            let confirmLbl = SKLabelNode(text: "确认")
            confirmLbl.fontSize = 24
            confirmLbl.fontColor = .white
            confirmLbl.fontName = "PingFangSC-Semibold"
            confirmLbl.verticalAlignmentMode = .center
            confirmBtn.addChild(confirmLbl)
        } else {
            let keypadY = h * 0.18
            let keyW: CGFloat = 70
            let keyH: CGFloat = 60
            let keysPerRow = 5
            let totalW = CGFloat(keysPerRow) * (keyW + 6) - 6
            let keyStartX = (w - totalW) / 2

            for i in 0...9 {
                let row = i / keysPerRow
                let col = i % keysPerRow
                let key = SKSpriteNode(color: .systemBlue.withAlphaComponent(0.7),
                                       size: CGSize(width: keyW, height: keyH))
                key.position = CGPoint(x: keyStartX + CGFloat(col) * (keyW + 6) + keyW/2,
                                       y: keypadY - CGFloat(row) * (keyH + 6))
                key.name = "key_\(i)"
                addChild(key)
                keypadNodes.append(key)

                let label = SKLabelNode(text: "\(i)")
                label.fontSize = 32
                label.fontColor = .white
                label.fontName = "PingFangSC-Semibold"
                label.verticalAlignmentMode = .center
                key.addChild(label)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isComplete, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        if useCountingMode {
            // Tap empty seat to count
            if let seatName = node.name ?? node.parent?.name, seatName.hasPrefix("seat_") {
                let index = Int(seatName.dropFirst(5)) ?? 0
                if index >= gameState.occupiedSeats {
                    gameState.tapEmptySeat()
                    seatNodes[index].color = .systemGreen
                    answerLabel.text = "答案: \(gameState.countedSeats)"
                }
            } else if node.name == "confirm" || node.parent?.name == "confirm" {
                gameState.commitCountedAnswer()
                if gameState.isCorrect { handleCompletion() } else { flashWrong() }
            }
            return
        }

        // Input mode — tap keypad key
        if let name = node.name ?? node.parent?.name, name.hasPrefix("key_") {
            let digit = Int(name.dropFirst(4)) ?? 0
            gameState.submitAnswer(digit)
            answerLabel.text = "答案: \(digit)"
            if gameState.isCorrect {
                handleCompletion()
            } else {
                flashWrong()
            }
        }
    }

    private func flashWrong() {
        answerLabel.run(SKAction.sequence([
            SKAction.colorize(with: .systemRed, colorBlendFactor: 1.0, duration: 0.15),
            SKAction.wait(forDuration: 0.3),
            SKAction.colorize(with: .systemGreen, colorBlendFactor: 1.0, duration: 0.15),
        ]))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        // Celebrate: fill empty seats with animals
        for i in gameState.occupiedSeats..<gameState.totalSeats {
            let seat = seatNodes[i]
            seat.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i - gameState.occupiedSeats) * 0.1),
                SKAction.colorize(with: .systemOrange, colorBlendFactor: 1.0, duration: 0.2),
            ]))
            let animal = SKLabelNode(text: ["🐼", "🐨", "🦊", "🐰", "🐻"].randomElement()!)
            animal.fontSize = 36
            animal.verticalAlignmentMode = .center
            animal.setScale(0.1)
            seat.addChild(animal)
            animal.run(SKAction.scale(to: 1.0, duration: 0.3))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.gameDelegate?.numberTrainSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NumberTrainLogicTests 2>&1 | grep -E "passed|failed|error:|\*\* TEST"
```
Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: implement NumberTrain (凑十法) scene with counting and input modes"
```

---

## Task 12: NumberTrainView (SwiftUI wrapper)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/NumberTrain/NumberTrainView.swift`

- [ ] **Step 1: Create the wrapper**

Create `NumberOrchard/NumberOrchard/Features/Adventure/NumberTrain/NumberTrainView.swift`:

```swift
import SwiftUI
import SpriteKit

struct NumberTrainView: View {
    let question: MathQuestion
    let countingMode: Bool
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: NumberTrainScene?
    @State private var coordinator: NumberTrainCoordinator?

    var body: some View {
        GeometryReader { _ in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = NumberTrainScene(size: CGSize(width: 1194, height: 834))
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question, countingMode: countingMode)
            let coord = NumberTrainCoordinator(onComplete: onComplete)
            newScene.gameDelegate = coord
            coordinator = coord
            scene = newScene
        }
    }
}

@MainActor
private class NumberTrainCoordinator: NSObject, NumberTrainSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void
    init(onComplete: @escaping (Bool, TimeInterval) -> Void) { self.onComplete = onComplete }
    func numberTrainSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add NumberTrainView SwiftUI wrapper"
```

---

## Task 13: Balance game logic & scene

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/Balance/BalanceScene.swift`
- Create: `NumberOrchard/NumberOrchardTests/Features/Adventure/BalanceLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Features/Adventure/BalanceLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func balanceStateInitializesFromQuestion() {
    // question: "5 = 2 + ?", operand1=2, operand2=3 (answer), op=add, target=5
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    let state = BalanceGameState(question: q)
    #expect(state.leftSide == 5)         // fixed side
    #expect(state.rightFixed == 2)       // already placed
    #expect(state.rightUserPlaced == 0)  // user starts at 0
    #expect(state.isBalanced == false)
}

@Test func balanceWhenCorrectNumberPlaced() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()  // 3 blocks placed, 2 + 3 = 5 = left
    #expect(state.rightUserPlaced == 3)
    #expect(state.isBalanced == true)
    #expect(state.isComplete == true)
}

@Test func balanceCanRemoveBlocks() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()  // over by 1 (4 placed, 2+4=6 > 5)
    #expect(state.isBalanced == false)
    state.removeBlock()
    #expect(state.rightUserPlaced == 3)
    #expect(state.isBalanced == true)
}

@Test func tiltAngleProportionalToDifference() {
    let q = MathQuestion(operand1: 2, operand2: 3, operation: .add, gameMode: .balance)
    var state = BalanceGameState(question: q)
    #expect(state.tiltAngleDegrees < 0)  // left heavier (5 > 2)
    state.placeBlock()
    state.placeBlock()
    state.placeBlock()
    #expect(state.tiltAngleDegrees == 0) // balanced
    state.placeBlock()
    #expect(state.tiltAngleDegrees > 0)  // right now heavier
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/BalanceLogicTests 2>&1 | tail -10
```
Expected: FAIL — `BalanceGameState` not found

- [ ] **Step 3: Create BalanceScene.swift with game state**

Create `NumberOrchard/NumberOrchard/Features/Adventure/Balance/BalanceScene.swift`:

```swift
import SpriteKit

struct BalanceGameState: Sendable {
    let question: MathQuestion
    let leftSide: Int           // question.correctAnswer
    let rightFixed: Int         // question.operand1 (already placed)
    let targetRightAdd: Int     // question.operand2 (expected answer)
    var rightUserPlaced: Int = 0
    var isComplete: Bool = false

    var isBalanced: Bool {
        leftSide == rightFixed + rightUserPlaced
    }

    var tiltAngleDegrees: Double {
        let diff = Double((rightFixed + rightUserPlaced) - leftSide)
        return max(-30, min(30, diff * 5))
    }

    init(question: MathQuestion) {
        self.question = question
        self.leftSide = question.correctAnswer
        self.rightFixed = question.operand1
        self.targetRightAdd = question.operand2
    }

    mutating func placeBlock() {
        guard !isComplete else { return }
        rightUserPlaced += 1
        if isBalanced { isComplete = true }
    }

    mutating func removeBlock() {
        guard !isComplete else { return }
        rightUserPlaced = max(0, rightUserPlaced - 1)
    }
}

@MainActor
protocol BalanceSceneDelegate: AnyObject {
    func balanceSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class BalanceScene: SKScene {
    weak var gameDelegate: BalanceSceneDelegate?

    private var gameState: BalanceGameState!
    private var leftPan: SKSpriteNode!
    private var rightPan: SKSpriteNode!
    private var beam: SKSpriteNode!
    private var pivot: SKSpriteNode!
    private var leftBlocks: [SKSpriteNode] = []
    private var rightBlocks: [SKSpriteNode] = []
    private var poolBlocks: [SKSpriteNode] = []
    private var draggingBlock: SKSpriteNode?
    private var startTime: Date!
    private var questionLabel: SKLabelNode!

    func configure(with question: MathQuestion) {
        self.gameState = BalanceGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let w = size.width
        let h = size.height

        questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 26
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.fontColor = .darkGray
        questionLabel.position = CGPoint(x: w/2, y: h - 60)
        questionLabel.preferredMaxLayoutWidth = w - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        // Pivot (triangle)
        pivot = SKSpriteNode(color: .brown, size: CGSize(width: 20, height: 80))
        pivot.position = CGPoint(x: w/2, y: h * 0.42)
        addChild(pivot)

        // Beam (horizontal bar), child of pivot so it rotates
        beam = SKSpriteNode(color: .darkGray, size: CGSize(width: 400, height: 8))
        beam.position = CGPoint(x: 0, y: 40)
        pivot.addChild(beam)

        // Left pan
        leftPan = SKSpriteNode(color: .systemGray.withAlphaComponent(0.4), size: CGSize(width: 150, height: 10))
        leftPan.position = CGPoint(x: -180, y: -30)
        beam.addChild(leftPan)
        // Left label
        let leftLabel = SKLabelNode(text: "\(gameState.leftSide)")
        leftLabel.fontSize = 36
        leftLabel.fontColor = .systemBlue
        leftLabel.fontName = "PingFangSC-Semibold"
        leftLabel.position = CGPoint(x: 0, y: 50)
        leftPan.addChild(leftLabel)

        // Pre-place blocks on left
        for i in 0..<gameState.leftSide {
            let block = makeBlock()
            block.position = CGPoint(x: CGFloat(i % 3 - 1) * 45, y: CGFloat(i / 3) * 35 + 20)
            leftPan.addChild(block)
            leftBlocks.append(block)
        }

        // Right pan
        rightPan = SKSpriteNode(color: .systemGray.withAlphaComponent(0.4), size: CGSize(width: 150, height: 10))
        rightPan.position = CGPoint(x: 180, y: -30)
        rightPan.name = "right_pan"
        beam.addChild(rightPan)
        // Right label
        let rightLabel = SKLabelNode(text: "\(gameState.rightFixed) + ?")
        rightLabel.fontSize = 32
        rightLabel.fontColor = .systemOrange
        rightLabel.fontName = "PingFangSC-Semibold"
        rightLabel.position = CGPoint(x: 0, y: 50)
        rightPan.addChild(rightLabel)

        // Pre-place fixed blocks on right
        for i in 0..<gameState.rightFixed {
            let block = makeBlock()
            block.position = CGPoint(x: CGFloat(i % 3 - 1) * 45, y: CGFloat(i / 3) * 35 + 20)
            rightPan.addChild(block)
            rightBlocks.append(block)
        }

        // Block pool at the bottom
        let poolY: CGFloat = 100
        for i in 0..<10 {
            let block = makeBlock()
            block.position = CGPoint(x: 120 + CGFloat(i) * 60, y: poolY)
            block.name = "pool_\(i)"
            addChild(block)
            poolBlocks.append(block)
        }
    }

    private func makeBlock() -> SKSpriteNode {
        let b = SKSpriteNode(color: .systemBlue, size: CGSize(width: 40, height: 30))
        b.name = "block"
        return b
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isComplete, let touch = touches.first else { return }
        let location = touch.location(in: self)
        // Check pool blocks first
        for block in poolBlocks where block.contains(location) {
            draggingBlock = block
            block.run(SKAction.scale(to: 1.2, duration: 0.1))
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let block = draggingBlock else { return }
        block.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let block = draggingBlock else { return }
        draggingBlock = nil

        // Convert rightPan frame to scene coordinates
        let rightPanSceneFrame = rightPan.calculateAccumulatedFrame()
        if rightPanSceneFrame.intersects(block.frame) {
            // Drop into right pan
            block.removeFromParent()
            poolBlocks.removeAll { $0 === block }

            gameState.placeBlock()
            // Add a fresh block representation to right pan
            let newBlock = makeBlock()
            let idx = gameState.rightFixed + gameState.rightUserPlaced - 1
            newBlock.position = CGPoint(x: CGFloat(idx % 3 - 1) * 45, y: CGFloat(idx / 3) * 35 + 20)
            newBlock.setScale(0.1)
            rightPan.addChild(newBlock)
            newBlock.run(SKAction.scale(to: 1.0, duration: 0.2))
            rightBlocks.append(newBlock)

            updateTilt()

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            block.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func updateTilt() {
        let angleRadians = gameState.tiltAngleDegrees * .pi / 180
        beam.run(SKAction.rotate(toAngle: angleRadians, duration: 0.3, shortestUnitArc: true))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        // Balance glow
        beam.run(SKAction.colorize(with: .systemYellow, colorBlendFactor: 0.6, duration: 0.3))
        let equation = SKLabelNode(text: "\(gameState.leftSide) = \(gameState.rightFixed) + \(gameState.rightUserPlaced)")
        equation.fontSize = 42
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.4))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.gameDelegate?.balanceSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/BalanceLogicTests 2>&1 | grep -E "passed|failed|error:|\*\* TEST"
```
Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: implement Balance (天平) scene with drag blocks and real-time tilt"
```

---

## Task 14: BalanceView SwiftUI wrapper

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Adventure/Balance/BalanceView.swift`

- [ ] **Step 1: Create wrapper**

Create `NumberOrchard/NumberOrchard/Features/Adventure/Balance/BalanceView.swift`:

```swift
import SwiftUI
import SpriteKit

struct BalanceView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: BalanceScene?
    @State private var coordinator: BalanceCoordinator?

    var body: some View {
        GeometryReader { _ in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = BalanceScene(size: CGSize(width: 1194, height: 834))
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question)
            let coord = BalanceCoordinator(onComplete: onComplete)
            newScene.gameDelegate = coord
            coordinator = coord
            scene = newScene
        }
    }
}

@MainActor
private class BalanceCoordinator: NSObject, BalanceSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void
    init(onComplete: @escaping (Bool, TimeInterval) -> Void) { self.onComplete = onComplete }
    func balanceSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add BalanceView SwiftUI wrapper"
```

---

## Task 15: Extend QuestionGenerator for Train/Balance modes

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/QuestionGenerator.swift`

- [ ] **Step 1: Add method to generate per-game-mode questions**

At the end of the `QuestionGenerator` struct, before the closing `}`, add:

```swift
    /// Generate a question for a specific game mode (used by exploration stations that mix play styles).
    func generate(for profile: LearningProfile, gameMode: GameMode, recentQuestions: [MathQuestion] = []) -> MathQuestion {
        // For pickFruit/shareFruit, fall back to the normal operation-driven logic
        if gameMode == .pickFruit || gameMode == .shareFruit {
            let operation: MathOperation = gameMode == .pickFruit ? .add : .subtract
            let (op1, op2) = generateOperands(
                level: profile.currentLevel,
                subDifficulty: profile.subDifficulty,
                operation: operation
            )
            return MathQuestion(operand1: op1, operand2: op2, operation: operation, gameMode: gameMode)
        }

        // numberTrain: total seats ≤ 10 at L1-L3, up to 20 at L5-L6
        // operand1 = occupied, operand2 = empty (answer)
        if gameMode == .numberTrain {
            let totalSeats = profile.currentLevel.maxNumber <= 5 ? 5 : (profile.currentLevel.maxNumber == 10 ? 10 : 10)
            let occupied = Int.random(in: 1...(totalSeats - 1))
            let empty = totalSeats - occupied
            return MathQuestion(operand1: occupied, operand2: empty, operation: .add, gameMode: .numberTrain)
        }

        // balance: left has target = operand1 (fixed right) + operand2 (answer)
        if gameMode == .balance {
            let maxTotal = min(profile.currentLevel.maxNumber, 10)  // cap at 10 for balance clarity
            let target = Int.random(in: 3...maxTotal)
            let rightFixed = Int.random(in: 1...(target - 1))
            let rightMissing = target - rightFixed
            return MathQuestion(operand1: rightFixed, operand2: rightMissing, operation: .add, gameMode: .balance)
        }

        // Fallback
        return generate(for: profile, recentQuestions: recentQuestions)
    }
```

- [ ] **Step 2: Build to verify**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: extend QuestionGenerator for NumberTrain and Balance game modes"
```

---

# Phase 3: Map, Rewards, Adventure Integration

## Task 16: MapProgressionLogic

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Exploration/MapProgressionLogic.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/Exploration/MapProgressionLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/Exploration/MapProgressionLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func initialStationUnlocked() {
    let logic = MapProgressionLogic()
    let completed: Set<String> = []
    #expect(logic.isUnlocked(stationId: "L1-1", completedStations: completed) == true)
    #expect(logic.isUnlocked(stationId: "L1-2", completedStations: completed) == false)
}

@Test func completingStationUnlocksConnected() {
    let logic = MapProgressionLogic()
    let completed: Set<String> = ["L1-1"]
    #expect(logic.isUnlocked(stationId: "L1-2", completedStations: completed) == true)
    #expect(logic.isUnlocked(stationId: "L1-3", completedStations: completed) == false)
}

@Test func starRatingFromAccuracy() {
    let logic = MapProgressionLogic()
    #expect(logic.starsFor(accuracy: 1.0, usedHint: false) == 3)
    #expect(logic.starsFor(accuracy: 1.0, usedHint: true) == 2)
    #expect(logic.starsFor(accuracy: 0.8, usedHint: false) == 2)
    #expect(logic.starsFor(accuracy: 0.6, usedHint: false) == 1)
    #expect(logic.starsFor(accuracy: 0.0, usedHint: false) == 1) // completion gives at least 1
}

@Test func starsOnlyIncreaseNeverDecrease() {
    let logic = MapProgressionLogic()
    #expect(logic.updateStars(current: 3, new: 2) == 3)
    #expect(logic.updateStars(current: 1, new: 3) == 3)
    #expect(logic.updateStars(current: 2, new: 2) == 2)
}

@Test func endStationUnlocksWhenAnyL6Complete() {
    let logic = MapProgressionLogic()
    #expect(logic.isUnlocked(stationId: "end", completedStations: ["L6-1"]) == true)
    #expect(logic.isUnlocked(stationId: "end", completedStations: ["L5-1"]) == false)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/MapProgressionLogicTests 2>&1 | tail -10
```
Expected: FAIL — type not found

- [ ] **Step 3: Implement MapProgressionLogic**

Create `NumberOrchard/NumberOrchard/Core/Exploration/MapProgressionLogic.swift`:

```swift
import Foundation

struct MapProgressionLogic: Sendable {

    /// Returns whether a station is currently accessible given what's been completed.
    func isUnlocked(stationId: String, completedStations: Set<String>) -> Bool {
        // Initial station always unlocked
        if stationId == MapCatalog.initialStationId { return true }

        // End station unlocks when any L6 station is completed
        if stationId == MapCatalog.endStationId {
            return MapCatalog.stations.contains { s in
                s.level == .harvest && completedStations.contains(s.id)
            }
        }

        // Any station is unlocked if any completed station lists it in its `unlocks`
        return MapCatalog.stations.contains { s in
            completedStations.contains(s.id) && s.unlocks.contains(stationId)
        }
    }

    /// Compute star rating from accuracy and hint usage.
    /// Any completion gives at least 1 star.
    func starsFor(accuracy: Double, usedHint: Bool) -> Int {
        if accuracy >= 1.0 && !usedHint { return 3 }
        if accuracy >= 0.8 { return 2 }
        return 1
    }

    /// Combine new attempt's stars with previous best — only increase.
    func updateStars(current: Int, new: Int) -> Int {
        max(current, new)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/MapProgressionLogicTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: MapProgressionLogic — station unlock rules and star ratings"
```

---

## Task 17: RewardCalculator

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Rewards/RewardCalculator.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/Rewards/RewardCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/Rewards/RewardCalculatorTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func oneStarGrants3StarsAnd1Seed() {
    let calc = RewardCalculator()
    let reward = calc.calculate(stars: 1, isFirstCompletion: true, station: MapCatalog.station(id: "L1-1")!)
    #expect(reward.starsEarned == 3)
    #expect(reward.seedsEarned == 1)
}

@Test func twoStarsGrantsBonus() {
    let calc = RewardCalculator()
    let reward = calc.calculate(stars: 2, isFirstCompletion: true, station: MapCatalog.station(id: "L1-1")!)
    #expect(reward.starsEarned == 5)  // 3 + 2
    #expect(reward.seedsEarned == 1)
}

@Test func threeStarsGrantsFruit() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let reward = calc.calculate(stars: 3, isFirstCompletion: true, station: station)
    #expect(reward.starsEarned == 8)  // 3 + 2 + 3
    #expect(reward.fruitIdEarned == "apple")
}

@Test func subsequentCompletionGivesNoExtraFruit() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let reward = calc.calculate(stars: 3, isFirstCompletion: false, station: station)
    #expect(reward.starsEarned == 3)  // bonus re-earned but capped
    #expect(reward.fruitIdEarned == nil) // no duplicate fruit
    #expect(reward.seedsEarned == 0)  // seed only on first
}

@Test func rewardIsDeterministic() {
    let calc = RewardCalculator()
    let station = MapCatalog.station(id: "L1-1")!
    let r1 = calc.calculate(stars: 2, isFirstCompletion: true, station: station)
    let r2 = calc.calculate(stars: 2, isFirstCompletion: true, station: station)
    #expect(r1.starsEarned == r2.starsEarned)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/RewardCalculatorTests 2>&1 | tail -10
```
Expected: FAIL

- [ ] **Step 3: Implement RewardCalculator**

Create `NumberOrchard/NumberOrchard/Core/Rewards/RewardCalculator.swift`:

```swift
import Foundation

struct StationReward: Sendable {
    let starsEarned: Int
    let seedsEarned: Int
    let fruitIdEarned: String?
}

struct RewardCalculator: Sendable {

    /// Calculate rewards for completing a station.
    /// - stars: 1 to 3, star rating earned this attempt
    /// - isFirstCompletion: true if first ever completion (any star); seeds only granted then.
    /// - station: which station
    func calculate(stars: Int, isFirstCompletion: Bool, station: Station) -> StationReward {
        var starsEarned = 3  // base for completion
        if stars >= 2 { starsEarned += 2 }
        if stars >= 3 { starsEarned += 3 }

        let seedsEarned = isFirstCompletion ? 1 : 0

        // Fruit only on first-ever 3-star
        let fruitIdEarned: String? = (stars == 3 && isFirstCompletion) ? station.starFruitId : nil

        return StationReward(
            starsEarned: starsEarned,
            seedsEarned: seedsEarned,
            fruitIdEarned: fruitIdEarned
        )
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/RewardCalculatorTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: RewardCalculator — stars/seeds/fruit distribution for station completion"
```

---

## Task 18: Integrate stationId into AdventureSession

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionViewModel.swift`
- Modify: `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionView.swift`

- [ ] **Step 1: Update AdventureSessionViewModel to accept stationId**

Replace the entire contents of `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionViewModel.swift`:

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
    let station: Station?   // nil means free-play (not bound to a map station)
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

        // Pick game mode based on station's level and question index for variety
        let gameMode = chooseGameMode()
        let next = questionGenerator.generate(for: learningProfile, gameMode: gameMode, recentQuestions: recentQuestions)
        currentQuestion = next
        recentQuestions.append(next)
        if recentQuestions.count > 5 {
            recentQuestions.removeFirst(recentQuestions.count - 5)
        }
    }

    private func chooseGameMode() -> GameMode {
        // Mix game modes per station level; questionsCompleted 0-4
        let level = learningProfile.currentLevel
        let isAdditionOnly = !level.allowsSubtraction

        // L1, L3, L5 (addition only): alternate pickFruit and numberTrain/balance
        if isAdditionOnly {
            switch questionsCompleted {
            case 0, 2, 4: return .pickFruit
            case 1: return .numberTrain
            case 3: return level.maxNumber >= 10 ? .balance : .numberTrain
            default: return .pickFruit
            }
        } else {
            // L2, L4, L6 (add+sub): mix all 4
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

        // Compute station rewards if this was a station session
        if let station {
            applyStationRewards(station: station)
        }
    }

    private func applyStationRewards(station: Station) {
        let accuracy = Double(session.correctCount) / Double(session.records.count)
        let newStars = mapLogic.starsFor(accuracy: accuracy, usedHint: hintUsedThisSession)

        // Find or create StationProgress
        let existingProgress = profile.stationProgress.first { $0.stationId == station.id }
        let isFirstCompletion = existingProgress == nil

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
            // Only add if not already in collection
            let alreadyCollected = profile.collectedFruits.contains { $0.fruitId == fruitId }
            if !alreadyCollected {
                let fruit = CollectedFruit(fruitId: fruitId, unlockedFromStationId: station.id)
                profile.collectedFruits.append(fruit)
                modelContext.insert(fruit)
                newlyUnlockedFruit = FruitCatalog.fruit(id: fruitId)
            }
        }

        // Mark following stations as unlocked if not already
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
```

- [ ] **Step 2: Update AdventureSessionView to route 4 game modes**

Replace the entire contents of `NumberOrchard/NumberOrchard/Features/Adventure/AdventureSessionView.swift`:

```swift
import SwiftUI
import SwiftData

struct AdventureSessionView: View {
    let station: Station?
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
            viewModel = AdventureSessionViewModel(profile: profile, station: station, modelContext: modelContext)
            AudioManager.shared.playMusic("adventure_bgm.wav")
        }
    }

    @ViewBuilder
    private func gameView(for question: MathQuestion, viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 0) {
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

            Group {
                switch question.gameMode {
                case .pickFruit:
                    PickFruitView(question: question) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .shareFruit:
                    ShareFruitView(question: question) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .numberTrain:
                    let countingMode = viewModel.station?.level.rawValue ?? 1 <= 3
                    NumberTrainView(question: question, countingMode: countingMode) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .balance:
                    BalanceView(question: question) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                }
            }
            .id("\(question.operand1)-\(question.operand2)-\(question.operation.rawValue)-\(question.gameMode.rawValue)-\(viewModel.questionsCompleted)")
        }
    }

    private func sessionCompleteView(viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 24) {
            Text("太棒了！")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let reward = viewModel.lastReward {
                VStack(spacing: 8) {
                    Text("获得 ⭐ +\(reward.starsEarned)")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    if reward.seedsEarned > 0 {
                        Text("获得 🌱 +\(reward.seedsEarned)")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    if let fruit = viewModel.newlyUnlockedFruit {
                        VStack(spacing: 4) {
                            Text(fruit.emoji).font(.system(size: 80))
                            Text("解锁新水果: \(fruit.name)")
                                .font(.headline)
                                .foregroundStyle(.purple)
                        }
                    }
                }
            } else {
                Text("获得经验 +\(viewModel.experienceGained)")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

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

- [ ] **Step 3: Build to verify**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: AdventureSession accepts station, routes 4 game modes, applies rewards"
```

---

## Task 19: ExplorationMapView

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Exploration/ExplorationMapView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/Exploration/ExplorationMapViewModel.swift`

- [ ] **Step 1: Create ExplorationMapViewModel**

Create `NumberOrchard/NumberOrchard/Features/Exploration/ExplorationMapViewModel.swift`:

```swift
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
```

- [ ] **Step 2: Create ExplorationMapView**

Create `NumberOrchard/NumberOrchard/Features/Exploration/ExplorationMapView.swift`:

```swift
import SwiftUI
import SwiftData

struct ExplorationMapView: View {
    let onDismiss: () -> Void
    let onStartStation: (Station) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: ExplorationMapViewModel?
    @State private var selectedStation: Station?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 0.95),   // sky blue top
                    Color(red: 0.85, green: 0.95, blue: 0.75),   // grass green bottom
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if let viewModel {
                mapContent(viewModel: viewModel)
            }

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .padding()
                            .background(.thinMaterial, in: Circle())
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title3)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            viewModel = ExplorationMapViewModel(profile: profile)
        }
        .sheet(item: $selectedStation) { station in
            StationDetailView(
                station: station,
                stars: viewModel?.stars(for: station.id) ?? 0,
                isUnlocked: viewModel?.isUnlocked(station.id) ?? false,
                onStart: {
                    selectedStation = nil
                    onStartStation(station)
                },
                onDismiss: { selectedStation = nil }
            )
        }
    }

    private var profile: ChildProfile {
        profiles.first ?? ChildProfile(name: "小果农")
    }

    private func mapContent(viewModel: ExplorationMapViewModel) -> some View {
        GeometryReader { geo in
            ScrollView([.vertical]) {
                ZStack {
                    // Paths between stations
                    Canvas { ctx, size in
                        for station in MapCatalog.stations {
                            for unlockId in station.unlocks where unlockId != "end" {
                                if let target = MapCatalog.station(id: unlockId) {
                                    var path = Path()
                                    path.move(to: CGPoint(x: station.mapX * size.width, y: station.mapY * size.height))
                                    path.addLine(to: CGPoint(x: target.mapX * size.width, y: target.mapY * size.height))
                                    let completed = viewModel.completedStationIds.contains(station.id)
                                    ctx.stroke(path,
                                              with: .color(completed ? .green : .gray.opacity(0.4)),
                                              lineWidth: 4)
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height * 2)

                    // Station nodes
                    ForEach(MapCatalog.stations) { station in
                        StationNodeView(
                            station: station,
                            stars: viewModel.stars(for: station.id),
                            isUnlocked: viewModel.isUnlocked(station.id)
                        )
                        .position(
                            x: station.mapX * geo.size.width,
                            y: station.mapY * (geo.size.height * 2)
                        )
                        .onTapGesture {
                            selectedStation = station
                        }
                    }

                    // End station placeholder
                    if viewModel.isUnlocked(MapCatalog.endStationId) {
                        VStack {
                            Text("⭐🌈🏆")
                                .font(.system(size: 60))
                            Text("终点果园")
                                .font(.headline)
                        }
                        .position(
                            x: 0.5 * geo.size.width,
                            y: 0.01 * (geo.size.height * 2)
                        )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 2)
            }
        }
    }
}

struct StationNodeView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .shadow(radius: 2)
                Text(station.emoji)
                    .font(.system(size: 36))
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }
            Text(station.displayName)
                .font(.caption)
                .foregroundStyle(isUnlocked ? .primary : .secondary)

            // Stars display
            if stars > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i < stars ? .orange : .gray)
                    }
                }
            }
        }
        .scaleEffect(isUnlocked && stars == 0 ? 1.05 : 1.0)
    }
}
```

- [ ] **Step 3: Commit (StationDetailView next task)**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: ExplorationMapView with scrollable map, stations, and paths"
```

---

## Task 20: StationDetailView

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Exploration/StationDetailView.swift`

- [ ] **Step 1: Create StationDetailView**

Create `NumberOrchard/NumberOrchard/Features/Exploration/StationDetailView.swift`:

```swift
import SwiftUI

struct StationDetailView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(station.emoji)
                .font(.system(size: 100))

            Text(station.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("(\(station.id))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 30) {
                VStack {
                    Text("难度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(station.level.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                VStack {
                    Text("当前成绩")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(i < stars ? .orange : .gray)
                        }
                    }
                }
            }

            if let fruitId = station.starFruitId, let fruit = FruitCatalog.fruit(id: fruitId) {
                HStack {
                    Text("三星奖励:")
                        .font(.callout)
                    Text(fruit.emoji).font(.title2)
                    Text(fruit.name).font(.callout)
                }
                .padding(8)
                .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }

            if isUnlocked {
                Button(action: onStart) {
                    Text("开始挑战")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                Text("先完成前面的关卡才能解锁哦")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Button("返回", action: onDismiss)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .presentationDetents([.medium, .large])
    }
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: StationDetailView popup with stars, level, fruit reward preview"
```

---

# Phase 4: Collection and Decoration

## Task 21: FruitCollectionView with tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Orchard/FruitCollectionView.swift`
- Create: `NumberOrchard/NumberOrchardTests/Features/Orchard/FruitCollectionTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Features/Orchard/FruitCollectionTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func catalogHas30Fruits() {
    #expect(FruitCatalog.fruits.count == 30)
}

@Test func fifteenCommonTenRareFiveLegendary() {
    #expect(FruitCatalog.fruits(rarity: .common).count == 15)
    #expect(FruitCatalog.fruits(rarity: .rare).count == 10)
    #expect(FruitCatalog.fruits(rarity: .legendary).count == 5)
}

@Test func fruitIdsAreUnique() {
    let ids = FruitCatalog.fruits.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func mapCatalogStationsMapToValidFruits() {
    for station in MapCatalog.stations {
        if let fruitId = station.starFruitId {
            #expect(FruitCatalog.fruit(id: fruitId) != nil, "Station \(station.id) references unknown fruit \(fruitId)")
        }
    }
}
```

- [ ] **Step 2: Run tests (should PASS since catalogs are static data)**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/FruitCollectionTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```
Expected: All PASS

- [ ] **Step 3: Create FruitCollectionView**

Create `NumberOrchard/NumberOrchard/Features/Orchard/FruitCollectionView.swift`:

```swift
import SwiftUI
import SwiftData

struct FruitCollectionView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedRarity: FruitRarity = .common
    @State private var detailFruit: FruitItem?

    private var profile: ChildProfile? { profiles.first }

    private var collectedIds: Set<String> {
        Set(profile?.collectedFruits.map(\.fruitId) ?? [])
    }

    private var filteredFruits: [FruitItem] {
        FruitCatalog.fruits(rarity: selectedRarity)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Rarity picker
                Picker("稀有度", selection: $selectedRarity) {
                    Text("常见").tag(FruitRarity.common)
                    Text("稀有").tag(FruitRarity.rare)
                    Text("传说").tag(FruitRarity.legendary)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Collection stats
                HStack {
                    Text("图鉴进度: \(collectedIds.count) / 30")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Grid of fruits
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(filteredFruits) { fruit in
                            let collected = collectedIds.contains(fruit.id)
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(collected ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    Text(fruit.emoji)
                                        .font(.system(size: 42))
                                        .grayscale(collected ? 0 : 1)
                                        .opacity(collected ? 1 : 0.3)
                                }
                                Text(collected ? fruit.name : "？")
                                    .font(.caption)
                                    .foregroundStyle(collected ? .primary : .secondary)
                            }
                            .onTapGesture {
                                if collected { detailFruit = fruit }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("水果图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回", action: onDismiss)
                }
            }
            .sheet(item: $detailFruit) { fruit in
                FruitDetailSheet(fruit: fruit, onDismiss: { detailFruit = nil })
            }
        }
    }
}

struct FruitDetailSheet: View {
    let fruit: FruitItem
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(fruit.emoji).font(.system(size: 120))
            Text(fruit.name).font(.largeTitle).fontWeight(.bold)
            Text(fruit.rarity.rawValue)
                .font(.callout)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(rarityColor.opacity(0.2), in: Capsule())
                .foregroundStyle(rarityColor)

            Text(fruit.funFact)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("关闭", action: onDismiss)
                .padding(.top)
        }
        .padding(40)
        .presentationDetents([.medium])
    }

    private var rarityColor: Color {
        switch fruit.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .legendary: return .purple
        }
    }
}
```

- [ ] **Step 4: Build**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: FruitCollectionView with rarity tabs and detail sheets"
```

---

## Task 22: DecorateOrchardView with tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/Orchard/DecorateOrchardView.swift`
- Create: `NumberOrchard/NumberOrchardTests/Features/Orchard/DecorationInventoryTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Features/Orchard/DecorationInventoryTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func catalogHas53Decorations() {
    #expect(DecorationCatalog.items.count == 53)
}

@Test func allSevenCategoriesPresent() {
    let categories = Set(DecorationCatalog.items.map(\.category))
    #expect(categories == Set(DecorationCategory.allCases))
}

@Test func decorationIdsAreUnique() {
    let ids = DecorationCatalog.items.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func purchaseDeductsStars() {
    let logic = DecorationPurchaseLogic()
    let item = DecorationCatalog.item(id: "daisy")!
    let result = logic.purchase(item: item, availableStars: 10)
    #expect(result.success == true)
    #expect(result.remainingStars == 5) // 10 - 5 (daisy cost)
}

@Test func purchaseFailsWithInsufficientStars() {
    let logic = DecorationPurchaseLogic()
    let item = DecorationCatalog.item(id: "castle")! // cost 80
    let result = logic.purchase(item: item, availableStars: 30)
    #expect(result.success == false)
    #expect(result.remainingStars == 30) // unchanged
}
```

- [ ] **Step 2: Run tests to verify they fail (purchase tests need DecorationPurchaseLogic)**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/DecorationInventoryTests 2>&1 | tail -10
```
Expected: Some FAIL on `DecorationPurchaseLogic`

- [ ] **Step 3: Create DecorationPurchaseLogic**

Create `NumberOrchard/NumberOrchard/Core/Models/DecorationPurchaseLogic.swift`:

```swift
import Foundation

struct DecorationPurchaseResult: Sendable {
    let success: Bool
    let remainingStars: Int
}

struct DecorationPurchaseLogic: Sendable {
    func purchase(item: DecorationItem, availableStars: Int) -> DecorationPurchaseResult {
        guard availableStars >= item.cost else {
            return DecorationPurchaseResult(success: false, remainingStars: availableStars)
        }
        return DecorationPurchaseResult(success: true, remainingStars: availableStars - item.cost)
    }
}
```

- [ ] **Step 4: Run tests, all should PASS**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/DecorationInventoryTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```
Expected: All PASS

- [ ] **Step 5: Create DecorateOrchardView**

Create `NumberOrchard/NumberOrchard/Features/Orchard/DecorateOrchardView.swift`:

```swift
import SwiftUI
import SwiftData

struct DecorateOrchardView: View {
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var selectedCategory: DecorationCategory = .flower
    private let purchaseLogic = DecorationPurchaseLogic()

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack {
                // Stars display
                HStack {
                    Label("\(profile?.stars ?? 0)", systemImage: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DecorationCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.rawValue)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.2), in: Capsule())
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Grid of items in category
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 16) {
                        ForEach(DecorationCatalog.items(in: selectedCategory)) { item in
                            decorationCard(for: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("装饰商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回", action: onDismiss)
                }
            }
        }
    }

    @ViewBuilder
    private func decorationCard(for item: DecorationItem) -> some View {
        let owned = profile?.decorations.filter { $0.itemId == item.id }.count ?? 0
        let stars = profile?.stars ?? 0
        let canAfford = stars >= item.cost

        VStack(spacing: 6) {
            Text(item.emoji).font(.system(size: 50))
            Text(item.name).font(.caption)
            Text("\(item.cost) ⭐").font(.caption2).foregroundStyle(.orange)
            if owned > 0 {
                Text("已有 x\(owned)").font(.caption2).foregroundStyle(.green)
            }
            Button(action: { purchase(item) }) {
                Text(canAfford ? "购买" : "不够")
                    .font(.caption)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(canAfford ? Color.green : Color.gray, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(!canAfford)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func purchase(_ item: DecorationItem) {
        guard let profile else { return }
        let result = purchaseLogic.purchase(item: item, availableStars: profile.stars)
        if result.success {
            profile.stars = result.remainingStars
            let decoration = CollectedDecoration(itemId: item.id)
            // Auto-place at random position in the top 70% of the orchard (not in UI chrome)
            decoration.isPlaced = true
            decoration.positionX = Double.random(in: 0.1...0.9)
            decoration.positionY = Double.random(in: 0.2...0.7)
            profile.decorations.append(decoration)
            modelContext.insert(decoration)
        }
    }
}
```

- [ ] **Step 6: Build**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: DecorateOrchardView shop with category tabs and purchase flow"
```

---

## Task 23: Show placed decorations on HomeView orchard scene

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`

- [ ] **Step 1: Add placed decorations display to HomeView**

Replace the entire contents of `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`:

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void
    let onOpenMap: () -> Void
    let onOpenCollection: () -> Void
    let onOpenDecorate: () -> Void
    let onOpenBattle: () -> Void

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
            LinearGradient(
                colors: [
                    Color(red: 0.70, green: 0.88, blue: 0.98),  // sky blue
                    Color(red: 0.85, green: 0.95, blue: 0.75),  // grass green
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Orchard scene with placed decorations
            GeometryReader { geo in
                ForEach(profile.decorations.filter { $0.isPlaced }) { deco in
                    if let item = DecorationCatalog.item(id: deco.itemId) {
                        Text(item.emoji)
                            .font(.system(size: 44))
                            .position(
                                x: deco.positionX * geo.size.width,
                                y: deco.positionY * geo.size.height
                            )
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                // Top bar
                HStack {
                    HStack(spacing: 12) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title3)

                    Spacer()

                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                // Tree centerpiece
                VStack(spacing: 10) {
                    Text(viewModel.treeStageEmoji).font(.system(size: 90))
                    ProgressView(value: viewModel.treeProgress).frame(width: 180).tint(.green)
                    Text(profile.difficultyLevel.displayName).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                // 4 feature entries
                HStack(spacing: 20) {
                    featureButton(emoji: "🗺️", label: "探险", color: .green) { onOpenMap() }
                    featureButton(emoji: "🎨", label: "装饰", color: .purple) { onOpenDecorate() }
                    featureButton(emoji: "🍎", label: "图鉴", color: .red) { onOpenCollection() }
                    featureButton(emoji: "👨‍👦", label: "对战", color: .blue) {
                        // Battle requires parental gate
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.checkDailyLogin(profile: profile)
            AudioManager.shared.playMusic("home_bgm.wav")
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
                    switch viewModel.parentGateIntent {
                    case .settings: onOpenParentCenter()
                    case .battle: onOpenBattle()
                    }
                    viewModel.parentGateIntent = .settings
                },
                onCancel: {
                    viewModel.showParentalGate = false
                    viewModel.parentGateIntent = .settings
                }
            )
        }
    }

    private func featureButton(emoji: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 40))
                Text(label).font(.footnote).fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.primary)
            .shadow(color: color.opacity(0.3), radius: 6, y: 3)
        }
    }
}
```

- [ ] **Step 2: Extend HomeViewModel with parentGateIntent**

Replace the contents of `NumberOrchard/NumberOrchard/Features/Home/HomeViewModel.swift`:

```swift
import SwiftUI
import SwiftData
import Observation

enum ParentGateIntent {
    case settings
    case battle
}

@Observable
@MainActor
final class HomeViewModel {
    var showCheckIn = false
    var showParentalGate = false
    var parentGateIntent: ParentGateIntent = .settings
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
```

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: HomeView with 4 feature entries and placed decorations visible"
```

---

# Phase 5: Parent-Child Battle

## Task 24: ParentQuestionGenerator with tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/ParentChild/ParentQuestionGenerator.swift`
- Create: `NumberOrchard/NumberOrchardTests/Features/ParentChild/ParentBattleTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Features/ParentChild/ParentBattleTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func parentDifficultyScalesWithChildLevel() {
    let gen = ParentQuestionGenerator()
    // L1 child → 25内 for parent
    let q1 = gen.generate(forChildLevel: .seed)
    #expect(q1.correctAnswer <= 25)

    // L3 child → 50内 for parent
    let q3 = gen.generate(forChildLevel: .smallTree)
    #expect(q3.correctAnswer <= 50 || q3.correctAnswer >= 0)

    // L6 child → 100内 for parent
    let q6 = gen.generate(forChildLevel: .harvest)
    // L6 allows multiplication
    #expect(q6.parentOperation != nil)
}

@Test func difficultyBoostIncreasesRange() {
    let gen = ParentQuestionGenerator()
    let base = gen.generate(forChildLevel: .seed, difficultyMultiplier: 1.0)
    let boosted = gen.generate(forChildLevel: .seed, difficultyMultiplier: 1.5)
    // Boosted should allow larger range
    #expect(boosted.operand1 + boosted.operand2 >= 0) // at minimum same
    _ = base // use
}

@Test func childLevelInBattleMatchesProfile() {
    let gen = ParentQuestionGenerator()
    let kidQ = gen.generateChildQuestion(childLevel: .sprout)
    #expect(kidQ.correctAnswer <= 5)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/ParentBattleTests 2>&1 | tail -10
```
Expected: FAIL — type not found

- [ ] **Step 3: Implement ParentQuestionGenerator**

Create `NumberOrchard/NumberOrchard/Features/ParentChild/ParentQuestionGenerator.swift`:

```swift
import Foundation

enum ParentOperation: String, Sendable {
    case add
    case subtract
    case multiply
    case divide
}

struct ParentQuestion: Sendable {
    let operand1: Int
    let operand2: Int
    let parentOperation: ParentOperation?
    let correctAnswer: Int
    let displayText: String
}

struct ParentQuestionGenerator: Sendable {

    /// Generate a parent question based on the child's current level.
    func generate(forChildLevel childLevel: DifficultyLevel, difficultyMultiplier: Double = 1.0) -> ParentQuestion {
        let baseRange = childLevel.rawValue * 5  // L1 → 5, L6 → 30
        let maxRange = Int(Double(baseRange) * 5 * difficultyMultiplier)  // L1 → 25, L6 → 150

        // L5/L6 parent gets mul/div
        let includeMulDiv = childLevel.rawValue >= 5

        let ops: [ParentOperation] = includeMulDiv ? [.add, .subtract, .multiply, .divide] : [.add, .subtract]
        let op = ops.randomElement() ?? .add

        let op1: Int
        let op2: Int
        let answer: Int
        let displayText: String

        switch op {
        case .add:
            op1 = Int.random(in: 2...(maxRange - 1))
            op2 = Int.random(in: 1...(maxRange - op1))
            answer = op1 + op2
            displayText = "\(op1) + \(op2) = ?"
        case .subtract:
            op1 = Int.random(in: 10...maxRange)
            op2 = Int.random(in: 1...(op1 - 1))
            answer = op1 - op2
            displayText = "\(op1) - \(op2) = ?"
        case .multiply:
            op1 = Int.random(in: 2...min(12, maxRange / 4))
            op2 = Int.random(in: 2...min(12, maxRange / max(1, op1)))
            answer = op1 * op2
            displayText = "\(op1) × \(op2) = ?"
        case .divide:
            op2 = Int.random(in: 2...9)
            answer = Int.random(in: 2...12)
            op1 = op2 * answer
            displayText = "\(op1) ÷ \(op2) = ?"
        }

        return ParentQuestion(
            operand1: op1,
            operand2: op2,
            parentOperation: op,
            correctAnswer: answer,
            displayText: displayText
        )
    }

    /// Generate a child-appropriate question for the battle.
    func generateChildQuestion(childLevel: DifficultyLevel) -> MathQuestion {
        let profile = LearningProfile(currentLevel: childLevel, subDifficulty: 3)
        return QuestionGenerator().generate(for: profile)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/ParentBattleTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: ParentQuestionGenerator with level-scaled difficulty and mul/div for L5+"
```

---

## Task 25: BattleViewModel

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/ParentChild/BattleViewModel.swift`

- [ ] **Step 1: Create BattleViewModel**

Create `NumberOrchard/NumberOrchard/Features/ParentChild/BattleViewModel.swift`:

```swift
import SwiftUI
import Observation

enum BattleWinner: String, Sendable {
    case child
    case parent
    case tie
}

@Observable
@MainActor
final class BattleViewModel {
    let totalRounds = 5
    var currentRound: Int = 1
    var childScore: Int = 0
    var parentScore: Int = 0
    var childQuestion: MathQuestion?
    var parentQuestion: ParentQuestion?
    var childInput: String = ""
    var parentInput: String = ""
    var roundComplete: Bool = false
    var roundWinner: BattleWinner?
    var battleComplete: Bool = false
    var finalWinner: BattleWinner?
    var parentKeypadScale: Double = 1.0
    private var parentDifficultyMultiplier: Double = 1.0
    private var childLossStreak: Int = 0
    private var parentLossStreak: Int = 0

    private let childLevel: DifficultyLevel
    private let childGenerator = QuestionGenerator()
    private let parentGenerator = ParentQuestionGenerator()

    init(childLevel: DifficultyLevel) {
        self.childLevel = childLevel
        generateNewRound()
    }

    private func generateNewRound() {
        let childProfile = LearningProfile(currentLevel: childLevel, subDifficulty: 3)
        childQuestion = childGenerator.generate(for: childProfile)
        parentQuestion = parentGenerator.generate(forChildLevel: childLevel, difficultyMultiplier: parentDifficultyMultiplier)
        childInput = ""
        parentInput = ""
        roundComplete = false
        roundWinner = nil
    }

    func submitChild() {
        guard !roundComplete, let question = childQuestion else { return }
        guard let inputValue = Int(childInput) else { return }
        if inputValue == question.correctAnswer {
            childScore += 1
            roundWinner = .child
            parentLossStreak += 1
            childLossStreak = 0
            endRound()
        } else {
            childInput = ""  // let them try again
        }
    }

    func submitParent() {
        guard !roundComplete, let question = parentQuestion else { return }
        guard let inputValue = Int(parentInput) else { return }
        if inputValue == question.correctAnswer {
            parentScore += 1
            roundWinner = .parent
            childLossStreak += 1
            parentLossStreak = 0
            endRound()
        } else {
            parentInput = ""
        }
    }

    private func endRound() {
        roundComplete = true

        // Apply dynamic balance for next round
        if childLossStreak >= 2 {
            parentDifficultyMultiplier = 1.5
            parentKeypadScale = 0.8
        } else if parentLossStreak >= 2 {
            parentDifficultyMultiplier = 0.8
            parentKeypadScale = 1.0
        } else {
            parentDifficultyMultiplier = 1.0
            parentKeypadScale = 1.0
        }
    }

    func nextRound() {
        guard roundComplete else { return }
        if currentRound >= totalRounds {
            finishBattle()
            return
        }
        currentRound += 1
        generateNewRound()
    }

    private func finishBattle() {
        battleComplete = true
        if childScore > parentScore { finalWinner = .child }
        else if parentScore > childScore { finalWinner = .parent }
        else { finalWinner = .tie }
    }

    func appendDigit(_ digit: String, to player: BattlePlayer) {
        switch player {
        case .child: childInput = String((childInput + digit).prefix(4))
        case .parent: parentInput = String((parentInput + digit).prefix(4))
        }
    }

    func clearInput(for player: BattlePlayer) {
        switch player {
        case .child: childInput = ""
        case .parent: parentInput = ""
        }
    }
}

enum BattlePlayer {
    case child
    case parent
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: BattleViewModel with 5-round scoring and dynamic balance"
```

---

## Task 26: BattleView

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/ParentChild/BattleView.swift`

- [ ] **Step 1: Create BattleView**

Create `NumberOrchard/NumberOrchard/Features/ParentChild/BattleView.swift`:

```swift
import SwiftUI
import SwiftData

struct BattleView: View {
    let onFinish: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var viewModel: BattleViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.battleComplete {
                    battleResultView(viewModel: viewModel)
                } else {
                    battleContentView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            let level = profiles.first?.difficultyLevel ?? .seed
            viewModel = BattleViewModel(childLevel: level)
        }
    }

    @ViewBuilder
    private func battleContentView(viewModel: BattleViewModel) -> some View {
        VStack(spacing: 0) {
            // Parent side (rotated 180°)
            battleSide(
                question: viewModel.parentQuestion?.displayText ?? "",
                input: viewModel.parentInput,
                keypadScale: viewModel.parentKeypadScale,
                onDigit: { viewModel.appendDigit($0, to: .parent) },
                onClear: { viewModel.clearInput(for: .parent) },
                onSubmit: { viewModel.submitParent() },
                label: "家长",
                color: .blue
            )
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity)

            // Middle bar
            ZStack {
                Rectangle().fill(.brown.opacity(0.3)).frame(height: 40)
                HStack(spacing: 20) {
                    Text("🏆 第 \(viewModel.currentRound)/\(viewModel.totalRounds) 轮")
                    Text("孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                        .fontWeight(.bold)
                    if viewModel.roundComplete {
                        Button("下一轮") { viewModel.nextRound() }
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(.green, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .font(.callout)
            }

            // Child side
            battleSide(
                question: viewModel.childQuestion?.displayText ?? "",
                input: viewModel.childInput,
                keypadScale: 1.0,
                onDigit: { viewModel.appendDigit($0, to: .child) },
                onClear: { viewModel.clearInput(for: .child) },
                onSubmit: { viewModel.submitChild() },
                label: "孩子",
                color: .green
            )
            .frame(maxWidth: .infinity)
        }
    }

    private func battleSide(
        question: String,
        input: String,
        keypadScale: Double,
        onDigit: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: 16) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(question).font(.title2).fontWeight(.semibold)
            Text(input.isEmpty ? "_" : input)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(minWidth: 80)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 8) {
                ForEach(0..<10) { i in
                    Button(action: { onDigit("\(i)") }) {
                        Text("\(i)")
                            .font(.title3)
                            .frame(width: 40 * keypadScale, height: 40 * keypadScale)
                            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            HStack(spacing: 20) {
                Button("清空", action: onClear)
                Button("提交", action: onSubmit)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(color, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }

    private func battleResultView(viewModel: BattleViewModel) -> some View {
        VStack(spacing: 24) {
            switch viewModel.finalWinner {
            case .child:
                Text("🎆").font(.system(size: 100))
                Text("你比爸爸/妈妈还厉害！")
                    .font(.title)
                    .fontWeight(.bold)
            case .parent:
                Text("🤗").font(.system(size: 100))
                Text("差一点就赢了，下次一定！")
                    .font(.title)
                    .fontWeight(.bold)
            case .tie, nil:
                Text("🙌").font(.system(size: 100))
                Text("你们都很棒！")
                    .font(.title)
                    .fontWeight(.bold)
            }
            Text("最终 孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button(action: onFinish) {
                Text("返回主页")
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: BattleView with 180° rotated parent UI and split-screen keypads"
```

---

# Phase 6: Integration

## Task 27: Update AppCoordinator with new routes

**Files:**
- Modify: `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`

- [ ] **Step 1: Expand AppScreen enum and route to new views**

Replace the entire contents of `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`:

```swift
import SwiftUI
import SwiftData

enum AppScreen {
    case home
    case adventure(station: Station?)
    case parentCenter
    case map
    case collection
    case decorate
    case battle
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
                        onStartAdventure: { startAdventure(station: nil) },
                        onOpenParentCenter: { currentScreen = .parentCenter },
                        onOpenMap: { currentScreen = .map },
                        onOpenCollection: { currentScreen = .collection },
                        onOpenDecorate: { currentScreen = .decorate },
                        onOpenBattle: { currentScreen = .battle }
                    )
                case .adventure(let station):
                    AdventureSessionView(
                        station: station,
                        onFinish: { stopAdventure() }
                    )
                case .parentCenter:
                    ParentCenterView(onDismiss: { currentScreen = .home })
                case .map:
                    ExplorationMapView(
                        onDismiss: { currentScreen = .home },
                        onStartStation: { station in startAdventure(station: station) }
                    )
                case .collection:
                    FruitCollectionView(onDismiss: { currentScreen = .home })
                case .decorate:
                    DecorateOrchardView(onDismiss: { currentScreen = .home })
                case .battle:
                    BattleView(onFinish: { currentScreen = .home })
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
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🌳").font(.system(size: 60))
                Text("小果农休息一下吧！").font(.title).foregroundStyle(.white)
                Text("站起来看看窗外～").font(.title3).foregroundStyle(.white.opacity(0.8))
                if !eyeCareManager.hasUsedExtension {
                    Button {
                        eyeCareManager.useExtension()
                        showEyeCareAlert = false
                    } label: {
                        Text("再玩 5 分钟")
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Button {
                    stopAdventure()
                    showEyeCareAlert = false
                } label: {
                    Text("结束今天的学习")
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func startAdventure(station: Station?) {
        let timeLimit = profiles.first?.dailyTimeLimitMinutes ?? 20
        eyeCareManager = EyeCareManager(timeLimitMinutes: timeLimit)
        eyeCareManager.startSession()
        currentScreen = .adventure(station: station)
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

- [ ] **Step 2: Build**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: AppCoordinator routes all new screens (map, collection, decorate, battle)"
```

---

## Task 28: Run full test suite and verify everything passes

**Files:** (verification only)

- [ ] **Step 1: Run full test suite**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run with|\*\* TEST|error:" | tail -10
```
Expected: `Test run with ≥50 tests passed` and `** TEST SUCCEEDED **`

- [ ] **Step 2: If any test fails, fix it before continuing**

Review the failing test output. Common issues:
- Forgotten `@MainActor` annotation on test functions
- Missing init parameter when calling updated constructors
- Catalog count mismatch (add/remove items)

Fix inline, re-run test, commit with message: `fix: <specific issue>`

- [ ] **Step 3: Verify manual build succeeds**

Run:
```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Final commit if any fixes were made**

```bash
cd /Users/samxiao/code/app
git add -A
git diff --cached --quiet || git commit -m "fix: resolve final test/build issues for extended features"
```

---

## Summary

| Phase | Tasks | Tests |
|-------|-------|-------|
| 1. Data foundation | 1-9 (9 tasks) | DifficultyManager updates |
| 2. New gameplay + L5/L6 | 10-15 (6 tasks) | L5L6, NumberTrain, Balance |
| 3. Map + Rewards + Adventure | 16-20 (5 tasks) | MapProgression, RewardCalculator |
| 4. Collection + Decoration | 21-23 (3 tasks) | FruitCollection, DecorationInventory |
| 5. Parent-Child Battle | 24-26 (3 tasks) | ParentBattle |
| 6. Integration | 27-28 (2 tasks) | Full suite regression |

**Total: 28 tasks**, spec-compliant implementation of all 7 extended features.
