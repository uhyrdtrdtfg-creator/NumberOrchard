import Foundation
import CoreGraphics

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

    /// Emoji rendering size (pt) when placed in the orchard. Different categories get
    /// different sizes so a 🏰 feels bigger than a 🐞, producing visual hierarchy.
    var placedSize: CGFloat {
        switch self {
        case .fence:    return 56
        case .flower:   return 60
        case .plant:    return 96
        case .animal:   return 52
        case .water:    return 84
        case .building: return 124
        case .festival: return 76
        }
    }
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
