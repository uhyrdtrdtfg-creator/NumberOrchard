import Foundation

/// One storybook page. The illustration is either a Noom portrait
/// (rendered by NoomRenderer when `noomNumber` is set) or a fallback
/// emoji glyph for non-Noom characters (汪汪队 etc.).
///
/// Stories are deliberately tiny (3-4 lines) because this is early
/// reading for 3-6 yr olds. Each ends in a math question whose
/// answer the child taps from 3 choices.
struct StoryEntry: Sendable, Hashable, Identifiable {
    let id: String
    let book: StoryBook
    /// If set, the page renders the Noom portrait at this number.
    let noomNumber: Int?
    /// Otherwise (or alongside) the page shows this emoji as the hero.
    let illustration: String?
    /// 3-4 short lines of narrative, one per beat.
    let lines: [String]
    /// Prompt above the answer choices.
    let question: String
    /// Exactly one of `choices` equals `answer`.
    let choices: [Int]
    let answer: Int
}

/// The two collections shipped today. Adding a new book is a matter of
/// adding a case + an `entries(in:)` clause + the seed data.
enum StoryBook: String, Sendable, CaseIterable, Identifiable {
    case noom       = "🐾 小精灵"
    case pawPatrol  = "🚒 汪汪队"

    var id: String { rawValue }
}

enum StoryCatalog {
    /// All entries from every book, in book order.
    static let all: [StoryEntry] = noom() + pawPatrol()

    static func entries(in book: StoryBook) -> [StoryEntry] {
        all.filter { $0.book == book }
    }

    // Backwards compatibility for existing call sites.
    static var availableNumbers: [Int] {
        noom().compactMap { $0.noomNumber }
    }

    static func story(forNoom number: Int) -> StoryEntry? {
        noom().first { $0.noomNumber == number }
    }

    // MARK: - Noom stories (10 entries, Noom 1-10)

    private static func noom() -> [StoryEntry] {
        [
            .init(id: "noom-1", book: .noom, noomNumber: 1, illustration: nil,
                  lines: [
                    "小一一个人站在山坡上,",
                    "看着天上飞过一群小鸟。",
                    "它悄悄数着:一只、两只……",
                    "'要是有一个朋友就好了!'"
                  ],
                  question: "小一再来 1 个朋友,一共几个?",
                  choices: [2, 3, 1], answer: 2),
            .init(id: "noom-2", book: .noom, noomNumber: 2, illustration: nil,
                  lines: [
                    "贝贝和好朋友两个人手拉手,",
                    "他们看见草地上有 2 朵小花。",
                    "贝贝摘了 1 朵,",
                    "悄悄放在朋友头上。"
                  ],
                  question: "草地上还剩几朵花?",
                  choices: [1, 2, 3], answer: 1),
            .init(id: "noom-3", book: .noom, noomNumber: 3, illustration: nil,
                  lines: [
                    "朵朵有 3 朵粉色小花,",
                    "妈妈生日到了,",
                    "朵朵想送妈妈一朵,",
                    "再送爸爸一朵。"
                  ],
                  question: "朵朵自己还剩几朵?",
                  choices: [2, 1, 3], answer: 1),
            .init(id: "noom-4", book: .noom, noomNumber: 4, illustration: nil,
                  lines: [
                    "汪汪住在一座四角方方的小房子里,",
                    "一个角下种着苹果树,",
                    "另一个角下种着樱桃树。",
                    "还有 2 个角空着。"
                  ],
                  question: "汪汪还可以种几棵树?",
                  choices: [1, 2, 3], answer: 2),
            .init(id: "noom-5", book: .noom, noomNumber: 5, illustration: nil,
                  lines: [
                    "妮妮的五个手指头最爱比赛,",
                    "大拇指先跑,食指紧跟着。",
                    "现在有 2 个在跑,",
                    "还有几个在等?"
                  ],
                  question: "5 个手指,2 个在跑,剩几个?",
                  choices: [3, 2, 4], answer: 3),
            .init(id: "noom-6", book: .noom, noomNumber: 6, illustration: nil,
                  lines: [
                    "六六是个大顺儿!",
                    "它搬来 3 颗苹果,",
                    "又搬来 3 颗橘子,",
                    "要摆一个漂亮的果盘。"
                  ],
                  question: "果盘里一共几个水果?",
                  choices: [5, 6, 7], answer: 6),
            .init(id: "noom-7", book: .noom, noomNumber: 7, illustration: nil,
                  lines: [
                    "奇奇最爱彩虹,",
                    "彩虹有 7 种颜色。",
                    "今天它数到了 4 种,",
                    "就被云朵盖住了。"
                  ],
                  question: "还差几种颜色没数到?",
                  choices: [3, 2, 4], answer: 3),
            .init(id: "noom-8", book: .noom, noomNumber: 8, illustration: nil,
                  lines: [
                    "胖胖圆滚滚像个数字 8,",
                    "它今天吃了 5 个饺子,",
                    "妈妈说再吃 3 个就饱。",
                    "胖胖鼓起肚子吃完了。"
                  ],
                  question: "胖胖一共吃了几个饺子?",
                  choices: [7, 8, 9], answer: 8),
            .init(id: "noom-9", book: .noom, noomNumber: 9, illustration: nil,
                  lines: [
                    "九妹快要变大啦,",
                    "它现在有 9 颗星星徽章,",
                    "再得 1 颗就满 10 啦!",
                    "快给它加油。"
                  ],
                  question: "九妹现在有几颗星?",
                  choices: [9, 10, 8], answer: 9),
            .init(id: "noom-10", book: .noom, noomNumber: 10, illustration: nil,
                  lines: [
                    "十全大王要开派对,",
                    "它邀请了 10 个朋友。",
                    "分成两组做游戏:",
                    "一组 4 个,另一组..."
                  ],
                  question: "另一组有几个朋友?",
                  choices: [6, 5, 7], answer: 6),
        ]
    }

    // MARK: - 汪汪队 stories (20 entries)
    //
    // Lightweight rescue-team adventures themed around 汪汪队 / PAW
    // Patrol-style characters. Math is woven into the rescue beats so
    // the child does the count *as* the story resolves.

    private static func pawPatrol() -> [StoryEntry] {
        [
            .init(id: "pp-01", book: .pawPatrol, noomNumber: nil, illustration: "👦",
                  lines: [
                    "莱德召集汪汪队集合!",
                    "队里一共有 6 只小狗。",
                    "莱德派 2 只去港口巡逻,",
                    "其他都留在基地。"
                  ],
                  question: "基地还有几只小狗?",
                  choices: [3, 4, 5], answer: 4),
            .init(id: "pp-02", book: .pawPatrol, noomNumber: nil, illustration: "🚒",
                  lines: [
                    "毛毛是消防员小狗,",
                    "山路边有 7 棵小树着火。",
                    "它喷水救灭了 4 棵,",
                    "还在加油救剩下的!"
                  ],
                  question: "还有几棵在着火?",
                  choices: [2, 3, 4], answer: 3),
            .init(id: "pp-03", book: .pawPatrol, noomNumber: nil, illustration: "🚓",
                  lines: [
                    "阿奇追到 5 个偷果子的小坏蛋,",
                    "先抓住了 2 个,",
                    "又抓住 1 个,",
                    "其它的还在跑。"
                  ],
                  question: "还有几个跑了?",
                  choices: [2, 3, 1], answer: 2),
            .init(id: "pp-04", book: .pawPatrol, noomNumber: nil, illustration: "🚁",
                  lines: [
                    "天天驾着直升机起飞了,",
                    "飞过 3 座大山,",
                    "又飞过 4 座小山,",
                    "终于看到救援目标!"
                  ],
                  question: "天天一共飞过几座山?",
                  choices: [6, 7, 8], answer: 7),
            .init(id: "pp-05", book: .pawPatrol, noomNumber: nil, illustration: "🚜",
                  lines: [
                    "路马要搬 9 块砖盖小屋,",
                    "已经搬了 5 块。",
                    "队友帮它一起搬,",
                    "很快就盖好啦!"
                  ],
                  question: "路马还要搬几块砖?",
                  choices: [3, 4, 5], answer: 4),
            .init(id: "pp-06", book: .pawPatrol, noomNumber: nil, illustration: "♻️",
                  lines: [
                    "灰灰是回收专家,",
                    "今天捡了 4 个塑料瓶,",
                    "又捡了 3 个易拉罐。",
                    "全部送进回收车!"
                  ],
                  question: "一共回收几样东西?",
                  choices: [6, 7, 8], answer: 7),
            .init(id: "pp-07", book: .pawPatrol, noomNumber: nil, illustration: "🐢",
                  lines: [
                    "珠玛在沙滩看到 8 只小海龟,",
                    "它帮 3 只回到了大海,",
                    "其他的还在沙滩散步,",
                    "等着妈妈回来。"
                  ],
                  question: "沙滩上还有几只小海龟?",
                  choices: [4, 5, 6], answer: 5),
            .init(id: "pp-08", book: .pawPatrol, noomNumber: nil, illustration: "🏔️",
                  lines: [
                    "雪雪要爬上大雪山,",
                    "山顶有 10 级台阶。",
                    "它已经爬了 6 级,",
                    "马上就能救出迷路的旅行者!"
                  ],
                  question: "还有几级台阶到顶?",
                  choices: [3, 4, 5], answer: 4),
            .init(id: "pp-09", book: .pawPatrol, noomNumber: nil, illustration: "🌴",
                  lines: [
                    "雷克斯在丛林发现 5 只小猴子,",
                    "树后又跳出来 4 只。",
                    "猴子们围着它玩,",
                    "热闹极了!"
                  ],
                  question: "现在一共几只小猴子?",
                  choices: [8, 9, 10], answer: 9),
            .init(id: "pp-10", book: .pawPatrol, noomNumber: nil, illustration: "📦",
                  lines: [
                    "力豹是新来的快递狗,",
                    "上午送了 6 个包裹,",
                    "下午还要送 5 个。",
                    "今天工作很忙呀!"
                  ],
                  question: "力豹一天要送几个包裹?",
                  choices: [10, 11, 12], answer: 11),
            .init(id: "pp-11", book: .pawPatrol, noomNumber: nil, illustration: "🗼",
                  lines: [
                    "海湾镇灯塔有 12 扇窗户,",
                    "晚上点亮了 7 扇,",
                    "其余的还黑着,",
                    "毛毛快去帮忙点灯!"
                  ],
                  question: "还有几扇窗户黑着?",
                  choices: [4, 5, 6], answer: 5),
            .init(id: "pp-12", book: .pawPatrol, noomNumber: nil, illustration: "🐔",
                  lines: [
                    "市长古蒂养了 8 只小鸡,",
                    "早上有 3 只跑出鸡窝,",
                    "她请汪汪队帮忙找,",
                    "其它都乖乖留在家里。"
                  ],
                  question: "鸡窝里还剩几只小鸡?",
                  choices: [4, 5, 6], answer: 5),
            .init(id: "pp-13", book: .pawPatrol, noomNumber: nil, illustration: "🎣",
                  lines: [
                    "船长奇宝出海钓鱼,",
                    "今天钓到了 7 条鱼。",
                    "回到岸边卖了 4 条,",
                    "其余带回小屋做晚餐。"
                  ],
                  question: "船长带回家几条鱼?",
                  choices: [2, 3, 4], answer: 3),
            .init(id: "pp-14", book: .pawPatrol, noomNumber: nil, illustration: "🛹",
                  lines: [
                    "小艾本来有 2 块滑板,",
                    "生日妈妈又送了 1 块,",
                    "他高兴得跳起来,",
                    "约毛毛去公园玩。"
                  ],
                  question: "小艾现在一共几块滑板?",
                  choices: [2, 3, 4], answer: 3),
            .init(id: "pp-15", book: .pawPatrol, noomNumber: nil, illustration: "🏍️",
                  lines: [
                    "勇敢丹丹的特技摩托,",
                    "先跳过 3 个轮胎堆,",
                    "又跳过了 5 个,",
                    "全场观众鼓掌叫好!"
                  ],
                  question: "丹丹一共跳过几堆轮胎?",
                  choices: [7, 8, 9], answer: 8),
            .init(id: "pp-16", book: .pawPatrol, noomNumber: nil, illustration: "🏘️",
                  lines: [
                    "海湾镇本来有 6 家小店,",
                    "今年又开了 4 家新店,",
                    "镇民们好开心,",
                    "一起庆祝呢!"
                  ],
                  question: "海湾镇现在一共几家店?",
                  choices: [9, 10, 11], answer: 10),
            .init(id: "pp-17", book: .pawPatrol, noomNumber: nil, illustration: "💃",
                  lines: [
                    "汪汪队在玩跳舞游戏,",
                    "毛毛跳了 3 段舞,",
                    "天天又跳了 4 段,",
                    "全场的小狗都拍手!"
                  ],
                  question: "他们一共跳了几段舞?",
                  choices: [6, 7, 8], answer: 7),
            .init(id: "pp-18", book: .pawPatrol, noomNumber: nil, illustration: "🏰",
                  lines: [
                    "观察塔一共有 5 层,",
                    "毛毛从 1 楼上到了 4 楼,",
                    "马上就要到顶啦!",
                    "好风景在等着它。"
                  ],
                  question: "毛毛还要爬几层?",
                  choices: [1, 2, 3], answer: 1),
            .init(id: "pp-19", book: .pawPatrol, noomNumber: nil, illustration: "🚐",
                  lines: [
                    "车库里停着 6 辆巡逻车,",
                    "紧急任务出动了 4 辆,",
                    "剩下的还在车库,",
                    "等着下次出发!"
                  ],
                  question: "车库里还剩几辆车?",
                  choices: [1, 2, 3], answer: 2),
            .init(id: "pp-20", book: .pawPatrol, noomNumber: nil, illustration: "🎉",
                  lines: [
                    "海湾镇大庆典开始啦,",
                    "上午来了 8 个朋友,",
                    "下午又来了 7 个,",
                    "广场上热闹极了!"
                  ],
                  question: "庆典上一共来了几个朋友?",
                  choices: [14, 15, 16], answer: 15),
        ]
    }
}

// MARK: - Compatibility shim
//
// Older callers used `NoomStory` and `NoomStoryCatalog` — alias both so
// the StorybookView migration stays a small diff.

typealias NoomStory = StoryEntry
typealias NoomStoryCatalog = StoryCatalog
