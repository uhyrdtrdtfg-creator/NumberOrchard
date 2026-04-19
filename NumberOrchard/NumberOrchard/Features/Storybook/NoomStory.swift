import Foundation

/// One storybook page for a Noom — a short narrative (30 seconds of
/// reading) ending in an embedded math question whose answer the child
/// taps from 3 choices. Gives each Noom a reason-to-exist beyond its
/// body colour and XP bar.
///
/// Stories are deliberately tiny (3-4 lines) because this is early
/// reading for 3-6 yr olds. The `question` hooks into the Noom's
/// number so 小一 teaches +1, 十全 teaches composition of 10, etc.
struct NoomStory: Sendable, Hashable {
    let noomNumber: Int
    /// 3-4 short lines of narrative, one per beat.
    let lines: [String]
    /// Prompt shown above the answer choices, e.g. "朵朵送走 1 朵,还剩?"
    let question: String
    /// Exactly one of `choices` equals `answer`.
    let choices: [Int]
    let answer: Int
}

enum NoomStoryCatalog {
    static let all: [NoomStory] = [
        .init(noomNumber: 1,
              lines: [
                "小一一个人站在山坡上,",
                "看着天上飞过一群小鸟。",
                "它悄悄数着:一只、两只……",
                "'要是有一个朋友就好了!'"
              ],
              question: "小一再来 1 个朋友,一共几个?",
              choices: [2, 3, 1],
              answer: 2),
        .init(noomNumber: 2,
              lines: [
                "贝贝和好朋友两个人手拉手,",
                "他们看见草地上有 2 朵小花。",
                "贝贝摘了 1 朵,",
                "悄悄放在朋友头上。"
              ],
              question: "草地上还剩几朵花?",
              choices: [1, 2, 3],
              answer: 1),
        .init(noomNumber: 3,
              lines: [
                "朵朵有 3 朵粉色小花,",
                "妈妈生日到了,",
                "朵朵想送妈妈一朵,",
                "再送爸爸一朵。"
              ],
              question: "朵朵自己还剩几朵?",
              choices: [2, 1, 3],
              answer: 1),
        .init(noomNumber: 4,
              lines: [
                "汪汪住在一座四角方方的小房子里,",
                "一个角下种着苹果树,",
                "另一个角下种着樱桃树。",
                "还有 2 个角空着。"
              ],
              question: "汪汪还可以种几棵树?",
              choices: [1, 2, 3],
              answer: 2),
        .init(noomNumber: 5,
              lines: [
                "妮妮的五个手指头最爱比赛,",
                "大拇指先跑,食指紧跟着。",
                "现在有 2 个在跑,",
                "还有几个在等?"
              ],
              question: "5 个手指,2 个在跑,剩几个?",
              choices: [3, 2, 4],
              answer: 3),
        .init(noomNumber: 6,
              lines: [
                "六六是个大顺儿!",
                "它搬来 3 颗苹果,",
                "又搬来 3 颗橘子,",
                "要摆一个漂亮的果盘。"
              ],
              question: "果盘里一共几个水果?",
              choices: [5, 6, 7],
              answer: 6),
        .init(noomNumber: 7,
              lines: [
                "奇奇最爱彩虹,",
                "彩虹有 7 种颜色。",
                "今天它数到了 4 种,",
                "就被云朵盖住了。"
              ],
              question: "还差几种颜色没数到?",
              choices: [3, 2, 4],
              answer: 3),
        .init(noomNumber: 8,
              lines: [
                "胖胖圆滚滚像个数字 8,",
                "它今天吃了 5 个饺子,",
                "妈妈说再吃 3 个就饱。",
                "胖胖鼓起肚子吃完了。"
              ],
              question: "胖胖一共吃了几个饺子?",
              choices: [7, 8, 9],
              answer: 8),
        .init(noomNumber: 9,
              lines: [
                "九妹快要变大啦,",
                "它现在有 9 颗星星徽章,",
                "再得 1 颗就满 10 啦!",
                "快给它加油。"
              ],
              question: "九妹现在有几颗星?",
              choices: [9, 10, 8],
              answer: 9),
        .init(noomNumber: 10,
              lines: [
                "十全大王要开派对,",
                "它邀请了 10 个朋友。",
                "分成两组做游戏:",
                "一组 4 个,另一组..."
              ],
              question: "另一组有几个朋友?",
              choices: [6, 5, 7],
              answer: 6),
    ]

    static func story(forNoom number: Int) -> NoomStory? {
        all.first { $0.noomNumber == number }
    }

    /// All Noom numbers that have a story written. Used by the view to
    /// filter the child's owned pets to those that actually have a page.
    static var availableNumbers: [Int] { all.map(\.noomNumber) }
}
