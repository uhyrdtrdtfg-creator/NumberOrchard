# 数学宠物养成 设计文档

> **版本:** v1.0
> **日期:** 2026-04-13
> **状态:** Approved for implementation
> **基于:** MVP + Extended Features + Noom 小精灵 已实现的基础
> **灵感:** Todo Math 怪兽养成, たまごっち, DragonBox Numbers

---

## 1. 目标

把孩子已收集的 Noom 小精灵（1-10）和即将引入的大精灵（11-20）变成**可以喂养成长的宠物**。用从关卡奖励来的水果作为食物，每一道答对的题都能持续作用到宠物成长，让孩子有**长期目标感**——养出独一无二的"我的大妮妮"。

与之前独立玩法不同，这不是一种新玩法，而是**现有系统的养成层**：现有的闯关、Noom 挑战仍然是"主食"，宠物花园是"消费果实+见证成长"的地方。

---

## 2. 核心设计决策汇总

| # | 问题 | 决策 |
|---|------|------|
| 1 | 宠物身份 | **C 混合**（Noom 进化 + 独立 11-20 精灵） |
| 2 | 成长机制 | **E 混合**（XP 进度条 + 偏好题型 2× 奖励） |
| 3 | 喂食方式 | **D 果实消费**（图鉴里的水果作为食物） |
| 4 | 独立宠物 | **C 数字延伸 11-20 大精灵** |
| 5 | 孵化条件 | **B 合成解锁**（两只成年小 Noom 加起来为 11-20） |
| 6 | 进化阶段 | **B 3 阶段**（幼→少→成） |
| 7 | UI 入口 | **B 并入小精灵森林 Tab 切换** |

---

## 3. 整体架构

### 3.1 导航变化

主屏按钮 **不变**（5 个）。小精灵森林内部新增 2 级 Tab：

```
🐾 小精灵森林 (NoomForestView — 修改)
├── [📖 图鉴]  [🌻 宠物花园]  ← Tab 切换
│
├── 图鉴 tab (现有 + 扩展):
│   ├── 10 格 Noom 1-10 (已实现)
│   └── 10 格 大精灵 11-20 (新增)
│
└── 宠物花园 tab (全新):
    ├── 顶部: 活跃宠物 + XP 条
    ├── 中部: 水果库存横滑栏 + 拖拽喂食
    └── 底部: 孵蛋区 (两槽合成大精灵)
```

### 3.2 数据流

```
孩子完成关卡 → stars/seeds/水果 入图鉴 (现有)
         ↓
进宠物花园 Tab → 选活跃宠物 → 拖水果到宠物身上
         ↓
PetXPCalculator 计算 XP:
  - 普通水果: +10 XP
  - 偏好水果 (PetPreferenceMap): +20 XP
         ↓
更新 PetProgress(xp += N)
         ↓
PetEvolutionLogic.stage(for: xp) → 可能升级
         ↓
升级动画 + NoomRenderer 重绘（加装饰）

孵蛋:
拖 2 只已成年 Noom 到蛋槽 → canHatch(a+b ∈ 11-20) → 显示结果
  → 点击「孵化」按钮 → 孵蛋动画 → 新大 Noom 加入图鉴 + PetProgress
```

### 3.3 新增/修改文件

```
NumberOrchard/NumberOrchard/
├── Core/
│   ├── Models/
│   │   ├── Noom.swift                          (modify: NoomCatalog 加 11-20)
│   │   ├── PetProgress.swift                   (NEW @Model)
│   │   └── PetPreferenceMap.swift              (NEW 静态偏好表)
│   └── PetLogic/ (NEW dir)
│       ├── PetXPCalculator.swift
│       └── PetEvolutionLogic.swift
├── App/
│   └── NumberOrchardApp.swift                  (modify: Schema + PetProgress.self)
├── Features/NoomForest/
│   ├── NoomForestView.swift                    (modify: 加 Tab)
│   ├── NoomForestViewModel.swift               (modify: 加 selectedTab)
│   ├── NoomRenderer.swift                      (modify: 加 stage 参数支持装饰)
│   ├── PetGardenView.swift                     (NEW)
│   ├── PetGardenViewModel.swift                (NEW)
│   ├── PetFeedingArea.swift                    (NEW: 活跃宠物 + 水果栏)
│   └── EggHatchingArea.swift                   (NEW: 合成蛋孵化)
└── Core/Models/ChildProfile.swift              (modify: + petProgress)

Tests:
NumberOrchardTests/
├── Core/Models/
│   ├── NoomCatalogTests.swift                  (modify: 加 11-20 验证)
│   └── PetPreferenceMapTests.swift             (NEW)
├── Core/PetLogic/ (NEW)
│   ├── PetXPCalculatorTests.swift
│   └── PetEvolutionLogicTests.swift
└── Features/NoomForest/
    └── PetProgressTests.swift                  (NEW)
```

---

## 4. 数据模型

### 4.1 PetProgress @Model

```swift
@Model
final class PetProgress {
    var noomNumber: Int         // 1-20
    var xp: Int
    var stage: Int              // 0 幼, 1 少, 2 成
    var matureAt: Date?         // 成年时间，参与孵化判定
    var isActive: Bool          // 最多 1 只 active

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

### 4.2 ChildProfile 扩展

```swift
@Relationship(deleteRule: .cascade)
var petProgress: [PetProgress] = []
```

### 4.3 NumberOrchardApp Schema 注册

新增 `PetProgress.self` 到 Schema。

### 4.4 NoomCatalog 扩展到 20

```swift
enum NoomCatalog {
    static let all: [Noom] = [
        // 1-10 现有，保持不变
        .init(number: 1, name: "小一", ...),
        // ...
        .init(number: 10, name: "十全", ...),

        // 11-20 新增
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
    ]
    
    static var smallNooms: [Noom] { all.filter { $0.number <= 10 } }
    static var bigNooms: [Noom] { all.filter { $0.number >= 11 } }
}
```

### 4.5 PetPreferenceMap（偏好映射）

```swift
enum PetPreferenceMap {
    static let preferences: [Int: [String]] = [
        1: ["apple", "strawberry"],
        2: ["banana", "lemon"],
        3: ["cherry", "red_grape"],
        4: ["orange", "tangerine"],
        5: ["watermelon", "melon"],
        6: ["grape", "blueberry"],
        7: ["peach", "apricot"],
        8: ["mango", "pineapple"],
        9: ["kiwi", "tomato"],
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

### 4.6 水果库存策略

**无限供给模型**：孩子只要在 `CollectedFruit` 里拥有某水果（表示"解锁过"），就可以在宠物花园里**无限次**把它喂给宠物。这避免了「吃光就没得喂」的焦虑，同时激励孩子收集更多品种（而非屯积同一种）。

实现上，水果库存 UI 读取 `profile.collectedFruits` 显示；喂食不减少任何计数。

---

## 5. 纯逻辑模块

### 5.1 PetXPCalculator

```swift
struct PetXPCalculator: Sendable {
    static let baseXP = 10
    static let preferredMultiplier = 2

    /// 计算一次喂食得到多少 XP。
    func xpFor(fruitId: String, noomNumber: Int) -> Int {
        if PetPreferenceMap.isPreferred(fruitId: fruitId, for: noomNumber) {
            return Self.baseXP * Self.preferredMultiplier  // 20
        }
        return Self.baseXP  // 10
    }
}
```

### 5.2 PetEvolutionLogic

```swift
struct PetEvolutionLogic: Sendable {
    /// 每阶段的 XP 门槛 (cumulative)
    /// stage 0 = 幼 (0-99 XP)
    /// stage 1 = 少 (100-299 XP)
    /// stage 2 = 成 (300+ XP)
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

    /// 返回孵化结果 Noom 编号（11-20）或 nil。
    /// 需要两只数字相加等于 11-20。
    func canHatch(matureNoomA: Int, matureNoomB: Int) -> Int? {
        let sum = matureNoomA + matureNoomB
        guard (11...20).contains(sum) else { return nil }
        return sum
    }
}
```

---

## 6. UI 交互详细设计

### 6.1 宠物花园视图布局

```
┌─────────────────────────────────────────────────────────┐
│  ⬅️  小精灵森林      ⭐ 48  🌱 5                          │
│      [ 📖 图鉴 ] [ 🌻 宠物花园 ]                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌── 活跃宠物 ──────────────────────────────┐            │
│  │        🟠 妮妮 (少年)                       │            │
│  │       ■■■■■■□□□□ 130/300 XP              │            │
│  │       [ 切换宠物 ]                          │            │
│  └────────────────────────────────────────────┘            │
│                                                         │
│  ┌── 水果库存 ────────────────────────────────┐            │
│  │  🍎 🍓 🍊 🍇 🥝 🍑 🍍 ...  ←→             │            │
│  │  拖到宠物身上 → 喂食                        │            │
│  └────────────────────────────────────────────┘            │
│                                                         │
│  ┌── 孵蛋大本营 ──────────────────────────────┐            │
│  │  [ 🥚 槽1 ] + [ 🥚 槽2 ] = ?                │            │
│  │  拖入成年 Noom                              │            │
│  │  [ 🐣 孵化！ ] (匹配 11-20 时亮起)            │            │
│  └────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

### 6.2 喂食交互时间线

```
T+0.0s  孩子长按水果 emoji → 水果 scale 到 1.15 + 金色光晕
T+n.n   孩子拖拽，水果跟手指；宠物方向"翻眼"看来的水果
T+x.x   松手于宠物:
  偏好水果 (2× XP, 20 点):
    T+0.0s  宠物张大嘴 + "啊呜" 吞咽动画
    T+0.3s  金色 ★ 粒子 (8 个) 从宠物身上爆射
    T+0.5s  XP 条从当前涨 20，"+20!" 金字上浮
    T+0.8s  宠物扭身 / happy 表情 0.5s
  普通水果 (10 点):
    T+0.0s  宠物吃下，身体轻微弹跳 +10%
    T+0.3s  XP 条涨 10，"+10" 白字上浮
  松手于非宠物:
    水果弹回原位（和现有 PickFruit 一致）
```

### 6.3 进化动画

XP 首次跨越 100 或 300 门槛时自动触发:

```
T+0.0s  当前宠物停止动作，全屏暗化 + 发光圈从宠物辐射
T+0.5s  宠物开始发光旋转（用 SKAction.rotate + scale）
T+2.5s  光环爆散 → 宠物重绘为新阶段（body +15%，加装饰）
T+3.0s  "妮妮长大啦！" 语音 + 花瓣粒子
T+4.0s  返回花园正常视图
```

### 6.4 NoomRenderer 阶段装饰

NoomRenderer 新增 `stage: Int` 参数。装饰以额外层渲染：

| stage | body scale | 装饰 |
|-------|------------|------|
| 0 幼 | 1.00 | 无 |
| 1 少 | 1.15 | 顶部加蝴蝶结或小帽子（用 emoji 作为 text layer: 🎀 或 🧢）|
| 2 成 | 1.30 | 顶部皇冠 + 披风装饰（emoji 👑 + 🎽 贴在身上）|

（Emoji 装饰通过 `NSString.draw(in:)` 贴到绘制图像上，不新增资源。）

### 6.5 孵蛋交互

```
空状态:
  [ 🥚 槽1 ]  +  [ 🥚 槽2 ]  =  ?

孩子长按成年 Noom (在「活跃宠物」或「切换宠物」视图里) 拖到槽1:
  [ 🟠 妮妮 ]  +  [ 🥚 槽2 ]  =  ?
  "再拖一只成年 Noom 进来！"

两槽都填:
  [ 🟠 妮妮 ]  +  [ 🟣 六六 ]  = 11 号 大十一
  [ 🐣 孵化！] (金色发光按钮，可点击)

点击孵化:
  T+0.0s  两只 Noom 跳到中心碰撞
  T+0.5s  闪光 → 合并成大蛋
  T+1.0s  蛋晃动 3 次
  T+2.0s  蛋裂开 → 大 Noom 诞生 (scale 0.1 → 1.3 → 1.0 弹性)
  T+2.8s  名字显示 + 金色粒子
  T+3.5s  语音："大十一 诞生啦！"
  T+4.5s  关闭动画 → 图鉴 tab 对应格子点亮 → 返回花园
         新 Noom 自动加入 PetProgress，可选为活跃宠物
```

### 6.6 孵蛋规则

- 参与合成的两只成年 Noom **不消失**，仅本轮使用
- 同一只大 Noom 已孵化过 → 按钮变灰 + 文字「已收集」
- 合成结果不在 11-20（比如 1+2=3）→ 按钮保持灰色 + 提示「加起来需要在 11-20 之间」
- 如果某数字有多种合成法（如 11 = 5+6 或 10+1），任何合法组合都算

---

## 7. 测试策略

| 测试文件 | 覆盖点 |
|---------|--------|
| `NoomCatalogTests` (扩展) | 20 个 Noom 存在，name 唯一，number 1-20 |
| `PetXPCalculatorTests` | 基础 10 XP，偏好 20 XP，未知水果 fallback |
| `PetEvolutionLogicTests` | stage 映射（0/100/300），成年判定，孵化 sum 必须 11-20 |
| `PetPreferenceMapTests` | 1-20 都有偏好，偏好水果 id 存在于 FruitCatalog |
| `PetProgressTests` | init 默认 xp=0/stage=0，xp 更新不改 stage（由 logic 单独算）|

约 20 个新测试。

---

## 8. 实现优先级 (Phase)

### Phase 1: 数据扩展 (~40min)
1. NoomCatalog 扩展到 20
2. PetProgress @Model
3. PetPreferenceMap 静态
4. ChildProfile + petProgress
5. Schema 注册

### Phase 2: 纯逻辑 (~1h)
6. PetXPCalculator + tests
7. PetEvolutionLogic + tests
8. PetPreferenceMap tests
9. PetProgress tests
10. NoomCatalog 扩展 tests

### Phase 3: Renderer 扩展 (~45min)
11. NoomRenderer 加 stage 参数 + 蝴蝶结/王冠装饰

### Phase 4: PetGarden 框架 (~45min)
12. NoomForestView 加 Tab picker
13. PetGardenView 三区域骨架
14. PetGardenViewModel

### Phase 5: 喂食交互 (~1h 30min)
15. PetFeedingArea - 活跃宠物展示
16. 水果库存横滑栏
17. 拖拽喂食逻辑 + XP 动画

### Phase 6: 进化动画 (~30min)
18. 发光旋转 + 阶段切换转场

### Phase 7: 孵蛋区 (~1h 15min)
19. EggHatchingArea 两槽 + 验证逻辑
20. 孵蛋动画

### Phase 8: 联调 (~1h)
21. 导航 & Tab 切换测试
22. 端到端 bug 修复

**合计约 8 小时**，约 22-25 task。

---

## 9. 不在本次范围

- **饥饿 / 消耗机制**（选 A+C 而非 B 明确排除）
- **每日签到**（MVP 已有）
- **宠物对战**
- **自定义宠物名**
- **21+ 的数字精灵**
- **宠物专属 BGM**
- **宠物专属配音**（用 speakEquation + catchphrase 文本）

---

## 10. 成功标准

1. 孩子能把任意小 Noom（1-10）从幼年养成成年（累积 300 XP）
2. 两只成年小 Noom 合成孵化出对应的 11-20 大 Noom
3. 水果库存与 CollectedFruit 无缝联动
4. 偏好水果 2× XP 有明显视觉反馈
5. Tab 切换流畅，不影响图鉴的现有功能
6. 整体美术风格与现有卡通系统一致

---

## 11. 技术风险

| 风险 | 缓解 |
|------|------|
| PetProgress 可能有 20 条 + 查询频繁 | 20 条远小于 SwiftData 阈值 |
| NoomRenderer 加装饰导致现有图鉴格子变化 | stage 参数默认 0，现有调用无需改 |
| 水果库存无限 vs 现实感（不现实） | 显性设计选择：kid-friendly, no 饥饿焦虑 |
| 孵蛋拖拽成年 Noom 的 UI 发现性 | 提示文字明确「拖成年 Noom 到这里」+ 成年 Noom 视觉上更大更华丽易识别 |
