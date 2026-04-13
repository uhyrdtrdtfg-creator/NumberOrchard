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
    ]
    static func noom(for n: Int) -> Noom? { all.first { $0.number == n } }
}
