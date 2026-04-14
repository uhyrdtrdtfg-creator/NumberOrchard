# Math Pet Raising Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pet-raising layer that lets children feed collected fruits to Noom creatures (1-20) to grow them through 3 evolution stages, and hatch new big-Noom creatures (11-20) by combining two mature small Nooms.

**Architecture:** Adds a 2nd tab inside `NoomForestView` (图鉴 / 宠物花园). Reuses existing `NoomCatalog`, `CollectedFruit`, and `NoomRenderer` (extended with stage decorations). New `PetProgress @Model` tracks each pet's XP/stage. Pure logic units (`PetXPCalculator`, `PetEvolutionLogic`, `PetPreferenceMap`) drive feeding/evolution/hatching rules.

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, SwiftData, iPadOS 17.0+, Swift Testing.

---

## File Structure

```
NumberOrchard/NumberOrchard/
├── Core/
│   ├── Models/
│   │   ├── Noom.swift                        (modify: catalog adds 11-20)
│   │   ├── PetProgress.swift                 (NEW @Model)
│   │   ├── PetPreferenceMap.swift            (NEW static)
│   │   └── ChildProfile.swift                (modify: + petProgress)
│   └── PetLogic/                             (NEW dir)
│       ├── PetXPCalculator.swift
│       └── PetEvolutionLogic.swift
├── App/
│   └── NumberOrchardApp.swift                (modify: + Schema)
└── Features/NoomForest/
    ├── NoomRenderer.swift                    (modify: + stage param)
    ├── NoomForestView.swift                  (modify: + Tab picker)
    ├── NoomForestViewModel.swift             (modify: + selectedTab)
    ├── PetGardenView.swift                   (NEW)
    ├── PetGardenViewModel.swift              (NEW)
    ├── PetFeedingArea.swift                  (NEW)
    └── EggHatchingArea.swift                 (NEW)

NumberOrchardTests/
├── Core/Models/
│   ├── NoomCatalogTests.swift                (modify: 20 entries assertion)
│   └── PetPreferenceMapTests.swift           (NEW)
├── Core/PetLogic/                            (NEW dir)
│   ├── PetXPCalculatorTests.swift
│   └── PetEvolutionLogicTests.swift
└── Features/NoomForest/
    └── PetProgressTests.swift                (NEW)
```

---

# Phase 1: Data Extension

## Task 1: Extend NoomCatalog to 20 entries

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Core/Models/Noom.swift`
- Modify: `NumberOrchard/NumberOrchardTests/Core/Models/NoomCatalogTests.swift`

- [ ] **Step 1: Update existing tests to assert 20 entries**

In `NumberOrchard/NumberOrchardTests/Core/Models/NoomCatalogTests.swift`, find:

```swift
@Test func catalogHasTenNooms() {
    #expect(NoomCatalog.all.count == 10)
}

@Test func noomNumbersAreOneThroughTen() {
    let numbers = NoomCatalog.all.map(\.number).sorted()
    #expect(numbers == Array(1...10))
}
```

Replace with:

```swift
@Test func catalogHasTwentyNooms() {
    #expect(NoomCatalog.all.count == 20)
}

@Test func noomNumbersAreOneThroughTwenty() {
    let numbers = NoomCatalog.all.map(\.number).sorted()
    #expect(numbers == Array(1...20))
}

@Test func smallNoomsArePartitioned() {
    #expect(NoomCatalog.smallNooms.count == 10)
    #expect(NoomCatalog.smallNooms.allSatisfy { $0.number <= 10 })
}

@Test func bigNoomsArePartitioned() {
    #expect(NoomCatalog.bigNooms.count == 10)
    #expect(NoomCatalog.bigNooms.allSatisfy { $0.number >= 11 })
}
```

Also find:

```swift
@Test func lookupByNumberWorks() {
    #expect(NoomCatalog.noom(for: 1)?.name == "小一")
    #expect(NoomCatalog.noom(for: 10)?.name == "十全")
    #expect(NoomCatalog.noom(for: 0) == nil)
    #expect(NoomCatalog.noom(for: 11) == nil)
}
```

Replace with:

```swift
@Test func lookupByNumberWorks() {
    #expect(NoomCatalog.noom(for: 1)?.name == "小一")
    #expect(NoomCatalog.noom(for: 10)?.name == "十全")
    #expect(NoomCatalog.noom(for: 11)?.name == "大十一")
    #expect(NoomCatalog.noom(for: 20)?.name == "廿宝")
    #expect(NoomCatalog.noom(for: 0) == nil)
    #expect(NoomCatalog.noom(for: 21) == nil)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomCatalogTests 2>&1 | tail -10
```

Expected: FAIL (count assertion + missing methods)

- [ ] **Step 3: Extend Noom.swift**

In `NumberOrchard/NumberOrchard/Core/Models/Noom.swift`, find the closing `]` of `static let all: [Noom] = [`. Insert the 10 new entries before the closing bracket:

```swift
        // 11-20 (大精灵)
        .init(number: 11, name: "大十一",
              bodyColor: UIColor(red: 0.95, green: 0.50, blue: 0.40, alpha: 1.0),
              catchphrase: "我是十加一哦！"),
        .init(number: 12, name: "十二郎",
              bodyColor: UIColor(red: 0.50, green: 0.80, blue: 0.60, alpha: 1.0),
              catchphrase: "一打就是十二！"),
        .init(number: 13, name: "十三公",
              bodyColor: UIColor(red: 0.90, green: 0.70, blue: 0.30, alpha: 1.0),
              catchphrase: "幸运十三！"),
        .init(number: 14, name: "十四妹",
              bodyColor: UIColor(red: 0.50, green: 0.70, blue: 0.90, alpha: 1.0),
              catchphrase: "我比十三多一个。"),
        .init(number: 15, name: "十五月",
              bodyColor: UIColor(red: 0.90, green: 0.55, blue: 0.40, alpha: 1.0),
              catchphrase: "圆月十五！"),
        .init(number: 16, name: "十六金",
              bodyColor: UIColor(red: 0.65, green: 0.55, blue: 0.90, alpha: 1.0),
              catchphrase: "十六金币！"),
        .init(number: 17, name: "十七客",
              bodyColor: UIColor(red: 0.70, green: 0.85, blue: 0.45, alpha: 1.0),
              catchphrase: "我独一无二！"),
        .init(number: 18, name: "十八子",
              bodyColor: UIColor(red: 0.90, green: 0.55, blue: 0.55, alpha: 1.0),
              catchphrase: "十八武艺！"),
        .init(number: 19, name: "十九嫂",
              bodyColor: UIColor(red: 0.45, green: 0.75, blue: 0.80, alpha: 1.0),
              catchphrase: "接近二十啦！"),
        .init(number: 20, name: "廿宝",
              bodyColor: UIColor(red: 1.00, green: 0.75, blue: 0.10, alpha: 1.0),
              catchphrase: "我是大王廿宝！"),
```

In the same file, after the existing `static func noom(for n: Int) -> Noom?` method, add:

```swift
    static var smallNooms: [Noom] { all.filter { $0.number <= 10 } }
    static var bigNooms: [Noom] { all.filter { $0.number >= 11 } }
```

- [ ] **Step 4: Run tests, expect PASS**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomCatalogTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 7 tests PASS (5 existing updated + 2 new partition tests)

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: extend NoomCatalog to 20 entries with smallNooms/bigNooms partitions"
```

---

## Task 2: PetProgress @Model + ChildProfile relationship + Schema

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/PetProgress.swift`
- Modify: `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`
- Modify: `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift`

- [ ] **Step 1: Create PetProgress @Model**

Create `NumberOrchard/NumberOrchard/Core/Models/PetProgress.swift`:

```swift
import Foundation
import SwiftData

@Model
final class PetProgress {
    var noomNumber: Int
    var xp: Int
    var stage: Int        // 0 = baby, 1 = teen, 2 = adult
    var matureAt: Date?
    var isActive: Bool

    @Relationship(inverse: \ChildProfile.petProgress)
    var profile: ChildProfile?

    init(noomNumber: Int) {
        self.noomNumber = noomNumber
        self.xp = 0
        self.stage = 0
        self.matureAt = nil
        self.isActive = false
    }
}
```

- [ ] **Step 2: Add relationship to ChildProfile**

In `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`, find:

```swift
    @Relationship(deleteRule: .cascade)
    var collectedNooms: [CollectedNoom] = []
```

Add immediately after:

```swift

    @Relationship(deleteRule: .cascade)
    var petProgress: [PetProgress] = []
```

- [ ] **Step 3: Register Schema**

In `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift`, find:

```swift
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
            StationProgress.self,
            CollectedDecoration.self,
            CollectedFruit.self,
            CollectedNoom.self,
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
            CollectedNoom.self,
            PetProgress.self,
        ])
```

- [ ] **Step 4: Build and verify all existing tests still pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run|\*\* TEST|error:" | tail -3
```

Expected: All ~85 tests pass (83 existing including new NoomCatalog + nothing broken)

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetProgress @Model + ChildProfile.petProgress + Schema registration"
```

---

## Task 3: PetPreferenceMap

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/PetPreferenceMap.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/Models/PetPreferenceMapTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/Models/PetPreferenceMapTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func every1To20HasPreferences() {
    for n in 1...20 {
        let prefs = PetPreferenceMap.preferences[n]
        #expect(prefs != nil, "Noom \(n) missing preferences")
        #expect(!(prefs?.isEmpty ?? true), "Noom \(n) has empty preferences")
    }
}

@Test func preferenceFruitIdsExistInFruitCatalog() {
    for (noomNum, fruitIds) in PetPreferenceMap.preferences {
        for fruitId in fruitIds {
            #expect(FruitCatalog.fruit(id: fruitId) != nil,
                    "Noom \(noomNum) preference '\(fruitId)' not in FruitCatalog")
        }
    }
}

@Test func isPreferredReturnsTrueForMatching() {
    #expect(PetPreferenceMap.isPreferred(fruitId: "apple", for: 1) == true)
    #expect(PetPreferenceMap.isPreferred(fruitId: "watermelon", for: 5) == true)
}

@Test func isPreferredReturnsFalseForNonMatching() {
    #expect(PetPreferenceMap.isPreferred(fruitId: "watermelon", for: 1) == false)
    #expect(PetPreferenceMap.isPreferred(fruitId: "fake_fruit", for: 5) == false)
    #expect(PetPreferenceMap.isPreferred(fruitId: "apple", for: 999) == false)
}
```

- [ ] **Step 2: Run tests, verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetPreferenceMapTests 2>&1 | tail -10
```

Expected: FAIL — `PetPreferenceMap` not found

- [ ] **Step 3: Implement PetPreferenceMap**

Create `NumberOrchard/NumberOrchard/Core/Models/PetPreferenceMap.swift`:

```swift
import Foundation

enum PetPreferenceMap {
    /// Each Noom (1-20) prefers certain fruits — feeding a preferred fruit doubles XP gain.
    /// Fruit IDs must exist in `FruitCatalog`.
    static let preferences: [Int: [String]] = [
        1:  ["apple", "strawberry"],
        2:  ["banana", "lemon"],
        3:  ["cherry", "red_grape"],
        4:  ["orange", "tangerine"],
        5:  ["watermelon", "melon"],
        6:  ["grape", "blueberry"],
        7:  ["peach", "apricot"],
        8:  ["mango", "pineapple"],
        9:  ["kiwi", "tomato"],
        10: ["green_apple", "avocado"],

        11: ["blueberry", "kiwi"],
        12: ["mango", "coconut"],
        13: ["chestnut", "olive"],
        14: ["starfruit"],
        15: ["dragon_fruit"],
        16: ["golden_apple"],
        17: ["rainbow_fruit"],
        18: ["crystal_berry"],
        19: ["sun_fruit"],
        20: ["golden_apple", "crystal_berry"],
    ]

    static func isPreferred(fruitId: String, for noomNumber: Int) -> Bool {
        preferences[noomNumber]?.contains(fruitId) ?? false
    }
}
```

- [ ] **Step 4: Run tests, expect PASS**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetPreferenceMapTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetPreferenceMap — fruit preferences for all 20 Nooms (preferred = 2x XP)"
```

---

# Phase 2: Pure Logic

## Task 4: PetXPCalculator

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/PetLogic/PetXPCalculator.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/PetLogic/PetXPCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/PetLogic/PetXPCalculatorTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func nonPreferredFruitGivesBaseXP() {
    let calc = PetXPCalculator()
    // watermelon is preference of 5, not 1
    #expect(calc.xpFor(fruitId: "watermelon", noomNumber: 1) == 10)
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 5) == 10)
}

@Test func preferredFruitGivesDoubleXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 1) == 20)
    #expect(calc.xpFor(fruitId: "strawberry", noomNumber: 1) == 20)
    #expect(calc.xpFor(fruitId: "watermelon", noomNumber: 5) == 20)
}

@Test func unknownFruitGivesBaseXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "fake_fruit_xyz", noomNumber: 5) == 10)
}

@Test func unknownNoomNumberGivesBaseXP() {
    let calc = PetXPCalculator()
    #expect(calc.xpFor(fruitId: "apple", noomNumber: 999) == 10)
}
```

- [ ] **Step 2: Run, verify fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetXPCalculatorTests 2>&1 | tail -10
```

Expected: FAIL

- [ ] **Step 3: Implement PetXPCalculator**

Create `NumberOrchard/NumberOrchard/Core/PetLogic/PetXPCalculator.swift`:

```swift
import Foundation

struct PetXPCalculator: Sendable {
    static let baseXP = 10
    static let preferredMultiplier = 2

    /// Returns XP gained from feeding `fruitId` to the Noom with `noomNumber`.
    /// Preferred fruit → 2x base; everything else (including unknown fruits/noom numbers) → base.
    func xpFor(fruitId: String, noomNumber: Int) -> Int {
        if PetPreferenceMap.isPreferred(fruitId: fruitId, for: noomNumber) {
            return Self.baseXP * Self.preferredMultiplier
        }
        return Self.baseXP
    }
}
```

- [ ] **Step 4: Run tests, expect PASS**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetXPCalculatorTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetXPCalculator — 10 base XP, 20 for preferred fruits"
```

---

## Task 5: PetEvolutionLogic

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/PetLogic/PetEvolutionLogic.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/PetLogic/PetEvolutionLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/PetLogic/PetEvolutionLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func stageAtZeroXPIsBaby() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 0) == 0)
    #expect(logic.stage(for: 50) == 0)
    #expect(logic.stage(for: 99) == 0)
}

@Test func stageAt100XPIsTeen() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 100) == 1)
    #expect(logic.stage(for: 200) == 1)
    #expect(logic.stage(for: 299) == 1)
}

@Test func stageAt300XPIsAdult() {
    let logic = PetEvolutionLogic()
    #expect(logic.stage(for: 300) == 2)
    #expect(logic.stage(for: 1000) == 2)
}

@Test func isMatureRequires300XP() {
    let logic = PetEvolutionLogic()
    #expect(logic.isMature(xp: 0) == false)
    #expect(logic.isMature(xp: 299) == false)
    #expect(logic.isMature(xp: 300) == true)
    #expect(logic.isMature(xp: 500) == true)
}

@Test func canHatchReturnsSumIfInElevenToTwenty() {
    let logic = PetEvolutionLogic()
    #expect(logic.canHatch(matureNoomA: 5, matureNoomB: 6) == 11)
    #expect(logic.canHatch(matureNoomA: 10, matureNoomB: 1) == 11)
    #expect(logic.canHatch(matureNoomA: 10, matureNoomB: 10) == 20)
}

@Test func canHatchReturnsNilIfSumOutsideRange() {
    let logic = PetEvolutionLogic()
    #expect(logic.canHatch(matureNoomA: 1, matureNoomB: 2) == nil)   // sum=3, < 11
    #expect(logic.canHatch(matureNoomA: 5, matureNoomB: 5) == nil)   // sum=10, < 11
    #expect(logic.canHatch(matureNoomA: 11, matureNoomB: 10) == nil) // sum=21, > 20
}
```

- [ ] **Step 2: Run, verify fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetEvolutionLogicTests 2>&1 | tail -10
```

Expected: FAIL

- [ ] **Step 3: Implement PetEvolutionLogic**

Create `NumberOrchard/NumberOrchard/Core/PetLogic/PetEvolutionLogic.swift`:

```swift
import Foundation

struct PetEvolutionLogic: Sendable {
    /// Cumulative XP needed for each stage entry.
    /// stage 0 (baby): 0 XP, stage 1 (teen): 100 XP, stage 2 (adult): 300 XP.
    static let stageThresholds = [0, 100, 300]

    func stage(for xp: Int) -> Int {
        for i in stride(from: Self.stageThresholds.count - 1, through: 0, by: -1) {
            if xp >= Self.stageThresholds[i] { return i }
        }
        return 0
    }

    func isMature(xp: Int) -> Bool {
        stage(for: xp) >= 2
    }

    /// If two mature small Nooms (1-10) sum to 11-20, returns the resulting big-Noom number.
    /// Returns nil for invalid combinations.
    func canHatch(matureNoomA: Int, matureNoomB: Int) -> Int? {
        let sum = matureNoomA + matureNoomB
        guard (11...20).contains(sum) else { return nil }
        return sum
    }
}
```

- [ ] **Step 4: Run tests, expect PASS**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetEvolutionLogicTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 6 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetEvolutionLogic — XP stage mapping (0/100/300) + hatching sum validation"
```

---

## Task 6: PetProgress unit tests

**Files:**
- Create: `NumberOrchard/NumberOrchardTests/Features/NoomForest/PetProgressTests.swift`

- [ ] **Step 1: Write tests**

Create `NumberOrchard/NumberOrchardTests/Features/NoomForest/PetProgressTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test @MainActor func petProgressInitDefaults() {
    let p = PetProgress(noomNumber: 5)
    #expect(p.noomNumber == 5)
    #expect(p.xp == 0)
    #expect(p.stage == 0)
    #expect(p.matureAt == nil)
    #expect(p.isActive == false)
}

@Test @MainActor func xpCanBeAccumulated() {
    let p = PetProgress(noomNumber: 3)
    p.xp += 50
    p.xp += 50
    #expect(p.xp == 100)
}

@Test @MainActor func stageCanBeUpdated() {
    let p = PetProgress(noomNumber: 1)
    p.stage = 1
    #expect(p.stage == 1)
}
```

- [ ] **Step 2: Run, expect PASS (no new code needed — PetProgress already exists)**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/PetProgressTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 3 tests PASS

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetProgress init/mutation tests"
```

---

# Phase 3: Renderer Extension

## Task 7: NoomRenderer stage-based decoration

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomRenderer.swift`

- [ ] **Step 1: Add stage parameter and decoration helper**

In `NumberOrchard/NumberOrchard/Features/NoomForest/NoomRenderer.swift`, find:

```swift
    static func image(for noom: Noom, expression: NoomExpression, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawShadow(in: ctx.cgContext, size: size)
            drawBody(in: ctx.cgContext, size: size, color: noom.bodyColor)
            drawSpots(in: ctx.cgContext, size: size, count: noom.number)
            drawFace(in: ctx.cgContext, size: size, expression: expression)
            drawNumberBadge(in: ctx.cgContext, size: size, number: noom.number)
        }
    }
```

Replace with:

```swift
    static func image(for noom: Noom, expression: NoomExpression, size: CGSize, stage: Int = 0) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawShadow(in: ctx.cgContext, size: size)
            drawBody(in: ctx.cgContext, size: size, color: noom.bodyColor)
            drawSpots(in: ctx.cgContext, size: size, count: noom.number)
            drawFace(in: ctx.cgContext, size: size, expression: expression)
            drawNumberBadge(in: ctx.cgContext, size: size, number: noom.number)
            drawStageDecoration(in: ctx.cgContext, size: size, stage: stage)
        }
    }
```

Then add this new private method at the bottom of the `NoomRenderer` enum, just before the closing `}`:

```swift
    private static func drawStageDecoration(in ctx: CGContext, size: CGSize, stage: Int) {
        guard stage >= 1 else { return }

        // Teen: bow / hat on top
        if stage == 1 {
            let emoji = "🎀" as NSString
            let font = UIFont.systemFont(ofSize: size.width * 0.28)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let textSize = emoji.size(withAttributes: attrs)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height * 0.02,
                width: textSize.width,
                height: textSize.height
            )
            emoji.draw(in: rect, withAttributes: attrs)
        }

        // Adult: crown + cape
        if stage == 2 {
            let crown = "👑" as NSString
            let crownFont = UIFont.systemFont(ofSize: size.width * 0.3)
            let crownAttrs: [NSAttributedString.Key: Any] = [.font: crownFont]
            let crownSize = crown.size(withAttributes: crownAttrs)
            let crownRect = CGRect(
                x: (size.width - crownSize.width) / 2,
                y: -size.height * 0.04,
                width: crownSize.width,
                height: crownSize.height
            )
            crown.draw(in: crownRect, withAttributes: crownAttrs)

            let cape = "🎽" as NSString
            let capeFont = UIFont.systemFont(ofSize: size.width * 0.22)
            let capeAttrs: [NSAttributedString.Key: Any] = [.font: capeFont]
            let capeSize = cape.size(withAttributes: capeAttrs)
            let capeRect = CGRect(
                x: (size.width - capeSize.width) / 2,
                y: size.height - capeSize.height - 4,
                width: capeSize.width,
                height: capeSize.height
            )
            cape.draw(in: capeRect, withAttributes: capeAttrs)
        }
    }
```

- [ ] **Step 2: Build to verify (existing call sites still compile because `stage` defaults to 0)**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests to ensure no regressions**

```bash
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run|\*\* TEST|error:" | tail -3
```

Expected: All previous tests still pass

- [ ] **Step 4: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomRenderer accepts stage param — adds bow (teen) or crown+cape (adult)"
```

---

# Phase 4: PetGarden Framework (Tab + Skeleton)

## Task 8: NoomForestView with Tab picker + ViewModel

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestViewModel.swift`
- Modify: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenView.swift` (placeholder)

- [ ] **Step 1: Add selectedTab to NoomForestViewModel**

Replace the entire contents of `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestViewModel.swift`:

```swift
import SwiftUI
import Observation

enum NoomForestTab: Sendable, CaseIterable, Hashable {
    case dex
    case garden

    var title: String {
        switch self {
        case .dex: return "📖 图鉴"
        case .garden: return "🌻 宠物花园"
        }
    }
}

@Observable
@MainActor
final class NoomForestViewModel {
    let profile: ChildProfile
    var selectedTab: NoomForestTab = .dex

    init(profile: ChildProfile) {
        self.profile = profile
    }

    var unlockedNumbers: Set<Int> {
        Set(profile.collectedNooms.map(\.noomNumber))
    }

    var unlockedCount: Int { unlockedNumbers.count }

    func isUnlocked(_ number: Int) -> Bool { unlockedNumbers.contains(number) }
}
```

- [ ] **Step 2: Create PetGardenView placeholder**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenView.swift`:

```swift
import SwiftUI

struct PetGardenView: View {
    let profile: ChildProfile

    var body: some View {
        VStack {
            Spacer()
            Text("🌻 宠物花园")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
            Text("(即将到来 — Phase 5/6/7)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.5))
            Spacer()
        }
    }
}
```

- [ ] **Step 3: Modify NoomForestView to switch between tabs**

In `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestView.swift`, find the body's outer VStack and the section after `topBar` that displays the title and dex grid. We need to wrap the content in a tab-aware switch.

Find this block:

```swift
            VStack(spacing: 24) {
                topBar

                Text("🐾 小精灵森林")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                Text("图鉴: \(viewModel?.unlockedCount ?? 0) / 10")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.7))

                dexGrid
```

Replace with:

```swift
            VStack(spacing: 24) {
                topBar

                Text("🐾 小精灵森林")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                tabPicker

                if viewModel?.selectedTab == .garden, let profile {
                    PetGardenView(profile: profile)
                } else {
                    Text("图鉴: \(viewModel?.unlockedCount ?? 0) / 20")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CartoonColor.text.opacity(0.7))

                    dexGrid
                }
```

In the same file, also add a `tabPicker` computed property near the other view builders (before `dexGrid`):

```swift
    private var tabPicker: some View {
        HStack(spacing: 12) {
            ForEach(NoomForestTab.allCases, id: \.self) { tab in
                let selected = (viewModel?.selectedTab == tab)
                Button(action: {
                    viewModel?.selectedTab = tab
                }) {
                    Text(tab.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .foregroundStyle(selected ? .white : CartoonColor.text)
                        .background(
                            ZStack {
                                Capsule().fill(CartoonColor.ink.opacity(0.9)).offset(y: 4)
                                Capsule().fill(selected ? CartoonColor.gold : CartoonColor.paper)
                                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3)
                            }
                        )
                        .fixedSize()
                }
                .buttonStyle(.plain)
            }
        }
    }
```

Also extend the dex grid to show 20 entries instead of 10. Find:

```swift
    private var dexGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
            ForEach(NoomCatalog.all) { noom in
```

That's already iterating over `NoomCatalog.all` — which now includes 20 entries — so no change needed there. But the column count of 5 with 20 items gives 4 rows; verify the grid wraps. (No code change in this step.)

- [ ] **Step 4: Build & verify tests pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomForestView gets Tab picker (图鉴 / 宠物花园) with PetGardenView placeholder"
```

---

# Phase 5: Feeding Interaction

## Task 9: PetGardenViewModel — manage active pet + feeding logic

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenViewModel.swift`

- [ ] **Step 1: Implement PetGardenViewModel**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenViewModel.swift`:

```swift
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class PetGardenViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    private let xpCalculator = PetXPCalculator()
    private let evolutionLogic = PetEvolutionLogic()

    var lastEvolvedNoomNumber: Int?
    var lastFedXP: Int = 0
    var lastFedWasPreferred: Bool = false

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
    }

    /// Pets that are owned (one PetProgress entry per collected Noom).
    /// Lazily creates PetProgress for any CollectedNoom that doesn't have one yet.
    func ownedPets() -> [PetProgress] {
        let owned = profile.collectedNooms.map(\.noomNumber)
        for n in owned where !profile.petProgress.contains(where: { $0.noomNumber == n }) {
            let p = PetProgress(noomNumber: n)
            profile.petProgress.append(p)
            modelContext.insert(p)
        }
        return profile.petProgress
            .filter { owned.contains($0.noomNumber) }
            .sorted { $0.noomNumber < $1.noomNumber }
    }

    var activePet: PetProgress? {
        ownedPets().first(where: { $0.isActive }) ?? ownedPets().first
    }

    func setActive(_ pet: PetProgress) {
        for p in profile.petProgress {
            p.isActive = (p.noomNumber == pet.noomNumber)
        }
    }

    /// Feed `fruitId` to the active pet. Returns the XP gained and whether it was a preferred fruit.
    /// Also evolves the pet to a new stage if XP crosses a threshold.
    @discardableResult
    func feedActivePet(fruitId: String) -> (xp: Int, preferred: Bool, didEvolve: Bool) {
        guard let pet = activePet else { return (0, false, false) }
        let xp = xpCalculator.xpFor(fruitId: fruitId, noomNumber: pet.noomNumber)
        let oldStage = pet.stage
        pet.xp += xp
        let newStage = evolutionLogic.stage(for: pet.xp)
        var didEvolve = false
        if newStage > oldStage {
            pet.stage = newStage
            if newStage == 2 && pet.matureAt == nil {
                pet.matureAt = Date()
            }
            lastEvolvedNoomNumber = pet.noomNumber
            didEvolve = true
        }
        let preferred = PetPreferenceMap.isPreferred(fruitId: fruitId, for: pet.noomNumber)
        lastFedXP = xp
        lastFedWasPreferred = preferred
        return (xp, preferred, didEvolve)
    }

    /// Mature pets eligible for hatching.
    func maturePets() -> [PetProgress] {
        ownedPets().filter { evolutionLogic.isMature(xp: $0.xp) && $0.noomNumber <= 10 }
    }

    /// Inventory of fruit ids the child has unlocked.
    func availableFruits() -> [FruitItem] {
        let collectedIds = Set(profile.collectedFruits.map(\.fruitId))
        return FruitCatalog.fruits.filter { collectedIds.contains($0.id) }
    }

    /// Try to hatch a big-Noom from two mature small-Noom selections.
    /// On success: creates PetProgress for the new Noom + a CollectedNoom, returns the resulting number.
    /// On failure: returns nil.
    @discardableResult
    func tryHatch(petA: PetProgress, petB: PetProgress) -> Int? {
        guard evolutionLogic.isMature(xp: petA.xp), evolutionLogic.isMature(xp: petB.xp) else {
            return nil
        }
        guard let result = evolutionLogic.canHatch(matureNoomA: petA.noomNumber, matureNoomB: petB.noomNumber) else {
            return nil
        }
        // Already hatched?
        if profile.collectedNooms.contains(where: { $0.noomNumber == result }) {
            return nil
        }
        // Create CollectedNoom and PetProgress for the new big-Noom.
        let cn = CollectedNoom(noomNumber: result)
        profile.collectedNooms.append(cn)
        modelContext.insert(cn)
        let pp = PetProgress(noomNumber: result)
        profile.petProgress.append(pp)
        modelContext.insert(pp)
        return result
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetGardenViewModel — owned pets, active pet, feed/evolve/hatch logic"
```

---

## Task 10: PetFeedingArea — active pet + fruit drag-and-drop

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/PetFeedingArea.swift`

- [ ] **Step 1: Create PetFeedingArea**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/PetFeedingArea.swift`:

```swift
import SwiftUI

struct PetFeedingArea: View {
    @Bindable var viewModel: PetGardenViewModel
    @State private var draggedFruit: FruitItem?
    @State private var dragOffset: CGSize = .zero
    @State private var floatingXPText: String?
    @State private var showSwitcher = false
    @State private var showEvolutionEffect = false

    private let evolutionLogic = PetEvolutionLogic()

    var body: some View {
        VStack(spacing: 20) {
            activePetSection
            fruitInventorySection
        }
        .sheet(isPresented: $showSwitcher) {
            petSwitcherSheet
        }
    }

    @ViewBuilder
    private var activePetSection: some View {
        if let pet = viewModel.activePet, let noom = NoomCatalog.noom(for: pet.noomNumber) {
            CartoonPanel(cornerRadius: 24) {
                VStack(spacing: 12) {
                    HStack {
                        Text(noom.name)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(CartoonColor.text)
                        Text(stageLabel(pet.stage))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(CartoonColor.text.opacity(0.6))
                    }

                    ZStack {
                        Image(uiImage: NoomRenderer.image(
                            for: noom,
                            expression: .happy,
                            size: CGSize(width: 140, height: 140),
                            stage: pet.stage
                        ))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(showEvolutionEffect ? 1.4 : 1.0)
                        .rotationEffect(.degrees(showEvolutionEffect ? 360 : 0))
                        .animation(.easeInOut(duration: 1.0), value: showEvolutionEffect)

                        if let xpText = floatingXPText {
                            Text(xpText)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(viewModel.lastFedWasPreferred ? CartoonColor.gold : .white)
                                .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
                                .offset(y: -80)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 180, height: 180)

                    xpBar(pet: pet)

                    Button("切换宠物") { showSwitcher = true }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(CartoonColor.paper))
                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2))
                }
                .padding(20)
            }
        } else {
            Text("还没有宠物呢，去小精灵挑战解锁吧！")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .padding()
        }
    }

    private func xpBar(pet: PetProgress) -> some View {
        let nextThreshold = pet.stage < PetEvolutionLogic.stageThresholds.count - 1
            ? PetEvolutionLogic.stageThresholds[pet.stage + 1]
            : pet.xp
        let prevThreshold = PetEvolutionLogic.stageThresholds[pet.stage]
        let progress: Double = nextThreshold > prevThreshold
            ? min(1.0, Double(pet.xp - prevThreshold) / Double(nextThreshold - prevThreshold))
            : 1.0

        return VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: 200, height: 22)
                    .offset(y: 3)
                Capsule().fill(.white).frame(width: 200, height: 22)
                Capsule()
                    .fill(LinearGradient(colors: [CartoonColor.gold, CartoonColor.coral],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(22, progress * 200), height: 22)
                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 2.5).frame(width: 200, height: 22)
            }
            Text("\(pet.xp) / \(nextThreshold) XP")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.7))
        }
    }

    @ViewBuilder
    private var fruitInventorySection: some View {
        let fruits = viewModel.availableFruits()
        if fruits.isEmpty {
            Text("还没有水果呢！冒险中三星通关可以解锁。")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .padding()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(fruits) { fruit in
                        Button(action: { feed(fruit) }) {
                            Text(fruit.emoji)
                                .font(.system(size: 50))
                                .frame(width: 64, height: 64)
                                .background(
                                    ZStack {
                                        Circle().fill(CartoonColor.ink.opacity(0.9)).offset(y: 3)
                                        Circle().fill(CartoonColor.paper)
                                        Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2.5)
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 80)
        }
    }

    @ViewBuilder
    private var petSwitcherSheet: some View {
        VStack {
            Text("选择宠物")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .padding()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(viewModel.ownedPets(), id: \.noomNumber) { pet in
                        if let noom = NoomCatalog.noom(for: pet.noomNumber) {
                            Button(action: {
                                viewModel.setActive(pet)
                                showSwitcher = false
                            }) {
                                VStack(spacing: 4) {
                                    Image(uiImage: NoomRenderer.image(
                                        for: noom,
                                        expression: .neutral,
                                        size: CGSize(width: 80, height: 80),
                                        stage: pet.stage
                                    ))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    Text(noom.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(CartoonColor.text)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            Button("关闭") { showSwitcher = false }
                .padding()
        }
    }

    private func feed(_ fruit: FruitItem) {
        let result = viewModel.feedActivePet(fruitId: fruit.id)
        floatingXPText = "+\(result.xp)\(result.preferred ? "!" : "")"
        withAnimation(.easeOut(duration: 1.2)) {
            // floatingXPText already animated via transition
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                floatingXPText = nil
            }
        }
        if result.didEvolve {
            showEvolutionEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showEvolutionEffect = false }
            }
        }
    }

    private func stageLabel(_ stage: Int) -> String {
        switch stage {
        case 0: return "幼年"
        case 1: return "少年"
        case 2: return "成年"
        default: return ""
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetFeedingArea — active pet display + XP bar + fruit inventory + feeding interaction"
```

---

# Phase 6: Hatching Area

## Task 11: EggHatchingArea — two-slot mature-Noom merge

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/EggHatchingArea.swift`

- [ ] **Step 1: Create EggHatchingArea**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/EggHatchingArea.swift`:

```swift
import SwiftUI

struct EggHatchingArea: View {
    @Bindable var viewModel: PetGardenViewModel
    @State private var slotA: PetProgress?
    @State private var slotB: PetProgress?
    @State private var showPicker: Int?  // 0 or 1 = which slot is being filled
    @State private var hatchedNoomNumber: Int?
    @State private var showHatchAnimation = false

    private let evolutionLogic = PetEvolutionLogic()

    var body: some View {
        CartoonPanel(cornerRadius: 24) {
            VStack(spacing: 12) {
                Text("🥚 孵蛋大本营")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                HStack(spacing: 18) {
                    slotView(pet: slotA, slotIndex: 0)
                    Text("+").font(.system(size: 32, weight: .black, design: .rounded))
                    slotView(pet: slotB, slotIndex: 1)
                    Text("=").font(.system(size: 32, weight: .black, design: .rounded))
                    resultView
                }

                hatchButton
            }
            .padding(20)
        }
        .sheet(item: Binding(
            get: { showPicker.map { SlotIndex(value: $0) } },
            set: { showPicker = $0?.value }
        )) { wrapper in
            picker(forSlot: wrapper.value)
        }
        .overlay {
            if showHatchAnimation, let n = hatchedNoomNumber, let noom = NoomCatalog.noom(for: n) {
                hatchOverlay(noom: noom)
            }
        }
    }

    private func slotView(pet: PetProgress?, slotIndex: Int) -> some View {
        Button(action: { showPicker = slotIndex }) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.85)).frame(width: 92, height: 92).offset(y: 4)
                Circle().fill(CartoonColor.paper).frame(width: 92, height: 92)
                Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3).frame(width: 92, height: 92)
                if let pet, let noom = NoomCatalog.noom(for: pet.noomNumber) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom,
                        expression: .neutral,
                        size: CGSize(width: 80, height: 80),
                        stage: pet.stage
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                } else {
                    Text("🥚").font(.system(size: 44))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultView: some View {
        let resultNumber: Int? = {
            guard let a = slotA, let b = slotB else { return nil }
            return evolutionLogic.canHatch(matureNoomA: a.noomNumber, matureNoomB: b.noomNumber)
        }()
        ZStack {
            Circle().fill(CartoonColor.ink.opacity(0.5)).frame(width: 92, height: 92).offset(y: 4)
            Circle().fill(CartoonColor.gold.opacity(resultNumber != nil ? 0.7 : 0.2))
                .frame(width: 92, height: 92)
            Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3).frame(width: 92, height: 92)
            if let n = resultNumber {
                Text("\(n)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
            } else {
                Text("?").font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.ink.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private var hatchButton: some View {
        let canHatch: Bool = {
            guard let a = slotA, let b = slotB else { return false }
            guard let result = evolutionLogic.canHatch(matureNoomA: a.noomNumber, matureNoomB: b.noomNumber) else { return false }
            return !viewModel.profile.collectedNooms.contains(where: { $0.noomNumber == result })
        }()
        Button(action: triggerHatch) {
            Text("🐣 孵化！")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .padding(.horizontal, 28).padding(.vertical, 12)
                .background(
                    Capsule().fill(canHatch ? CartoonColor.gold : Color.gray.opacity(0.4))
                )
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!canHatch)
    }

    private func picker(forSlot slot: Int) -> some View {
        let mature = viewModel.maturePets()
        return VStack {
            Text("选一只成年 Noom")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .padding()
            if mature.isEmpty {
                Text("还没有成年 Noom 呢，先把 Noom 喂到 300 XP！")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.6))
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(mature, id: \.noomNumber) { pet in
                            if let noom = NoomCatalog.noom(for: pet.noomNumber) {
                                Button(action: {
                                    if slot == 0 { slotA = pet } else { slotB = pet }
                                    showPicker = nil
                                }) {
                                    VStack {
                                        Image(uiImage: NoomRenderer.image(
                                            for: noom,
                                            expression: .neutral,
                                            size: CGSize(width: 80, height: 80),
                                            stage: 2
                                        ))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        Text(noom.name)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            Button("关闭") { showPicker = nil }.padding()
        }
    }

    private func triggerHatch() {
        guard let a = slotA, let b = slotB else { return }
        if let result = viewModel.tryHatch(petA: a, petB: b) {
            hatchedNoomNumber = result
            showHatchAnimation = true
            slotA = nil
            slotB = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showHatchAnimation = false
                hatchedNoomNumber = nil
            }
        }
    }

    private func hatchOverlay(noom: Noom) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(uiImage: NoomRenderer.image(
                    for: noom,
                    expression: .happy,
                    size: CGSize(width: 200, height: 200),
                    stage: 0
                ))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(showHatchAnimation ? 1.0 : 0.1)
                .animation(.spring(response: 0.6, dampingFraction: 0.55), value: showHatchAnimation)

                Text("\(noom.name) 诞生啦！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private struct SlotIndex: Identifiable {
        let value: Int
        var id: Int { value }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: EggHatchingArea — two-slot mature-Noom picker + hatching animation"
```

---

# Phase 7: PetGardenView Wires Everything Together

## Task 12: PetGardenView — combine feeding + hatching

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenView.swift`

- [ ] **Step 1: Replace placeholder with real PetGardenView**

Replace the entire contents of `NumberOrchard/NumberOrchard/Features/NoomForest/PetGardenView.swift`:

```swift
import SwiftUI
import SwiftData

struct PetGardenView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PetGardenViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let viewModel {
                    PetFeedingArea(viewModel: viewModel)
                    EggHatchingArea(viewModel: viewModel)
                } else {
                    ProgressView()
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PetGardenViewModel(profile: profile, modelContext: modelContext)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: PetGardenView wires PetFeedingArea + EggHatchingArea together"
```

---

# Phase 8: Final Verification

## Task 13: Run full test suite + manual verification list

**Files:** (verification only)

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run with|\*\* TEST|error:" | tail -5
```

Expected: ~98 tests pass (81 existing Noom + 4 new NoomCatalog updates + 4 PetXP + 6 PetEvolution + 4 PetPreference + 3 PetProgress = ~102, depending on existing baseline)

- [ ] **Step 2: If failures, fix inline and re-run**

Common issues to check:
- `xcodegen generate` was run after creating new files
- Schema includes `PetProgress.self`
- ChildProfile.collectedNooms relationship works (no SwiftData migration error)
- NoomForestView still compiles after `dexGrid` change

- [ ] **Step 3: Verify HomeView → 小精灵森林 → 宠物花园 navigation works**

Open the project in Xcode, build, and run on iPad Pro 13" simulator. Manually verify:
1. Tap 🐾 小精灵 button on Home → enters Forest
2. See top-level [图鉴 / 宠物花园] tab picker
3. Tap 宠物花园 → Pet feeding area shows up (or empty-state message if no Nooms collected)
4. If you have collected Nooms (e.g. unlock by playing Noom Challenge), they appear as pets
5. Fruit inventory shows from CollectedFruit
6. Drag/tap fruit → pet feeds, XP bar updates
7. After enough feeding (300 XP), evolution animation triggers, decoration appears

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
cd /Users/samxiao/code/app
git add -A
git diff --cached --quiet || git commit -m "fix: resolve final issues after pet raising integration"
```

---

## Summary

| Phase | Tasks | Tests added |
|-------|-------|-------------|
| 1. Data extension | 1-3 | NoomCatalog (+4), PetPreferenceMap (4) |
| 2. Pure logic | 4-6 | PetXPCalculator (4), PetEvolutionLogic (6), PetProgress (3) |
| 3. Renderer | 7 | — |
| 4. Tab + skeleton | 8 | — |
| 5. Feeding | 9-10 | — |
| 6. Hatching | 11 | — |
| 7. Wire-up | 12 | — |
| 8. Verify | 13 | — |

**Total: 13 tasks**, ~21 new tests, ~8 hour estimated implementation.
