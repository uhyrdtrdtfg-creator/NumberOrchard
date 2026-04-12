import Foundation

struct Station: Identifiable, Sendable, Hashable {
    let id: String
    let level: DifficultyLevel
    let displayName: String
    let emoji: String
    let unlocks: [String]
    let mapX: Double
    let mapY: Double
    let starFruitId: String?
}

enum MapCatalog {
    static let stations: [Station] = [
        // L1 (3)
        .init(id: "L1-1", level: .seed, displayName: "苹果小屋", emoji: "🏡",
              unlocks: ["L1-2"], mapX: 0.5, mapY: 0.95, starFruitId: "apple"),
        .init(id: "L1-2", level: .seed, displayName: "草莓小屋", emoji: "🏡",
              unlocks: ["L1-3"], mapX: 0.5, mapY: 0.88, starFruitId: "strawberry"),
        .init(id: "L1-3", level: .seed, displayName: "梨树小屋", emoji: "🏡",
              unlocks: ["L2-1"], mapX: 0.5, mapY: 0.81, starFruitId: "pear"),
        // L2 (3)
        .init(id: "L2-1", level: .sprout, displayName: "橘子小屋", emoji: "🛖",
              unlocks: ["L2-2"], mapX: 0.5, mapY: 0.74, starFruitId: "orange"),
        .init(id: "L2-2", level: .sprout, displayName: "柠檬小屋", emoji: "🛖",
              unlocks: ["L2-3"], mapX: 0.5, mapY: 0.67, starFruitId: "lemon"),
        .init(id: "L2-3", level: .sprout, displayName: "香蕉小屋", emoji: "🛖",
              unlocks: ["L3-1"], mapX: 0.5, mapY: 0.60, starFruitId: "banana"),
        // L3 (3)
        .init(id: "L3-1", level: .smallTree, displayName: "西瓜小屋", emoji: "⛺",
              unlocks: ["L3-2"], mapX: 0.5, mapY: 0.53, starFruitId: "watermelon"),
        .init(id: "L3-2", level: .smallTree, displayName: "葡萄小屋", emoji: "⛺",
              unlocks: ["L3-3"], mapX: 0.5, mapY: 0.46, starFruitId: "grape"),
        .init(id: "L3-3", level: .smallTree, displayName: "樱桃小屋", emoji: "⛺",
              unlocks: ["L4-1"], mapX: 0.5, mapY: 0.39, starFruitId: "cherry"),
        // L4 (3)
        .init(id: "L4-1", level: .bigTree, displayName: "桃子小屋", emoji: "🏯",
              unlocks: ["L4-2"], mapX: 0.5, mapY: 0.33, starFruitId: "peach"),
        .init(id: "L4-2", level: .bigTree, displayName: "番茄小屋", emoji: "🏯",
              unlocks: ["L4-3"], mapX: 0.5, mapY: 0.27, starFruitId: "tomato"),
        .init(id: "L4-3", level: .bigTree, displayName: "橙子小屋", emoji: "🏯",
              unlocks: ["L5-1"], mapX: 0.5, mapY: 0.21, starFruitId: "tangerine"),
        // L5 branch (4)
        .init(id: "L5-1", level: .bloom, displayName: "蓝莓城堡", emoji: "🏰",
              unlocks: ["L5-3"], mapX: 0.3, mapY: 0.17, starFruitId: "blueberry"),
        .init(id: "L5-2", level: .bloom, displayName: "芒果城堡", emoji: "🏰",
              unlocks: ["L5-4"], mapX: 0.7, mapY: 0.17, starFruitId: "mango"),
        .init(id: "L5-3", level: .bloom, displayName: "菠萝城堡", emoji: "🏰",
              unlocks: ["L6-1"], mapX: 0.3, mapY: 0.12, starFruitId: "pineapple"),
        .init(id: "L5-4", level: .bloom, displayName: "椰子城堡", emoji: "🏰",
              unlocks: ["L6-2"], mapX: 0.7, mapY: 0.12, starFruitId: "coconut"),
        // L6 branch (4)
        .init(id: "L6-1", level: .harvest, displayName: "火龙果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.3, mapY: 0.07, starFruitId: "dragon_fruit"),
        .init(id: "L6-2", level: .harvest, displayName: "金苹果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.7, mapY: 0.07, starFruitId: "golden_apple"),
        .init(id: "L6-3", level: .harvest, displayName: "彩虹果宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.3, mapY: 0.03, starFruitId: "rainbow_fruit"),
        .init(id: "L6-4", level: .harvest, displayName: "水晶宫殿", emoji: "🎪",
              unlocks: ["end"], mapX: 0.7, mapY: 0.03, starFruitId: "crystal_berry"),
    ]

    static let endStationId = "end"
    static let initialStationId = "L1-1"

    static func station(id: String) -> Station? {
        stations.first { $0.id == id }
    }
}
