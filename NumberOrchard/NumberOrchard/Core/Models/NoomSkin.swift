import Foundation

/// Cosmetic hat / accessory overlay that renders on top of a Noom. Purely
/// decorative — no gameplay effect, priced in stars. A pet may have at
/// most one hat equipped at a time; unequipping a hat is free.
///
/// Hats unlock by being purchased from the wardrobe once a Noom reaches
/// Adult stage (the only stage that would wear a hat to begin with,
/// matching how the base renderer already draws a crown at stage 2).
struct NoomSkin: Identifiable, Sendable, Hashable {
    /// Which slot on the Noom this accessory occupies. A pet may have one
    /// item per slot equipped simultaneously (so a hat + a collar stack).
    enum Slot: String, Sendable, Codable, CaseIterable {
        case hat     // drawn at the crown
        case collar  // drawn around the neck
    }

    /// Stable identifier used in persistence + wardrobe selection.
    let id: String
    /// Emoji glyph drawn on top of the Noom by NoomRenderer.
    let glyph: String
    let name: String
    /// Star cost in the wardrobe. Premium items cost more.
    let cost: Int
    /// One-liner shown under the item in the store grid.
    let flavour: String
    /// Physical slot this item occupies. Defaults to hat for backwards
    /// compatibility with the original 6-hat catalogue.
    var slot: Slot = .hat
    /// Minimum pet stage required to *equip* (and therefore to purchase)
    /// this item. 0 = any, 2 = adult only. Used to gate premium items
    /// behind the child's hard-earned evolutions.
    var unlockStage: Int = 0
}

enum NoomSkinCatalog {
    static let all: [NoomSkin] = [
        // Hats
        .init(id: "strawhat",    glyph: "👒", name: "草帽",
              cost: 5,  flavour: "阳光田野的标配",
              slot: .hat, unlockStage: 0),
        .init(id: "topper",      glyph: "🎩", name: "礼帽",
              cost: 8,  flavour: "绅士风范的小精灵",
              slot: .hat, unlockStage: 0),
        .init(id: "graduation",  glyph: "🎓", name: "学士帽",
              cost: 10, flavour: "学霸就是你啦!",
              slot: .hat, unlockStage: 0),
        .init(id: "partyhat",    glyph: "🥳", name: "派对帽",
              cost: 12, flavour: "每天都是生日!",
              slot: .hat, unlockStage: 0),
        // Premium hats — locked until the pet is Adult.
        .init(id: "chef",        glyph: "🎭", name: "戏剧面具",
              cost: 15, flavour: "数学小剧场常驻嘉宾",
              slot: .hat, unlockStage: 2),
        .init(id: "wizard",      glyph: "🧙", name: "巫师帽",
              cost: 20, flavour: "魔法加持,好运翻倍的样子",
              slot: .hat, unlockStage: 2),

        // Collars — new slot, lower price tier. Stack on top of any hat.
        .init(id: "bowtie",      glyph: "🎀", name: "蝴蝶结",
              cost: 4,  flavour: "软萌百搭小物",
              slot: .collar, unlockStage: 0),
        .init(id: "medal",       glyph: "🏅", name: "奖牌",
              cost: 6,  flavour: "本周学习之星",
              slot: .collar, unlockStage: 0),
        .init(id: "scarf",       glyph: "🧣", name: "围巾",
              cost: 8,  flavour: "冬天最温暖的款",
              slot: .collar, unlockStage: 0),
        .init(id: "necktie",     glyph: "👔", name: "领结",
              cost: 12, flavour: "成年 Noom 的体面",
              slot: .collar, unlockStage: 2),
    ]

    static func skin(id: String) -> NoomSkin? {
        all.first { $0.id == id }
    }

    /// Only items in the hat/collar slots up to `maxCost` (common-ish
    /// tier) are eligible for the free daily gacha pull.
    static func gachaEligible(maxCost: Int = 10) -> [NoomSkin] {
        all.filter { $0.cost <= maxCost && $0.unlockStage == 0 }
    }
}
