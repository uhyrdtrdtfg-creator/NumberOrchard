import Foundation

/// One classic Chinese children's rhyme with numbers baked in. Each
/// line carries an optional highlight number so the view can show a
/// glowing badge while narration reads that line — gives the child
/// both audio and visual counting together.
struct NumberRhyme: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let emoji: String
    /// Narrative lines. Nil highlight = no number badge for that beat.
    let lines: [Line]

    struct Line: Sendable, Hashable {
        let text: String
        let highlight: Int?
    }
}

enum NumberRhymeCatalog {
    static let all: [NumberRhyme] = [
        // 《一去二三里》— classic counting poem, 10 numbers in 4 lines.
        .init(
            id: "yi_qu_er_san_li",
            title: "《一去二三里》",
            emoji: "🏞️",
            lines: [
                .init(text: "一去二三里,",   highlight: 3),
                .init(text: "烟村四五家。",   highlight: 5),
                .init(text: "亭台六七座,",   highlight: 7),
                .init(text: "八九十枝花。",   highlight: 10),
            ]
        ),

        // 《数鸭子》— ducks on the bridge counting 1-8.
        .init(
            id: "shu_ya_zi",
            title: "《数鸭子》",
            emoji: "🦆",
            lines: [
                .init(text: "门前大桥下,",                highlight: nil),
                .init(text: "游过一群鸭。",                highlight: 1),
                .init(text: "快来快来数一数,",             highlight: nil),
                .init(text: "二四六七八!",                 highlight: 8),
            ]
        ),

        // 《12345 上山打老虎》— rhythmic counting from 1-10.
        .init(
            id: "shang_shan_da_lao_hu",
            title: "《上山打老虎》",
            emoji: "🐯",
            lines: [
                .init(text: "一二三四五,",  highlight: 5),
                .init(text: "上山打老虎。",  highlight: nil),
                .init(text: "老虎不在家,",  highlight: nil),
                .init(text: "打到小松鼠。",  highlight: nil),
                .init(text: "六七八九十!",  highlight: 10),
            ]
        ),

        // 《数青蛙》— 1 frog → 1 mouth, 2 eyes, 4 legs. Teaches 倍数 sense.
        .init(
            id: "shu_qing_wa",
            title: "《数青蛙》",
            emoji: "🐸",
            lines: [
                .init(text: "一只青蛙一张嘴,",    highlight: 1),
                .init(text: "两只眼睛四条腿。",    highlight: 4),
                .init(text: "扑通一声跳下水,",    highlight: nil),
                .init(text: "池塘里的水花开!",    highlight: nil),
            ]
        ),
    ]

    static func rhyme(id: String) -> NumberRhyme? {
        all.first { $0.id == id }
    }
}
