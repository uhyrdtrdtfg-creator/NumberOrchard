import Foundation

enum FruitRarity: String, Sendable {
    case common    = "常见"
    case rare      = "稀有"
    case legendary = "传说"
}

struct FruitItem: Identifiable, Sendable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let rarity: FruitRarity
    let funFact: String
}

enum FruitCatalog {
    static let fruits: [FruitItem] = [
        // Common (15)
        .init(id: "apple",        emoji: "🍎", name: "苹果",     rarity: .common,    funFact: "一天一苹果，医生远离我！"),
        .init(id: "green_apple",  emoji: "🍏", name: "青苹果",   rarity: .common,    funFact: "酸酸甜甜，最清爽！"),
        .init(id: "pear",         emoji: "🍐", name: "梨",       rarity: .common,    funFact: "秋天的梨最水润。"),
        .init(id: "orange",       emoji: "🍊", name: "橘子",     rarity: .common,    funFact: "冬天吃橘子最暖心。"),
        .init(id: "lemon",        emoji: "🍋", name: "柠檬",     rarity: .common,    funFact: "酸酸的柠檬富含维生素C。"),
        .init(id: "banana",       emoji: "🍌", name: "香蕉",     rarity: .common,    funFact: "香蕉是猴子最爱！"),
        .init(id: "watermelon",   emoji: "🍉", name: "西瓜",     rarity: .common,    funFact: "夏天吃西瓜最消暑。"),
        .init(id: "grape",        emoji: "🍇", name: "葡萄",     rarity: .common,    funFact: "一串串的葡萄最可爱。"),
        .init(id: "strawberry",   emoji: "🍓", name: "草莓",     rarity: .common,    funFact: "小小的草莓有100多颗种子。"),
        .init(id: "cherry",       emoji: "🍒", name: "樱桃",     rarity: .common,    funFact: "樱桃是春天的味道。"),
        .init(id: "peach",        emoji: "🍑", name: "桃子",     rarity: .common,    funFact: "寿星公手里的就是大桃子！"),
        .init(id: "tomato",       emoji: "🍅", name: "番茄",     rarity: .common,    funFact: "番茄其实是水果哦！"),
        .init(id: "tangerine",    emoji: "🍊", name: "橙子",     rarity: .common,    funFact: "橙子榨成橙汁最好喝。"),
        .init(id: "red_grape",    emoji: "🍇", name: "红提",     rarity: .common,    funFact: "红提比绿提更甜。"),
        .init(id: "apricot",      emoji: "🍑", name: "杏",       rarity: .common,    funFact: "杏花开在春天里。"),

        // Rare (10)
        .init(id: "blueberry",    emoji: "🫐", name: "蓝莓",     rarity: .rare,      funFact: "蓝莓对眼睛很好！"),
        .init(id: "melon",        emoji: "🍈", name: "哈密瓜",   rarity: .rare,      funFact: "哈密瓜是瓜中之王。"),
        .init(id: "mango",        emoji: "🥭", name: "芒果",     rarity: .rare,      funFact: "热带的芒果最甜。"),
        .init(id: "pineapple",    emoji: "🍍", name: "菠萝",     rarity: .rare,      funFact: "菠萝头上有绿色的王冠。"),
        .init(id: "coconut",      emoji: "🥥", name: "椰子",     rarity: .rare,      funFact: "椰子水是天然的饮料。"),
        .init(id: "kiwi",         emoji: "🥝", name: "猕猴桃",   rarity: .rare,      funFact: "猕猴桃的维生素C超多！"),
        .init(id: "avocado",      emoji: "🥑", name: "牛油果",   rarity: .rare,      funFact: "牛油果中间有颗大籽。"),
        .init(id: "chestnut",     emoji: "🌰", name: "栗子",     rarity: .rare,      funFact: "糖炒栗子香喷喷的！"),
        .init(id: "olive",        emoji: "🫒", name: "橄榄",     rarity: .rare,      funFact: "橄榄是和平的象征。"),
        .init(id: "starfruit",    emoji: "⭐", name: "杨桃",     rarity: .rare,      funFact: "切开像一颗颗小星星！"),

        // Legendary (5)
        .init(id: "dragon_fruit", emoji: "🐲", name: "火龙果",   rarity: .legendary, funFact: "火龙果里面有好多黑籽！"),
        .init(id: "golden_apple", emoji: "🟡", name: "金苹果",   rarity: .legendary, funFact: "传说中的金苹果！"),
        .init(id: "rainbow_fruit",emoji: "🌈", name: "彩虹果",   rarity: .legendary, funFact: "七种颜色的神奇水果！"),
        .init(id: "crystal_berry",emoji: "💎", name: "水晶浆果", rarity: .legendary, funFact: "闪闪发光的水晶味道！"),
        .init(id: "sun_fruit",    emoji: "☀️", name: "太阳果",   rarity: .legendary, funFact: "只在终点果园才能找到。"),
    ]

    static func fruit(id: String) -> FruitItem? {
        fruits.first { $0.id == id }
    }

    static func fruits(rarity: FruitRarity) -> [FruitItem] {
        fruits.filter { $0.rarity == rarity }
    }
}
