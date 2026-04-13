# Noom 数字小精灵 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 5th gameplay mode "🐾 小精灵森林" (Noom Forest) to Number Orchard — a DragonBox-inspired creature collection game where children merge or split number creatures (Nooms) to learn number composition/decomposition.

**Architecture:** Independent feature area with its own SwiftUI screens (forest + challenge) and a SpriteKit scene for merge/split interactions. Reuses existing `CartoonUI`/`CartoonSpriteKit` design system. Persists collected Nooms via SwiftData (`CollectedNoom @Model` related to existing `ChildProfile`).

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, SwiftData, iPadOS 17.0+, Swift Testing.

---

## File Structure

```
NumberOrchard/NumberOrchard/
├── Core/
│   ├── Models/
│   │   ├── Noom.swift                          (NEW)
│   │   ├── CollectedNoom.swift                 (NEW @Model)
│   │   └── ChildProfile.swift                  (modify: + collectedNooms)
│   ├── NoomLogic/                              (NEW dir)
│   │   ├── NoomMergeLogic.swift
│   │   └── NoomSplitLogic.swift
│   └── AdaptiveEngine/
│       └── NoomQuestionGenerator.swift         (NEW)
├── App/
│   ├── NumberOrchardApp.swift                  (modify: + Schema)
│   └── AppCoordinator.swift                    (modify: + route)
└── Features/
    ├── Home/
    │   └── HomeView.swift                      (modify: + 5th button)
    └── NoomForest/                             (NEW dir)
        ├── NoomRenderer.swift
        ├── NoomForestView.swift
        ├── NoomForestViewModel.swift
        ├── NoomChallengeView.swift
        ├── NoomChallengeScene.swift
        └── NoomChallengeViewModel.swift

NumberOrchardTests/
├── Core/Models/
│   └── NoomCatalogTests.swift                  (NEW)
├── Core/NoomLogic/                             (NEW dir)
│   ├── NoomMergeLogicTests.swift
│   └── NoomSplitLogicTests.swift
├── Core/AdaptiveEngine/
│   └── NoomQuestionGeneratorTests.swift        (NEW)
└── Features/NoomForest/                        (NEW dir)
    └── CollectedNoomTests.swift
```

---

# Phase 1: Data Foundation

## Task 1: Noom struct + catalog (10 entries) + tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/Noom.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/Models/NoomCatalogTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/Models/NoomCatalogTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func catalogHasTenNooms() {
    #expect(NoomCatalog.all.count == 10)
}

@Test func noomNumbersAreOneThroughTen() {
    let numbers = NoomCatalog.all.map(\.number).sorted()
    #expect(numbers == Array(1...10))
}

@Test func noomNamesAreUnique() {
    let names = NoomCatalog.all.map(\.name)
    #expect(Set(names).count == names.count)
}

@Test func lookupByNumberWorks() {
    #expect(NoomCatalog.noom(for: 1)?.name == "小一")
    #expect(NoomCatalog.noom(for: 10)?.name == "十全")
    #expect(NoomCatalog.noom(for: 0) == nil)
    #expect(NoomCatalog.noom(for: 11) == nil)
}

@Test func everyNoomHasNonEmptyCatchphrase() {
    for noom in NoomCatalog.all {
        #expect(!noom.catchphrase.isEmpty, "Noom \(noom.number) missing catchphrase")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomCatalogTests 2>&1 | tail -10
```

Expected: FAIL — `NoomCatalog` not defined

- [ ] **Step 3: Create Noom.swift**

Create `NumberOrchard/NumberOrchard/Core/Models/Noom.swift`:

```swift
import Foundation
import UIKit

struct Noom: Identifiable, Sendable, Hashable {
    let number: Int          // 1-10
    let name: String
    let bodyColor: UIColor
    let catchphrase: String
    var id: Int { number }
}

extension Noom {
    static func == (lhs: Noom, rhs: Noom) -> Bool { lhs.number == rhs.number }
    func hash(into hasher: inout Hasher) { hasher.combine(number) }
}

enum NoomCatalog {
    static let all: [Noom] = [
        .init(number: 1,  name: "小一", bodyColor: UIColor(red: 1.00, green: 0.60, blue: 0.64, alpha: 1.0),
              catchphrase: "我是一个，就一个哦！"),
        .init(number: 2,  name: "贝贝", bodyColor: UIColor(red: 0.66, green: 0.90, blue: 0.81, alpha: 1.0),
              catchphrase: "两个好朋友一起！"),
        .init(number: 3,  name: "朵朵", bodyColor: UIColor(red: 1.00, green: 0.85, blue: 0.44, alpha: 1.0),
              catchphrase: "三朵小花朵！"),
        .init(number: 4,  name: "汪汪", bodyColor: UIColor(red: 0.64, green: 0.85, blue: 1.00, alpha: 1.0),
              catchphrase: "四个角的房子！"),
        .init(number: 5,  name: "妮妮", bodyColor: UIColor(red: 1.00, green: 0.69, blue: 0.53, alpha: 1.0),
              catchphrase: "五个手指数一数！"),
        .init(number: 6,  name: "六六", bodyColor: UIColor(red: 0.79, green: 0.69, blue: 1.00, alpha: 1.0),
              catchphrase: "六六大顺～"),
        .init(number: 7,  name: "奇奇", bodyColor: UIColor(red: 0.83, green: 0.95, blue: 0.55, alpha: 1.0),
              catchphrase: "七彩的我最闪亮！"),
        .init(number: 8,  name: "胖胖", bodyColor: UIColor(red: 1.00, green: 0.66, blue: 0.66, alpha: 1.0),
              catchphrase: "圆圆滚滚的八！"),
        .init(number: 9,  name: "九妹", bodyColor: UIColor(red: 0.56, green: 0.86, blue: 0.90, alpha: 1.0),
              catchphrase: "快要到十啦！"),
        .init(number: 10, name: "十全", bodyColor: UIColor(red: 1.00, green: 0.84, blue: 0.20, alpha: 1.0),
              catchphrase: "我是大王十全！"),
    ]

    static func noom(for n: Int) -> Noom? {
        all.first { $0.number == n }
    }
}
```

- [ ] **Step 4: Run xcodegen + tests to verify they pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomCatalogTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 5 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: add Noom struct and NoomCatalog with 10 creature definitions"
```

---

## Task 2: CollectedNoom @Model + ChildProfile relationship

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/Models/CollectedNoom.swift`
- Modify: `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`
- Modify: `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift`

- [ ] **Step 1: Create CollectedNoom @Model**

Create `NumberOrchard/NumberOrchard/Core/Models/CollectedNoom.swift`:

```swift
import Foundation
import SwiftData

@Model
final class CollectedNoom {
    var noomNumber: Int
    var unlockedAt: Date
    var encounterCount: Int

    @Relationship(inverse: \ChildProfile.collectedNooms)
    var profile: ChildProfile?

    init(noomNumber: Int) {
        self.noomNumber = noomNumber
        self.unlockedAt = Date()
        self.encounterCount = 1
    }
}
```

- [ ] **Step 2: Add relationship to ChildProfile**

In `NumberOrchard/NumberOrchard/Core/Models/ChildProfile.swift`, find:

```swift
    @Relationship(deleteRule: .cascade)
    var collectedFruits: [CollectedFruit] = []
```

Add immediately after:

```swift

    @Relationship(deleteRule: .cascade)
    var collectedNooms: [CollectedNoom] = []
```

- [ ] **Step 3: Register schema**

In `NumberOrchard/NumberOrchard/App/NumberOrchardApp.swift`, find:

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
        ])
```

- [ ] **Step 4: Build and verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Run all tests to make sure nothing broke**

```bash
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run|\*\* TEST|error:" | tail -3
```

Expected: All existing tests pass + 5 new NoomCatalog tests = 62+ tests passing

- [ ] **Step 6: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: CollectedNoom @Model + ChildProfile relationship + schema registration"
```

---

# Phase 2: Pure Logic

## Task 3: NoomMergeLogic + tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/NoomLogic/NoomMergeLogic.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/NoomLogic/NoomMergeLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/NoomLogic/NoomMergeLogicTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func mergeValidPairsReturnsSum() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 1, b: 1) == 2)
    #expect(logic.merge(a: 2, b: 3) == 5)
    #expect(logic.merge(a: 4, b: 6) == 10)
}

@Test func mergeRejectsZeroOrNegative() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 0, b: 3) == nil)
    #expect(logic.merge(a: 3, b: 0) == nil)
    #expect(logic.merge(a: -1, b: 5) == nil)
}

@Test func mergeRejectsSumOverTen() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 5, b: 6) == nil)
    #expect(logic.merge(a: 9, b: 9) == nil)
    #expect(logic.merge(a: 10, b: 1) == nil)
}

@Test func mergeIsCommutative() {
    let logic = NoomMergeLogic()
    #expect(logic.merge(a: 3, b: 4) == logic.merge(a: 4, b: 3))
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomMergeLogicTests 2>&1 | tail -10
```

Expected: FAIL — `NoomMergeLogic` not found

- [ ] **Step 3: Implement NoomMergeLogic**

Create `NumberOrchard/NumberOrchard/Core/NoomLogic/NoomMergeLogic.swift`:

```swift
import Foundation

struct NoomMergeLogic: Sendable {
    /// Combine two Nooms. Returns nil for invalid inputs (sum > 10 or operands < 1).
    func merge(a: Int, b: Int) -> Int? {
        guard a >= 1, b >= 1, a + b <= 10 else { return nil }
        return a + b
    }
}
```

- [ ] **Step 4: Verify all tests pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomMergeLogicTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomMergeLogic with sum cap of 10 and positive-operand validation"
```

---

## Task 4: NoomSplitLogic + tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/NoomLogic/NoomSplitLogic.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/NoomLogic/NoomSplitLogicTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/NoomLogic/NoomSplitLogicTests.swift`:

```swift
import Testing
import CoreFoundation
@testable import NumberOrchard

@Test func splitMapsDragDistanceToRatio() {
    let logic = NoomSplitLogic()
    // total=5 has 4 segments (1+4, 2+3, 3+2, 4+1), each ~22.5pt wide
    let r1 = logic.splitFor(total: 5, dragDistance: 5)
    #expect(r1?.0 == 1 && r1?.1 == 4)
    let r2 = logic.splitFor(total: 5, dragDistance: 30)
    #expect(r2?.0 == 2 && r2?.1 == 3)
    let r3 = logic.splitFor(total: 5, dragDistance: 80)
    #expect(r3?.0 == 4 && r3?.1 == 1)
}

@Test func splitClampsToMinFirst() {
    let logic = NoomSplitLogic()
    // dragDistance 0 still gives at least (1, total-1)
    let r = logic.splitFor(total: 5, dragDistance: 0)
    #expect(r?.0 == 1 && r?.1 == 4)
}

@Test func splitClampsToMaxLast() {
    let logic = NoomSplitLogic()
    let r = logic.splitFor(total: 5, dragDistance: 200)
    #expect(r?.0 == 4 && r?.1 == 1)
}

@Test func splitRejectsInvalidTotal() {
    let logic = NoomSplitLogic()
    #expect(logic.splitFor(total: 1, dragDistance: 50) == nil)
    #expect(logic.splitFor(total: 0, dragDistance: 50) == nil)
    #expect(logic.splitFor(total: 11, dragDistance: 50) == nil)
}

@Test func allSplitsEnumerated() {
    let logic = NoomSplitLogic()
    let splits = logic.allSplits(of: 5)
    let pairs = splits.map { "\($0.0)+\($0.1)" }.sorted()
    #expect(pairs == ["1+4", "2+3", "3+2", "4+1"])
}

@Test func allSplitsEmptyForLessThanTwo() {
    let logic = NoomSplitLogic()
    #expect(logic.allSplits(of: 1).isEmpty)
    #expect(logic.allSplits(of: 0).isEmpty)
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomSplitLogicTests 2>&1 | tail -10
```

Expected: FAIL

- [ ] **Step 3: Implement NoomSplitLogic**

Create `NumberOrchard/NumberOrchard/Core/NoomLogic/NoomSplitLogic.swift`:

```swift
import Foundation
import CoreFoundation

struct NoomSplitLogic: Sendable {
    /// Map drag distance (pt) to a (left, right) split where left + right == total.
    /// Drag range 0–90pt mapped to (total-1) segments.
    func splitFor(total: Int, dragDistance: CGFloat) -> (Int, Int)? {
        guard (2...10).contains(total) else { return nil }
        let segments = total - 1
        let segmentSize = 90.0 / CGFloat(segments)
        let raw = Int(dragDistance / segmentSize) + 1
        let idx = min(segments, max(1, raw))
        return (idx, total - idx)
    }

    /// All legal (a, b) splits where a + b == n and both ≥ 1.
    func allSplits(of n: Int) -> [(Int, Int)] {
        guard n >= 2 else { return [] }
        return (1..<n).map { ($0, n - $0) }
    }
}
```

- [ ] **Step 4: Verify tests pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomSplitLogicTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 6 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomSplitLogic — drag-distance to ratio mapping + enumerate all splits"
```

---

## Task 5: NoomQuestionGenerator + tests

**Files:**
- Create: `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/NoomQuestionGenerator.swift`
- Create: `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/NoomQuestionGeneratorTests.swift`

- [ ] **Step 1: Write failing tests**

Create `NumberOrchard/NumberOrchardTests/Core/AdaptiveEngine/NoomQuestionGeneratorTests.swift`:

```swift
import Testing
@testable import NumberOrchard

@Test func sessionHasFiveQuestions() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    #expect(session.count == 5)
}

@Test func sessionHasOneSplitQuestion() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    let splitCount = session.filter { if case .split = $0 { return true } else { return false } }.count
    #expect(splitCount == 1)
}

@Test func sessionHasFourMergeQuestions() {
    let gen = NoomQuestionGenerator()
    let session = gen.generateSession(alreadyUnlocked: [])
    let mergeCount = session.filter { if case .merge = $0 { return true } else { return false } }.count
    #expect(mergeCount == 4)
}

@Test func mergeQuestionsRespectSumLimits() {
    let gen = NoomQuestionGenerator()
    for _ in 0..<20 {
        let session = gen.generateSession(alreadyUnlocked: [])
        for (idx, q) in session.enumerated() {
            if case .merge(let a, let b) = q {
                #expect(a >= 1 && b >= 1)
                let sum = a + b
                if idx < 2 {
                    #expect(sum <= 5, "Q\(idx+1) merge \(a)+\(b)=\(sum) should be ≤ 5")
                } else {
                    #expect(sum <= 10, "Q\(idx+1) merge \(a)+\(b)=\(sum) should be ≤ 10")
                }
            }
        }
    }
}

@Test func splitQuestionInRange() {
    let gen = NoomQuestionGenerator()
    for _ in 0..<10 {
        let session = gen.generateSession(alreadyUnlocked: [])
        for q in session {
            if case .split(let total) = q {
                #expect((3...5).contains(total), "split total \(total) should be in 3...5")
            }
        }
    }
}

@Test func challengeTypesEquatable() {
    #expect(NoomChallengeType.merge(a: 2, b: 3) == .merge(a: 2, b: 3))
    #expect(NoomChallengeType.merge(a: 2, b: 3) != .merge(a: 3, b: 2))
    #expect(NoomChallengeType.split(total: 5) != .merge(a: 2, b: 3))
}
```

- [ ] **Step 2: Run tests to verify failure**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomQuestionGeneratorTests 2>&1 | tail -10
```

Expected: FAIL

- [ ] **Step 3: Implement NoomQuestionGenerator**

Create `NumberOrchard/NumberOrchard/Core/AdaptiveEngine/NoomQuestionGenerator.swift`:

```swift
import Foundation

enum NoomChallengeType: Sendable, Equatable {
    case merge(a: Int, b: Int)
    case split(total: Int)
}

struct NoomQuestionGenerator: Sendable {
    /// Generate 5 questions: Q1-Q2 merge ≤5, Q3 split, Q4-Q5 merge ≤10.
    /// Prefers Nooms that haven't been unlocked yet (3x weight).
    func generateSession(alreadyUnlocked: Set<Int>) -> [NoomChallengeType] {
        var session: [NoomChallengeType] = []
        // Q1 and Q2: merge with sum ≤ 5
        session.append(generateMerge(maxSum: 5, alreadyUnlocked: alreadyUnlocked))
        session.append(generateMerge(maxSum: 5, alreadyUnlocked: alreadyUnlocked))
        // Q3: split with total in 3...5
        session.append(generateSplit(alreadyUnlocked: alreadyUnlocked))
        // Q4 and Q5: merge with sum ≤ 10
        session.append(generateMerge(maxSum: 10, alreadyUnlocked: alreadyUnlocked))
        session.append(generateMerge(maxSum: 10, alreadyUnlocked: alreadyUnlocked))
        return session
    }

    private func generateMerge(maxSum: Int, alreadyUnlocked: Set<Int>) -> NoomChallengeType {
        // Build all (a, b) pairs with a >= 1, b >= 1, a+b in 2...maxSum.
        var weighted: [((Int, Int), Int)] = []
        for a in 1..<maxSum {
            for b in 1...(maxSum - a) {
                let sum = a + b
                let weight = alreadyUnlocked.contains(sum) ? 1 : 3
                weighted.append(((a, b), weight))
            }
        }
        let pick = weightedRandom(weighted)
        return .merge(a: pick.0, b: pick.1)
    }

    private func generateSplit(alreadyUnlocked: Set<Int>) -> NoomChallengeType {
        var weighted: [(Int, Int)] = []
        for total in 3...5 {
            let weight = alreadyUnlocked.contains(total) ? 1 : 3
            weighted.append((total, weight))
        }
        return .split(total: weightedRandom(weighted))
    }

    private func weightedRandom<T>(_ items: [(T, Int)]) -> T {
        let totalWeight = items.reduce(0) { $0 + $1.1 }
        var roll = Int.random(in: 0..<max(totalWeight, 1))
        for (item, weight) in items {
            roll -= weight
            if roll < 0 { return item }
        }
        return items.last!.0
    }
}
```

- [ ] **Step 4: Verify tests pass**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/NoomQuestionGeneratorTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 6 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomQuestionGenerator with 2 merge + 1 split + 2 merge structure"
```

---

## Task 6: CollectedNoom unlock logic test

**Files:**
- Create: `NumberOrchard/NumberOrchardTests/Features/NoomForest/CollectedNoomTests.swift`

- [ ] **Step 1: Write tests for unlock semantics**

Create `NumberOrchard/NumberOrchardTests/Features/NoomForest/CollectedNoomTests.swift`:

```swift
import Testing
import SwiftData
@testable import NumberOrchard

@Test @MainActor func collectedNoomInitDefaults() {
    let cn = CollectedNoom(noomNumber: 5)
    #expect(cn.noomNumber == 5)
    #expect(cn.encounterCount == 1)
}

@Test @MainActor func encounterCountCanBeIncremented() {
    let cn = CollectedNoom(noomNumber: 3)
    cn.encounterCount += 1
    cn.encounterCount += 1
    #expect(cn.encounterCount == 3)
}
```

- [ ] **Step 2: Run tests, expect PASS (just init verification)**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO -only-testing:NumberOrchardTests/CollectedNoomTests 2>&1 | grep -E "passed|failed|\*\* TEST"
```

Expected: 2 tests PASS

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: CollectedNoom basic init/increment tests"
```

---

# Phase 3: Visual

## Task 7: NoomRenderer (program-generated creature image)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomRenderer.swift`

- [ ] **Step 1: Create renderer**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomRenderer.swift`:

```swift
import UIKit
import SpriteKit

enum NoomExpression: Sendable {
    case neutral
    case happy
    case surprised
}

enum NoomRenderer {
    /// Render a Noom creature image at the given size.
    /// Body diameter scales subtly with `noom.number` so larger Nooms look chunkier.
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

    private static func drawShadow(in ctx: CGContext, size: CGSize) {
        let rect = CGRect(x: 8, y: 14, width: size.width - 16, height: size.height - 16)
        let shadow = UIBezierPath(ovalIn: rect)
        UIColor.black.withAlphaComponent(0.4).setFill()
        shadow.fill()
    }

    private static func drawBody(in ctx: CGContext, size: CGSize, color: UIColor) {
        let bodyRect = CGRect(x: 8, y: 4, width: size.width - 16, height: size.height - 16)
        let body = UIBezierPath(ovalIn: bodyRect)

        ctx.saveGState()
        body.addClip()
        let lighter = color.lighter(by: 0.18)
        let colors = [lighter.cgColor, color.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient,
                start: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                end: CGPoint(x: bodyRect.midX, y: bodyRect.maxY),
                options: [])
        }
        ctx.restoreGState()

        UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85).setStroke()
        body.lineWidth = 4
        body.stroke()

        // Top highlight
        let highlightRect = CGRect(x: bodyRect.minX + 16, y: bodyRect.minY + 14, width: 30, height: 12)
        let highlight = UIBezierPath(ovalIn: highlightRect)
        UIColor.white.withAlphaComponent(0.45).setFill()
        highlight.fill()
    }

    private static func drawSpots(in ctx: CGContext, size: CGSize, count: Int) {
        // Pseudo-random but stable spot positions (same seed each call for same count).
        var rng = SeededRNG(seed: UInt64(count * 31))
        let bodyRect = CGRect(x: 12, y: 8, width: size.width - 24, height: size.height - 24)
        let spotRadius: CGFloat = 5
        UIColor.white.withAlphaComponent(0.85).setFill()

        for _ in 0..<count {
            let r: CGFloat = .random(in: 0...(min(bodyRect.width, bodyRect.height) / 3 - 4), using: &rng)
            let angle: CGFloat = .random(in: 0...(.pi * 2), using: &rng)
            let cx = bodyRect.midX + cos(angle) * r
            let cy = bodyRect.midY + sin(angle) * r * 0.8 + 8
            let spot = UIBezierPath(ovalIn: CGRect(x: cx - spotRadius, y: cy - spotRadius,
                                                   width: spotRadius * 2, height: spotRadius * 2))
            spot.fill()
        }
    }

    private static func drawFace(in ctx: CGContext, size: CGSize, expression: NoomExpression) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.45)
        let eyeOffset: CGFloat = 16
        let eyeRadius: CGFloat = expression == .surprised ? 7 : 5
        UIColor.black.setFill()

        for dx in [-eyeOffset, eyeOffset] {
            let eyeRect = CGRect(x: center.x + dx - eyeRadius,
                                 y: center.y - eyeRadius,
                                 width: eyeRadius * 2, height: eyeRadius * 2)
            UIBezierPath(ovalIn: eyeRect).fill()
            // Eye glint
            let glint = UIBezierPath(ovalIn: CGRect(x: eyeRect.minX + 2, y: eyeRect.minY + 1, width: 2, height: 2))
            UIColor.white.setFill()
            glint.fill()
            UIColor.black.setFill()
        }

        // Mouth
        let mouthY = center.y + 16
        let mouth = UIBezierPath()
        switch expression {
        case .neutral:
            mouth.move(to: CGPoint(x: center.x - 8, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: center.x + 8, y: mouthY),
                              controlPoint: CGPoint(x: center.x, y: mouthY + 4))
        case .happy:
            mouth.move(to: CGPoint(x: center.x - 14, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: center.x + 14, y: mouthY),
                              controlPoint: CGPoint(x: center.x, y: mouthY + 12))
        case .surprised:
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: center.x - 6, y: mouthY - 4, width: 12, height: 16)).fill()
            return
        }
        UIColor.black.setStroke()
        mouth.lineWidth = 3
        mouth.stroke()
    }

    private static func drawNumberBadge(in ctx: CGContext, size: CGSize, number: Int) {
        let badgeRect = CGRect(x: size.width - 32, y: size.height - 36, width: 28, height: 28)
        let badge = UIBezierPath(ovalIn: badgeRect)
        UIColor.white.setFill()
        badge.fill()
        UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85).setStroke()
        badge.lineWidth = 2.5
        badge.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Semibold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        ]
        let text = "\(number)"
        let textSize = text.size(withAttributes: attrs)
        let textRect = CGRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width, height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attrs)
    }
}

/// Tiny seeded RNG so spot positions are stable across renders.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 1 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomRenderer — program-generated creature with body, spots, face, number badge"
```

---

# Phase 4: SpriteKit Challenge Scene

## Task 8: NoomChallengeScene base + merge interaction

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeScene.swift`

- [ ] **Step 1: Create scene with merge logic**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeScene.swift`:

```swift
import SpriteKit

@MainActor
protocol NoomChallengeSceneDelegate: AnyObject {
    /// Called when a question completes. unlockedNumbers includes any Nooms revealed (could be 1 for merge, 2 for split).
    func noomChallengeDidComplete(unlockedNumbers: [Int])
}

class NoomChallengeScene: SKScene {
    weak var sceneDelegate: NoomChallengeSceneDelegate?

    private var challenge: NoomChallengeType!
    private var questionLabel: SKNode!
    private var noomNodes: [SKSpriteNode] = []
    private var noomNumbers: [SKSpriteNode: Int] = [:]
    private var noomHomePositions: [SKSpriteNode: CGPoint] = [:]
    private var draggingNoom: SKSpriteNode?
    private var dragStartPosition: CGPoint = .zero
    private var splitPreviewLabel: SKLabelNode?
    private var isCompleted = false

    private let noomImageSize = CGSize(width: 140, height: 140)
    private let mergeLogic = NoomMergeLogic()
    private let splitLogic = NoomSplitLogic()

    func configure(with challenge: NoomChallengeType) {
        self.challenge = challenge
    }

    override func didMove(to view: SKView) {
        backgroundColor = CartoonSK.skyTop
        view.preferredFramesPerSecond = 60
        setupBackground()
        setupQuestion()
        switch challenge {
        case .merge(let a, let b):
            setupMerge(a: a, b: b)
        case .split(let total):
            setupSplit(total: total)
        case .none:
            break
        }
    }

    private func setupBackground() {
        let bg = SKSpriteNode(texture: CartoonSKTextureCache.skyGradient(size: size))
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        addChild(bg)
    }

    private var safeAreaTop: CGFloat { view?.safeAreaInsets.top ?? 0 }

    private func setupQuestion() {
        let text: String
        switch challenge {
        case .merge(let a, let b):
            let nameA = NoomCatalog.noom(for: a)?.name ?? "\(a)"
            let nameB = NoomCatalog.noom(for: b)?.name ?? "\(b)"
            text = "把 \(nameA) 和 \(nameB) 合在一起！"
        case .split(let total):
            let name = NoomCatalog.noom(for: total)?.name ?? "\(total)"
            text = "把 \(name) 向下拖拽分开！"
        case .none:
            text = ""
        }
        questionLabel = SKNode.cartoonPillLabel(text: text, fontSize: 26)
        questionLabel.position = CGPoint(x: size.width / 2, y: size.height - safeAreaTop - 50)
        addChild(questionLabel)
    }

    private func setupMerge(a: Int, b: Int) {
        guard let noomA = NoomCatalog.noom(for: a), let noomB = NoomCatalog.noom(for: b) else { return }
        let leftPos = CGPoint(x: size.width * 0.32, y: size.height * 0.45)
        let rightPos = CGPoint(x: size.width * 0.68, y: size.height * 0.45)
        let nodeA = makeNoomNode(noom: noomA, expression: .neutral)
        let nodeB = makeNoomNode(noom: noomB, expression: .neutral)
        nodeA.position = leftPos
        nodeB.position = rightPos
        addChild(nodeA); addChild(nodeB)
        noomNodes = [nodeA, nodeB]
        noomNumbers = [nodeA: a, nodeB: b]
        noomHomePositions = [nodeA: leftPos, nodeB: rightPos]

        addBreathingAction(to: nodeA)
        addBreathingAction(to: nodeB)
    }

    private func setupSplit(total: Int) {
        guard let noom = NoomCatalog.noom(for: total) else { return }
        let pos = CGPoint(x: size.width / 2, y: size.height * 0.50)
        let node = makeNoomNode(noom: noom, expression: .neutral)
        node.position = pos
        addChild(node)
        noomNodes = [node]
        noomNumbers = [node: total]
        noomHomePositions = [node: pos]

        // Visual cue: dashed line under the noom suggesting "drag down"
        let cuePath = CGMutablePath()
        cuePath.move(to: CGPoint(x: pos.x - 60, y: pos.y - 100))
        cuePath.addLine(to: CGPoint(x: pos.x + 60, y: pos.y - 100))
        let cueShape = SKShapeNode(path: cuePath)
        cueShape.strokeColor = CartoonSK.ink.withAlphaComponent(0.4)
        cueShape.lineWidth = 4
        let dashPattern: [CGFloat] = [10, 8]
        cueShape.path = cuePath.copy(dashingWithPhase: 0, lengths: dashPattern)
        addChild(cueShape)

        addBreathingAction(to: node)
    }

    private func makeNoomNode(noom: Noom, expression: NoomExpression) -> SKSpriteNode {
        let img = NoomRenderer.image(for: noom, expression: expression, size: noomImageSize)
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.size = noomImageSize
        node.name = "noom_\(noom.number)"
        return node
    }

    private func addBreathingAction(to node: SKSpriteNode) {
        let action = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 1.2),
            SKAction.scale(to: 1.0, duration: 1.2)
        ])
        node.run(SKAction.repeatForever(action))
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCompleted, let location = touches.first?.location(in: self) else { return }

        let padding = CartoonSKTouch.largeHitPadding
        var best: SKSpriteNode?
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for node in noomNodes where node.parent != nil {
            let expanded = node.frame.insetBy(dx: -padding, dy: -padding)
            guard expanded.contains(location) else { continue }
            let dx = node.position.x - location.x
            let dy = node.position.y - location.y
            let d = dx * dx + dy * dy
            if d < bestDist { bestDist = d; best = node }
        }
        if let node = best {
            draggingNoom = node
            dragStartPosition = node.position
            node.removeAllActions()
            node.zPosition = 100
            node.run(SKAction.scale(to: 1.15, duration: 0.1))

            // For split, change to surprised expression
            if case .split(let total) = challenge {
                if let noom = NoomCatalog.noom(for: total) {
                    let surprisedImg = NoomRenderer.image(for: noom, expression: .surprised, size: noomImageSize)
                    node.texture = SKTexture(image: surprisedImg)
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNoom else { return }
        node.position = touch.location(in: self)

        // For split, show preview of (a, b) based on downward drag distance
        if case .split(let total) = challenge {
            let downDistance = max(0, dragStartPosition.y - node.position.y)
            if let (a, b) = splitLogic.splitFor(total: total, dragDistance: downDistance) {
                showSplitPreview(text: "\(a) 和 \(b)")
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = draggingNoom else { return }
        draggingNoom = nil

        switch challenge {
        case .merge(let a, let b):
            handleMergeRelease(node: node, a: a, b: b)
        case .split(let total):
            handleSplitRelease(node: node, total: total)
        case .none:
            break
        }
    }

    private func handleMergeRelease(node: SKSpriteNode, a: Int, b: Int) {
        // Did this node land near the OTHER noom?
        guard let other = noomNodes.first(where: { $0 !== node }) else { return }
        let distance = hypot(node.position.x - other.position.x, node.position.y - other.position.y)
        if distance < 120 {
            performMerge(nodeA: node, nodeB: other, a: a, b: b)
        } else {
            snapBack(node: node)
        }
    }

    private func handleSplitRelease(node: SKSpriteNode, total: Int) {
        let downDistance = max(0, dragStartPosition.y - node.position.y)
        if downDistance < 25 {
            // Not enough drag — snap back, restore neutral
            if let noom = NoomCatalog.noom(for: total) {
                let img = NoomRenderer.image(for: noom, expression: .neutral, size: noomImageSize)
                node.texture = SKTexture(image: img)
            }
            snapBack(node: node)
            removeSplitPreview()
            return
        }
        guard let (a, b) = splitLogic.splitFor(total: total, dragDistance: downDistance) else {
            snapBack(node: node)
            return
        }
        performSplit(node: node, total: total, a: a, b: b)
    }

    private func snapBack(node: SKSpriteNode) {
        node.zPosition = 0
        if let home = noomHomePositions[node] {
            node.run(SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.18),
                SKAction.move(to: home, duration: 0.22)
            ]))
        }
        addBreathingAction(to: node)
    }

    private func showSplitPreview(text: String) {
        if splitPreviewLabel == nil {
            let label = SKLabelNode(fontNamed: CartoonSK.chineseFont())
            label.fontSize = 36
            label.fontColor = CartoonSK.text
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
            label.zPosition = 200
            addChild(label)
            splitPreviewLabel = label
        }
        splitPreviewLabel?.text = text
    }

    private func removeSplitPreview() {
        splitPreviewLabel?.removeFromParent()
        splitPreviewLabel = nil
    }

    private func performMerge(nodeA: SKSpriteNode, nodeB: SKSpriteNode, a: Int, b: Int) {
        guard let resultNumber = mergeLogic.merge(a: a, b: b),
              let resultNoom = NoomCatalog.noom(for: resultNumber) else {
            snapBack(node: nodeA)
            return
        }
        isCompleted = true
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))
        Task { @MainActor in
            AudioManager.shared.speakEquation(MathQuestion(operand1: a, operand2: b, operation: .add, gameMode: .pickFruit))
        }

        // Animate A and B colliding at midpoint
        let mid = CGPoint(x: (nodeA.position.x + nodeB.position.x) / 2,
                          y: (nodeA.position.y + nodeB.position.y) / 2)
        nodeA.removeAllActions()
        nodeB.removeAllActions()
        nodeA.run(SKAction.sequence([
            SKAction.move(to: mid, duration: 0.2),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))
        nodeB.run(SKAction.sequence([
            SKAction.move(to: mid, duration: 0.2),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))

        // After collision, spawn new merged Noom
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                guard let self else { return }
                let newNode = self.makeNoomNode(noom: resultNoom, expression: .happy)
                newNode.position = mid
                newNode.setScale(0.1)
                self.addChild(newNode)
                newNode.run(SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.25),
                    SKAction.scale(to: 1.0, duration: 0.15)
                ]))
                self.showEquation(text: "\(a) + \(b) = \(resultNumber)")
            },
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                self?.sceneDelegate?.noomChallengeDidComplete(unlockedNumbers: [resultNumber])
            }
        ]))
    }

    private func performSplit(node: SKSpriteNode, total: Int, a: Int, b: Int) {
        guard let noomA = NoomCatalog.noom(for: a), let noomB = NoomCatalog.noom(for: b) else { return }
        isCompleted = true
        removeSplitPreview()
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        let originalPos = node.position
        node.removeAllActions()
        node.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                guard let self else { return }
                let leftNode = self.makeNoomNode(noom: noomA, expression: .happy)
                let rightNode = self.makeNoomNode(noom: noomB, expression: .happy)
                leftNode.position = originalPos
                rightNode.position = originalPos
                leftNode.setScale(0.1)
                rightNode.setScale(0.1)
                self.addChild(leftNode)
                self.addChild(rightNode)
                leftNode.run(SKAction.group([
                    SKAction.move(by: CGVector(dx: -130, dy: 0), duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ]))
                rightNode.run(SKAction.group([
                    SKAction.move(by: CGVector(dx: 130, dy: 0), duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ]))
                self.showEquation(text: "\(total) = \(a) + \(b)")
            },
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                self?.sceneDelegate?.noomChallengeDidComplete(unlockedNumbers: [a, b, total])
            }
        ]))
    }

    private func showEquation(text: String) {
        let label = SKNode.cartoonPillLabel(text: text, fontSize: 38, fill: CartoonSK.gold)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        label.setScale(0.1)
        label.zPosition = 250
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomChallengeScene with merge and split interactions"
```

---

# Phase 5: SwiftUI Forest Pages

## Task 9: NoomChallengeView (SwiftUI wrapper)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeView.swift`

- [ ] **Step 1: Create wrapper**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeView.swift`:

```swift
import SwiftUI
import SpriteKit

struct NoomChallengeView: View {
    let challenge: NoomChallengeType
    let onComplete: ([Int]) -> Void

    @State private var scene: NoomChallengeScene?
    @State private var coordinator: NoomChallengeCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = NoomChallengeScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: challenge)
                        let coord = NoomChallengeCoordinator(onComplete: onComplete)
                        newScene.sceneDelegate = coord
                        coordinator = coord
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class NoomChallengeCoordinator: NSObject, NoomChallengeSceneDelegate {
    let onComplete: ([Int]) -> Void
    init(onComplete: @escaping ([Int]) -> Void) { self.onComplete = onComplete }
    func noomChallengeDidComplete(unlockedNumbers: [Int]) {
        onComplete(unlockedNumbers)
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomChallengeView SwiftUI wrapper for NoomChallengeScene"
```

---

## Task 10: NoomChallengeViewModel (5-question session control)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeViewModel.swift`

- [ ] **Step 1: Create view model**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeViewModel.swift`:

```swift
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

    /// Nooms that were newly unlocked during this session (for the result screen).
    var newlyUnlockedNooms: [Noom] = []

    /// Total stars/seeds awarded this session.
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
        // Award unlocks
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
                starsEarned += 1   // first-time unlock bonus
            }
        }

        questionsCompleted += 1
        if questionsCompleted >= totalQuestions {
            // 5-question completion bonus
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
```

- [ ] **Step 2: Build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomChallengeViewModel — 5-question session, unlock tracking, reward distribution"
```

---

## Task 11: NoomForestView with dex grid

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestView.swift`
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestViewModel.swift`

- [ ] **Step 1: Create NoomForestViewModel**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestViewModel.swift`:

```swift
import SwiftUI
import Observation

@Observable
@MainActor
final class NoomForestViewModel {
    let profile: ChildProfile

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

- [ ] **Step 2: Create NoomForestView**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomForestView.swift`:

```swift
import SwiftUI
import SwiftData

struct NoomForestView: View {
    let onDismiss: () -> Void
    let onStartChallenge: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var viewModel: NoomForestViewModel?
    @State private var inspectedNoom: Noom?

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 24) {
                topBar

                Text("🐾 小精灵森林")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                Text("图鉴: \(viewModel?.unlockedCount ?? 0) / 10")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.7))

                dexGrid

                Spacer()

                CartoonButton(
                    tint: CartoonColor.gold,
                    accessibilityLabel: "开始挑战",
                    action: onStartChallenge
                ) {
                    Text("🎮 开始挑战")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 260, height: 76)
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            if let profile { viewModel = NoomForestViewModel(profile: profile) }
        }
        .sheet(item: $inspectedNoom) { noom in
            noomDetailSheet(noom: noom)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 60, height: 60).offset(y: 4)
                    Circle().fill(CartoonColor.paper).frame(width: 60, height: 60)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 60, height: 60)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            CartoonHUD(icon: "star.fill", value: "\(profile?.stars ?? 0)", tint: CartoonColor.gold)
            CartoonHUD(icon: "leaf.fill", value: "\(profile?.seeds ?? 0)", tint: CartoonColor.leaf)
        }
        .padding(.top, 20)
    }

    private var dexGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
            ForEach(NoomCatalog.all) { noom in
                noomCell(noom: noom)
                    .onTapGesture {
                        if viewModel?.isUnlocked(noom.number) ?? false {
                            inspectedNoom = noom
                        }
                    }
            }
        }
    }

    private func noomCell(noom: Noom) -> some View {
        let unlocked = viewModel?.isUnlocked(noom.number) ?? false
        return ZStack {
            Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 110, height: 110).offset(y: 5)
            Circle().fill(unlocked ? Color(uiColor: noom.bodyColor) : Color.gray.opacity(0.4))
                .frame(width: 110, height: 110)
            Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 110, height: 110)
            if unlocked {
                Image(uiImage: NoomRenderer.image(for: noom, expression: .neutral, size: CGSize(width: 100, height: 100)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(CartoonColor.ink.opacity(0.55))
            }
        }
    }

    private func noomDetailSheet(noom: Noom) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: NoomRenderer.image(for: noom, expression: .happy, size: CGSize(width: 200, height: 200)))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text(noom.name)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
            Text("我是数字 \(noom.number)！")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            CartoonPanel(cornerRadius: 20) {
                Text(noom.catchphrase)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text)
                    .padding(20)
            }
            Button("关闭") { inspectedNoom = nil }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.top)
        }
        .padding(40)
        .presentationDetents([.medium])
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomForestView dex grid + detail sheet + NoomForestViewModel"
```

---

## Task 12: NoomChallengeSession container view (5 questions + result screen)

**Files:**
- Create: `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeSessionView.swift`

- [ ] **Step 1: Create container**

Create `NumberOrchard/NumberOrchard/Features/NoomForest/NoomChallengeSessionView.swift`:

```swift
import SwiftUI
import SwiftData

struct NoomChallengeSessionView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: NoomChallengeViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isSessionComplete {
                    resultView(viewModel: viewModel)
                } else if let challenge = viewModel.currentChallenge {
                    challengeView(challenge: challenge, viewModel: viewModel)
                } else {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            let profile = profiles.first ?? createDefaultProfile()
            viewModel = NoomChallengeViewModel(profile: profile, modelContext: modelContext)
        }
    }

    private func challengeView(challenge: NoomChallengeType, viewModel: NoomChallengeViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(viewModel.questionsCompleted + 1)/\(viewModel.totalQuestions) 题")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("暂停") { onFinish() }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            NoomChallengeView(challenge: challenge) { unlocked in
                viewModel.handleCompletion(unlockedNumbers: unlocked)
            }
            .id(viewModel.questionsCompleted)  // Force scene rebuild on each new question
        }
    }

    private func resultView(viewModel: NoomChallengeViewModel) -> some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 24) {
                Text("🎉 太棒了！")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                Text("完成 5 道题")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.7))

                if !viewModel.newlyUnlockedNooms.isEmpty {
                    Text("解锁新伙伴")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CartoonColor.berry)
                    HStack(spacing: 16) {
                        ForEach(viewModel.newlyUnlockedNooms.prefix(5)) { noom in
                            VStack(spacing: 4) {
                                Image(uiImage: NoomRenderer.image(for: noom, expression: .happy, size: CGSize(width: 90, height: 90)))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                Text(noom.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(CartoonColor.text)
                            }
                        }
                    }
                }

                Text("⭐ +\(viewModel.starsEarned)   🌱 +\(viewModel.seedsEarned)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.gold)

                CartoonButton(tint: CartoonColor.leaf, action: onFinish) {
                    Text("🌳 回到森林")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 240, height: 70)
                }
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

- [ ] **Step 2: Build**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: NoomChallengeSessionView — 5-question flow + result screen"
```

---

# Phase 6: Integration

## Task 13: Add 5th button to HomeView + NoomForestEntry

**Files:**
- Modify: `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`

- [ ] **Step 1: Add a 5th feature button**

In `NumberOrchard/NumberOrchard/Features/Home/HomeView.swift`, find the `HomeView` struct's parameter list:

```swift
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void
    let onOpenMap: () -> Void
    let onOpenCollection: () -> Void
    let onOpenDecorate: () -> Void
    let onOpenBattle: () -> Void
```

Add immediately after `onOpenBattle`:

```swift
    let onOpenNoomForest: () -> Void
```

Then in the body, find the `HStack` with the 4 feature buttons (the one ending with `onOpenBattle()`). Replace its spacing and add a 5th button:

```swift
                HStack(spacing: 24) {
                    CartoonFeatureButton(emoji: "🗺️", label: "探险", tint: CartoonColor.gold, bobDelay: 0.0) {
                        onOpenMap()
                    }
                    CartoonFeatureButton(emoji: "🎨", label: "装饰", tint: CartoonColor.coral, bobDelay: 0.15) {
                        onOpenDecorate()
                    }
                    CartoonFeatureButton(emoji: "🍎", label: "图鉴", tint: CartoonColor.leaf, bobDelay: 0.30) {
                        onOpenCollection()
                    }
                    CartoonFeatureButton(emoji: "🐾", label: "小精灵", tint: CartoonColor.sky, bobDelay: 0.45) {
                        onOpenNoomForest()
                    }
                    CartoonFeatureButton(emoji: "👨‍👦", label: "对战", tint: CartoonColor.berry, bobDelay: 0.60) {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
```

(If the existing button block uses different spacing, keep its structure but insert the 🐾 button between "图鉴" and "对战".)

- [ ] **Step 2: Build (will fail at AppCoordinator call site — fixed in Task 14)**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -10
```

Expected: BUILD FAILED with missing argument `onOpenNoomForest:` at AppCoordinator

- [ ] **Step 3: Do not commit yet — proceed to Task 14**

---

## Task 14: AppCoordinator routing for NoomForest + ChallengeSession

**Files:**
- Modify: `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`

- [ ] **Step 1: Add new screens to enum**

In `NumberOrchard/NumberOrchard/App/AppCoordinator.swift`, find:

```swift
enum AppScreen: Equatable {
    case home
    case adventure(station: Station?)
    case parentCenter
    case map
    case collection
    case decorate
    case battle
}
```

Replace with:

```swift
enum AppScreen: Equatable {
    case home
    case adventure(station: Station?)
    case parentCenter
    case map
    case collection
    case decorate
    case battle
    case noomForest
    case noomChallenge
}
```

- [ ] **Step 2: Update HomeView call site**

Find the `case .home:` block in `AppCoordinator.body`:

```swift
                case .home:
                    HomeView(
                        onStartAdventure: { startAdventure(station: nil) },
                        onOpenParentCenter: { currentScreen = .parentCenter },
                        onOpenMap: { currentScreen = .map },
                        onOpenCollection: { currentScreen = .collection },
                        onOpenDecorate: { currentScreen = .decorate },
                        onOpenBattle: { currentScreen = .battle }
                    )
```

Replace with:

```swift
                case .home:
                    HomeView(
                        onStartAdventure: { startAdventure(station: nil) },
                        onOpenParentCenter: { currentScreen = .parentCenter },
                        onOpenMap: { currentScreen = .map },
                        onOpenCollection: { currentScreen = .collection },
                        onOpenDecorate: { currentScreen = .decorate },
                        onOpenBattle: { currentScreen = .battle },
                        onOpenNoomForest: { currentScreen = .noomForest }
                    )
```

- [ ] **Step 3: Add new case branches**

In the same `switch currentScreen` block, find `case .battle:`:

```swift
                case .battle:
                    BattleView(onFinish: { currentScreen = .home })
```

Add immediately after:

```swift
                case .noomForest:
                    NoomForestView(
                        onDismiss: { currentScreen = .home },
                        onStartChallenge: { currentScreen = .noomChallenge }
                    )
                case .noomChallenge:
                    NoomChallengeSessionView(onFinish: { currentScreen = .noomForest })
```

- [ ] **Step 4: Build to verify all integration works**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodegen generate
xcodebuild build -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit (Task 13 + 14 together)**

```bash
cd /Users/samxiao/code/app
git add -A
git commit -m "feat: integrate NoomForest into HomeView (5th button) and AppCoordinator routes"
```

---

## Task 15: Final test run + verification

**Files:** (verification only)

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/samxiao/code/app/NumberOrchard
xcodebuild test -scheme NumberOrchard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Test run with|\*\* TEST|error:" | tail -5
```

Expected: 70+ tests passed (existing 57 + 5 NoomCatalog + 4 NoomMerge + 6 NoomSplit + 6 NoomQuestionGen + 2 CollectedNoom = 80)

- [ ] **Step 2: If any failure, fix inline and commit `fix: ...` then re-run**

- [ ] **Step 3: Final commit (only if any fixes were needed)**

```bash
cd /Users/samxiao/code/app
git add -A
git diff --cached --quiet || git commit -m "fix: resolve final test/build issues for Noom Forest"
```

---

## Summary

| Phase | Tasks | Tests added |
|-------|-------|-------------|
| 1. Data foundation | 1-2 | NoomCatalog (5) |
| 2. Pure logic | 3-5 | Merge (4), Split (6), Generator (6) |
| 2 (cont.) | 6 | CollectedNoom (2) |
| 3. Visual | 7 | — |
| 4. SpriteKit | 8 | — |
| 5. SwiftUI | 9-12 | — |
| 6. Integration | 13-15 | — |

**Total: 15 tasks**, 23 new tests, ~7 hour estimated implementation.
