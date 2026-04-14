import Foundation
import UIKit

struct Noom: Identifiable, Sendable, Hashable {
    let number: Int
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
    ]
    static func noom(for n: Int) -> Noom? { all.first { $0.number == n } }

    static var smallNooms: [Noom] { all.filter { $0.number <= 10 } }
    static var bigNooms: [Noom] { all.filter { $0.number >= 11 } }
}
