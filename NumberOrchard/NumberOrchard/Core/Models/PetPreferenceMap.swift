import Foundation

enum PetPreferenceMap {
    /// Each Noom (1-20) prefers certain fruits — feeding a preferred fruit doubles XP gain.
    /// Fruit IDs must exist in `FruitCatalog`.
    static let preferences: [Int: [String]] = [
        1:  ["apple", "strawberry"],
        2:  ["banana", "lemon"],
        3:  ["cherry", "red_grape"],
        4:  ["orange", "tangerine"],
        5:  ["watermelon", "melon"],
        6:  ["grape", "blueberry"],
        7:  ["peach", "apricot"],
        8:  ["mango", "pineapple"],
        9:  ["kiwi", "tomato"],
        10: ["green_apple", "avocado"],

        11: ["blueberry", "kiwi"],
        12: ["mango", "coconut"],
        13: ["chestnut", "olive"],
        14: ["starfruit"],
        15: ["dragon_fruit"],
        16: ["golden_apple"],
        17: ["rainbow_fruit"],
        18: ["crystal_berry"],
        19: ["sun_fruit"],
        20: ["golden_apple", "crystal_berry"],
    ]

    static func isPreferred(fruitId: String, for noomNumber: Int) -> Bool {
        preferences[noomNumber]?.contains(fruitId) ?? false
    }
}
