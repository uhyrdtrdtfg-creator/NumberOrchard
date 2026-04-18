import Foundation

/// Cosmetic hat / accessory overlay that renders on top of a Noom. Purely
/// decorative — no gameplay effect, priced in stars. A pet may have at
/// most one hat equipped at a time; unequipping a hat is free.
///
/// Hats unlock by being purchased from the wardrobe once a Noom reaches
/// Adult stage (the only stage that would wear a hat to begin with,
/// matching how the base renderer already draws a crown at stage 2).
struct NoomSkin: Identifiable, Sendable, Hashable {
    /// Stable identifier used in persistence + wardrobe selection.
    let id: String
    /// Emoji glyph drawn on top of the Noom by NoomRenderer.
    let glyph: String
    let name: String
    /// Star cost in the wardrobe. Premium hats cost more.
    let cost: Int
    /// One-liner shown under the hat in the store grid.
    let flavour: String
}

enum NoomSkinCatalog {
    static let all: [NoomSkin] = [
        .init(id: "strawhat",    glyph: "👒", name: "草帽",
              cost: 5,  flavour: "阳光田野的标配"),
        .init(id: "topper",      glyph: "🎩", name: "礼帽",
              cost: 8,  flavour: "绅士风范的小精灵"),
        .init(id: "graduation",  glyph: "🎓", name: "学士帽",
              cost: 10, flavour: "学霸就是你啦!"),
        .init(id: "partyhat",    glyph: "🥳", name: "派对帽",
              cost: 12, flavour: "每天都是生日!"),
        .init(id: "chef",        glyph: "🎭", name: "戏剧面具",
              cost: 15, flavour: "数学小剧场常驻嘉宾"),
        .init(id: "wizard",      glyph: "🧙", name: "巫师帽",
              cost: 20, flavour: "魔法加持,好运翻倍的样子"),
    ]

    static func skin(id: String) -> NoomSkin? {
        all.first { $0.id == id }
    }
}
