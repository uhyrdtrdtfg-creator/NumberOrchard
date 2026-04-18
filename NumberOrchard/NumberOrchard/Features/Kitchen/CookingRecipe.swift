import Foundation

/// Pure state for a single cooking round. A recipe names 2-3 fruits with
/// target counts; the child taps fruits from the pantry to add them to
/// the basket. When basket counts match target counts exactly, the
/// recipe is served. Over-filling is possible and is gently caught by
/// the view (no auto-penalty — the child can dump the basket and retry).
struct CookingRecipe: Sendable, Equatable {
    /// Target quantities by fruit id, e.g. ["apple": 2, "strawberry": 3].
    let target: [String: Int]
    /// What the child has added so far.
    private(set) var basket: [String: Int] = [:]

    var totalTarget: Int { target.values.reduce(0, +) }
    var totalBasket: Int { basket.values.reduce(0, +) }

    var isComplete: Bool {
        target.allSatisfy { basket[$0.key, default: 0] == $0.value }
            && totalBasket == totalTarget
    }

    /// True if any single fruit exceeds its needed count. The view can
    /// highlight that fruit's counter and suggest clearing it.
    var isOverfilled: Bool {
        target.contains { key, needed in (basket[key] ?? 0) > needed }
    }

    /// Fruits that appear in the recipe. View renders one pantry button
    /// per entry plus some distractors.
    var recipeFruits: [String] { Array(target.keys) }

    mutating func add(_ fruitId: String) {
        basket[fruitId, default: 0] += 1
    }

    mutating func remove(_ fruitId: String) {
        let current = basket[fruitId] ?? 0
        guard current > 0 else { return }
        basket[fruitId] = current - 1
    }

    mutating func dumpBasket() {
        basket.removeAll()
    }
}

enum CookingRecipeGenerator {
    /// Curated fruit pool for the pantry — small enough that a recipe
    /// visually fits on screen, recognisable enough that children can
    /// tell them apart from emoji alone.
    static let pantryIds: [String] = [
        "apple", "strawberry", "banana", "orange",
        "grape", "peach", "cherry", "watermelon"
    ]

    /// Pick 2-3 distinct fruits with counts that sum to `totalUpperBound`.
    /// Totals stay within age-appropriate addition range.
    static func makeRecipe(
        maxTotal: Int = 7,
        rng: inout some RandomNumberGenerator
    ) -> CookingRecipe {
        let distinctCount = Int.random(in: 2...3, using: &rng)
        let shuffled = pantryIds.shuffled(using: &rng)
        let chosenIds = Array(shuffled.prefix(distinctCount))
        var target: [String: Int] = [:]
        var remaining = Int.random(in: max(distinctCount, 3)...maxTotal, using: &rng)
        for (i, id) in chosenIds.enumerated() {
            let isLast = (i == chosenIds.count - 1)
            let cap = remaining - (chosenIds.count - 1 - i)  // leave 1 for each future id
            let pick: Int
            if isLast {
                pick = max(1, remaining)
            } else {
                pick = Int.random(in: 1...max(1, cap), using: &rng)
            }
            target[id] = pick
            remaining -= pick
        }
        return CookingRecipe(target: target)
    }
}
