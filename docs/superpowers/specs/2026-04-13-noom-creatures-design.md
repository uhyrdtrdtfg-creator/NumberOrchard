# Noom 数字小精灵 设计文档

> **版本:** v1.0
> **日期:** 2026-04-13
> **状态:** Approved for implementation
> **基于:** MVP + Extended Features 已实现的基础
> **灵感:** DragonBox Numbers (Norway), Singapore Math 分解组合教学法

---

## 1. 目标

实现「数字果园」的第 5 种核心玩法 **🐾 小精灵森林**，用可爱的表情生物（Nooms）承载数字概念，让 5-6 岁儿童通过**拖拽合体 + 向下撕开**两种直觉操作理解加法与分解。

独立区域，不混入现有探险模式。完成后主屏从 4 个入口变 5 个。

---

## 2. 核心设计决策

| 问题 | 决策 | 理由 |
|------|------|------|
| 交互模式 | **双向混合（拆 + 合）** | 加减法直观训练，最接近 DragonBox 原版 |
| 视觉形象 | **表情生物**（程序生成毛球 + 斑点 + 眼睛嘴巴） | 情感连接强，与现有水果主题区分，工作量可控 |
| 关卡组织 | **独立专属区域** | 教学深度大，不稀释探险体验 |
| 进度结构 | **精灵收集图鉴（10 个）** | 集卡乐趣，5-6 岁最喜欢，目标明确 |

---

## 3. 整体架构

### 3.1 导航变化

主屏从 4 入口扩展到 5 入口：

```
HomeView (现有)
├── 🗺️ 探险
├── 🎨 装饰
├── 🍎 图鉴
├── 👨‍👦 对战
└── 🐾 小精灵森林  ← 新
         │
         ▼
   NoomForestView (新)
   ├── 顶部：10 格 Noom 图鉴（已收集/未收集）
   ├── 中部：森林场景（收集的 Noom 在此嬉戏）
   └── 底部：「开始挑战」按钮
         │
         ▼
   NoomChallengeView (新)
   ├── 5 道题一轮
   ├── 每道题二选一：拆分 / 合成
   └── 完成后显示结算 + 解锁状态
```

### 3.2 数据流

```
孩子打开小精灵森林
  → @Query CollectedNoom 列表
  → NoomForestView 展示图鉴 + 森林
  → 点击「开始挑战」
  → NoomChallengeViewModel 生成 5 道题（优先未解锁 Noom）
  → 每道题创建新的 NoomChallengeScene
  → 完成一题 → 若对应 Noom 未解锁 → 插入 CollectedNoom + stars/seeds
  → 5 题完成 → 结算屏 → 返回森林
  → 10 个全解锁 → 额外奖励传说水果 + "图鉴完成"徽章
```

### 3.3 新增文件

```
NumberOrchard/NumberOrchard/
├── Core/
│   ├── Models/
│   │   ├── Noom.swift                    (struct + NoomCatalog)
│   │   └── CollectedNoom.swift           (@Model)
│   └── AdaptiveEngine/
│       └── NoomQuestionGenerator.swift
├── Core/NoomLogic/ (NEW)
│   ├── NoomMergeLogic.swift
│   └── NoomSplitLogic.swift
└── Features/NoomForest/ (NEW)
    ├── NoomForestView.swift
    ├── NoomForestViewModel.swift
    ├── NoomChallengeView.swift           (SwiftUI wrapper)
    ├── NoomChallengeScene.swift          (SpriteKit)
    └── NoomChallengeViewModel.swift

Tests/
├── NumberOrchardTests/Core/Models/
│   └── NoomCatalogTests.swift
├── NumberOrchardTests/Core/NoomLogic/
│   ├── NoomMergeLogicTests.swift
│   └── NoomSplitLogicTests.swift
├── NumberOrchardTests/Core/AdaptiveEngine/
│   └── NoomQuestionGeneratorTests.swift
└── NumberOrchardTests/Features/NoomForest/
    └── CollectedNoomTests.swift

Modified:
├── Core/Models/ChildProfile.swift        (+ collectedNooms 关系)
├── App/NumberOrchardApp.swift            (+ Schema 注册)
├── Features/Home/HomeView.swift          (+ 第 5 个按钮)
└── App/AppCoordinator.swift              (+ noomForest 路由)
```

---

## 4. Noom 角色设计

### 4.1 10 个 Noom 定义

| N | 名字 | 主色 | 口头禅（首次解锁） |
|---|------|------|-----------------|
| 1 | 小一 | 粉红 #FF9AA2 | "我是一个，就一个哦！" |
| 2 | 贝贝 | 薄荷 #A8E6CF | "两个好朋友一起！" |
| 3 | 朵朵 | 浅黄 #FFD86F | "三三得九耶？哈哈！" |
| 4 | 汪汪 | 天蓝 #A3D8FF | "四个角的房子！" |
| 5 | 妮妮 | 橙 #FFB088 | "五个手指数一数！" |
| 6 | 六六 | 薰衣草 #C9B1FF | "六六大顺～" |
| 7 | 奇奇 | 柠檬绿 #D4F38C | "七彩的我最闪亮！" |
| 8 | 胖胖 | 珊瑚 #FFA8A8 | "圆圆滚滚的八！" |
| 9 | 九妹 | 天青 #8EDCE6 | "快要到十啦！" |
| 10 | 十全 | 金色 #FFD700 | "我是大王十全！" |

### 4.2 视觉构造（程序生成）

每个 Noom 是一张 `UIImage`，用 `UIBezierPath` 在 Core Graphics 中绘制：

```
圆身（bodyColor）:
  - 身体半径 = 30 + N * 4 (数字越大越胖)
  - 墨边 3pt, 硬阴影 6pt offset
  - 顶部高光椭圆（白色 0.3 opacity）

斑点:
  - N 个白色小圆点，在身上随机但固定分布
  - 每个斑点直径 6-8pt
  - 让孩子数得清

表情（3 种）:
  - default: 两只黑眼睛 + 小嘴
  - happy: 眯眼 + 大嘴笑（合体成功/解锁时）
  - surprised: 大眼睛 + O 型嘴（被拆分时）

小腿 (装饰):
  - 底部两个小半圆（同 bodyColor darker 0.2）
```

绘制工具：`CartoonSpriteKit.swift` 已有的 `renderCartoon*` helper 系列。

### 4.3 数据模型

```swift
struct Noom: Identifiable, Sendable, Hashable {
    let number: Int
    let name: String
    let bodyColor: UIColor
    let catchphrase: String
    var id: Int { number }
}

enum NoomCatalog {
    static let all: [Noom] = [/* 10 个 */]
    static func noom(for n: Int) -> Noom?
}

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

`ChildProfile` 新增：

```swift
@Relationship(deleteRule: .cascade)
var collectedNooms: [CollectedNoom] = []
```

`NumberOrchardApp.swift` Schema 注册新增 `CollectedNoom.self`。

---

## 5. 出题逻辑

### 5.1 题型

```swift
enum NoomChallengeType: Sendable, Equatable {
    case merge(a: Int, b: Int)    // 合成：给 a 和 b，要求拖在一起
    case split(total: Int)         // 拆分：给 total，要求向下撕开
}
```

### 5.2 出题器

`NoomQuestionGenerator` 生成 5 道题，规则：

| 题序 | 题型 | 难度 |
|------|------|------|
| 1 | merge | 5 以内 (a, b ∈ [1, 4], a+b ≤ 5) |
| 2 | merge | 5 以内 |
| 3 | split | total ∈ [3, 5] |
| 4 | merge | 10 以内 |
| 5 | merge | 10 以内 |

**优先未解锁 Noom：** 生成 merge 题时，如果 `a+b` 的 Noom 尚未解锁，权重 x3。split 题同理。

**核心方法：**
```swift
struct NoomQuestionGenerator: Sendable {
    func generateSession(alreadyUnlocked: Set<Int>) -> [NoomChallengeType]
}
```

### 5.3 纯逻辑（可单测）

```swift
struct NoomMergeLogic: Sendable {
    /// 合成两个 Noom 得到结果。a+b > 10 返回 nil。
    func merge(a: Int, b: Int) -> Int? {
        guard a >= 1, b >= 1, a + b <= 10 else { return nil }
        return a + b
    }
}

struct NoomSplitLogic: Sendable {
    /// 拖拽距离 → 拆分比例。
    /// dragDistance 范围 0-90pt，映射到 total-1 个拆分结果。
    func splitFor(total: Int, dragDistance: CGFloat) -> (Int, Int)? {
        guard (2...10).contains(total) else { return nil }
        let segments = total - 1
        let segmentSize = 90.0 / CGFloat(segments)
        let idx = min(segments, max(1, Int(dragDistance / segmentSize) + 1))
        return (idx, total - idx)
    }

    /// 所有合法拆法。
    func allSplits(of n: Int) -> [(Int, Int)] {
        guard n >= 2 else { return [] }
        return (1..<n).map { ($0, n - $0) }
    }
}
```

---

## 6. SpriteKit 交互详细设计

### 6.1 场景布局

```
┌──────────────────────────────────────────────────────┐
│ ⬅️ 返回     第 N/5 题                  ⏸️ 暂停         │
├──────────────────────────────────────────────────────┤
│                                                      │
│  📢 "把妮妮分成两个小伙伴～"  (卡通胶囊)              │
│                                                      │
│                                                      │
│      (合成模式)             (拆分模式)                │
│       🟢  🟡               🟠                        │
│    贝贝(2) 朵朵(3)         妮妮(5)                   │
│                           ✂️ 虚线 ~ ~                 │
│                                                      │
│                                                      │
│                                                      │
│    💡 "把两个拖到一起！" 或 "向下拖拽撕开！"          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 6.2 合成交互时间线

```
T+0.0s  用户按住 Noom A → A 眨眼 + 轻微放大到 1.15
T+n.n   用户拖拽 → A 跟手指；B 朝 A 方向转头（tease）
T+x.x   两个 frame 相交（含 50pt hit padding）→ 触发合体
合体动画：
  T+0.0s  A 和 B 磁吸靠拢（0.2s）
  T+0.2s  接触瞬间闪光（8 个 ★ 粒子向四周喷射）
  T+0.3s  A B 缩小消失
  T+0.5s  新 Noom 从接触点诞生（scale 0.1→1.2→1.0 弹性）
  T+0.8s  新 Noom 变 happy 表情，弹跳 1 次
  T+1.0s  播放 correct.wav + 语音 "2 + 3 = 5！"
  T+1.5s  图鉴顶部对应格子点亮（金色脉冲）
  T+2.2s  进入下一题
```

### 6.3 拆分交互时间线

```
T+0.0s  用户按住 Noom 中间 → Noom surprised 表情
T+n.n   用户向下拖拽 → 实时显示"将要拆成 X 和 Y"
         - 拖拽距离 0~30pt: "1 和 N-1"
         - 距离 30~60pt: "2 和 N-2"
         - 依此类推
T+x.x   松手 → 执行拆分
拆分动画：
  T+0.0s  原 Noom 身体从中间拉长
  T+0.2s  "啪" 一声分成两只（弹开到左右）
  T+0.5s  两只新 Noom 各自落地 (happy 表情)
  T+0.8s  显示算式 "5 = 3 + 2"
  T+1.2s  语音 "五等于三加二！"
  T+1.8s  两只对应的格子点亮
  T+2.5s  进入下一题
```

### 6.4 触摸判定

复用现有 `CartoonSKTouch.largeHitPadding = 50pt`：

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let location = touches.first?.location(in: self) else { return }
    // 扩展命中区域 + 选最近的 Noom
    let padding = CartoonSKTouch.largeHitPadding
    var best: SKSpriteNode?
    var bestDist: CGFloat = .greatestFiniteMagnitude
    for noom in noomNodes where noom.parent != nil {
        let expanded = noom.frame.insetBy(dx: -padding, dy: -padding)
        guard expanded.contains(location) else { continue }
        let d = pow(noom.position.x - location.x, 2)
              + pow(noom.position.y - location.y, 2)
        if d < bestDist { bestDist = d; best = noom }
    }
    draggingNoom = best
}
```

### 6.5 错误处理

- **合成错误**（拖到非 Noom 区域）→ Noom 回弹原位，柔和"咕~"音效
- **拆分错误**（未向下拖动）→ Noom 摇头 + 闪光，语音提示"向下拖一下哦"
- **不存在"答错"概念** —— 合成自动正确（算式 a+b=c 必然），拆分任何比例都接受（多解）

---

## 7. SwiftUI 页面设计

### 7.1 NoomForestView

```
┌──────────────────────────────────────────────────────┐
│ ⬅️ 返回                              ⭐ 12  🌱 4     │
├──────────────────────────────────────────────────────┤
│                                                      │
│   🐾 小精灵森林                                       │
│                                                      │
│   图鉴: 4 / 10                                       │
│   ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐│
│   │ 🟢 │ 🟡 │ 🟠 │ ?  │ ?  │ ?  │ ?  │ ?  │ ?  │ ?  ││
│   │小一│贝贝│朵朵│ ?? │ ?? │ ?? │ ?? │ ?? │ ?? │ ?? ││
│   └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘│
│                                                      │
│   (森林场景：已解锁的 Noom 在此走来走去)              │
│                                                      │
│                                                      │
│         [  🎮 开始挑战  ]                             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

- 图鉴格子点击（已解锁）→ 展开 detail sheet 显示 Noom 名字 + 口头禅
- 图鉴格子点击（未解锁）→ 摇头提示「完成挑战解锁哦」
- "开始挑战" 按钮使用 CartoonButton

### 7.2 NoomChallengeView

SwiftUI 壳（`SpriteView` 包装）+ 顶部进度条 + 暂停按钮。与现有 `PickFruitView` 同结构。

### 7.3 结算页

```
┌──────────────────────────────────────────────────────┐
│              🎉 太棒了！                              │
│                                                      │
│           完成 5 道题                                 │
│                                                      │
│           解锁新伙伴：                                │
│             🟠 妮妮                                  │
│             🟢 小一                                  │
│                                                      │
│           获得 ⭐ +5  🌱 +1                          │
│                                                      │
│         [  🌳 回到森林  ]                            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 8. 奖励 & 解锁规则

| 触发 | 奖励 |
|------|------|
| 首次解锁任意 Noom | stars +1, seeds +0 |
| 完成 5 题挑战 | stars +5 base |
| 首次完成挑战（任何星级） | seeds +1 |
| 解锁全部 10 个 Noom | 额外传说水果 🐲 + "图鉴完成"通知 |
| 重复挑战已完成的图鉴 | 只 stars +5，不重复发其它奖励 |

---

## 9. 测试策略

| 测试文件 | 覆盖要点 |
|---------|---------|
| `NoomCatalogTests` | 10 个 Noom 都存在，id 唯一，颜色唯一，name 唯一 |
| `NoomMergeLogicTests` | 合法合成、a+b>10 拒绝、a<1 或 b<1 拒绝 |
| `NoomSplitLogicTests` | 拖拽距离映射正确、边界值 (0, 90pt)、allSplits 枚举完整 |
| `NoomQuestionGeneratorTests` | 5 题序列（2 merge 5以内, 1 split, 2 merge 10以内）、未解锁 Noom 权重加倍 |
| `CollectedNoomTests` | 解锁不重复、encounterCount 递增、inverse 关系 |

SpriteKit 场景交互层、SwiftUI 视图不做单测（人工验证 + 现有模式）。

---

## 10. 实现优先级（Phase）

### Phase 1: 数据基础 (~30min)

1. Noom.swift + NoomCatalog (10 个)
2. CollectedNoom.swift (@Model)
3. ChildProfile.swift 加 collectedNooms 关系
4. NumberOrchardApp.swift Schema 注册
5. NoomCatalogTests

### Phase 2: 核心逻辑 (~1h15min)

6. NoomMergeLogic + tests
7. NoomSplitLogic + tests
8. NoomQuestionGenerator + tests

### Phase 3: 视觉 (~1h)

9. Noom 精灵图渲染（`renderNoom(noom: Noom, expression: .default/.happy/.surprised)`）
10. 森林背景（复用 CartoonGround）

### Phase 4: SpriteKit 挑战 (~1h30min)

11. NoomChallengeScene - 合成模式交互
12. NoomChallengeScene - 拆分模式交互
13. 完成动画 + 算式展示

### Phase 5: SwiftUI 森林 (~1h)

14. NoomForestView + 图鉴格子
15. Detail sheet（已解锁 Noom 信息）
16. 结算页（新解锁列表 + 奖励）

### Phase 6: Session 控制 (~45min)

17. NoomChallengeViewModel（5 题流程、奖励分发、更新 CollectedNoom）
18. NoomForestViewModel（计算已解锁 / 进度）

### Phase 7: 导航集成 (~30min)

19. HomeView 加第 5 按钮 🐾
20. AppCoordinator 加 `.noomForest` 路由
21. Parental Gate 不需要（纯儿童玩法）

### Phase 8: 联调 & 修复 (~1h)

22. 端到端走一遍
23. 触摸精度调试
24. bug 修复

**总计约 7 小时**，拆 ~22-25 个 task。

---

## 11. 不在本次范围

- 精灵成长/进化动画（留给后续「#2 宠物养成」）
- 沙盒自由玩耍（只做任务驱动）
- 自定义 Noom 配音（用 AudioManager 现有 TTS）
- 跨轮次的 Noom 好感度
- 亲子对战中的 Noom

---

## 12. 成功标准

1. 5-6 岁儿童能在无辅导下完成首次挑战
2. 合成操作（拖拽两只 Noom）的命中率 > 90%（不会"戳不到"）
3. 拆分操作（向下拖）直观易懂
4. 10 个 Noom 解锁驱动孩子重玩至少 3 轮
5. 一轮挑战（5 题）在 2-3 分钟内完成
6. 美术风格与现有卡通系统一致（ink outline, hard shadow）

---

## 13. 技术风险

| 风险 | 缓解 |
|------|------|
| 程序生成的 Noom 不够可爱 | 用暖色调 + 大眼睛 emoji 拼接，必要时可换成 SF Symbols |
| 拆分交互复杂，孩子不懂 | 首次进入显示教学动画示范 |
| 10 只 Noom 同时在森林场景可能卡顿 | 限制同屏最多 6 只，超出轮换 |
| SwiftData 多 Relationship 性能 | 现有 MVP 已有 3 个 relationship，再加 1 个没问题 |
