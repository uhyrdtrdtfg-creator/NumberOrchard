import Foundation

struct DecorationPurchaseResult: Sendable {
    let success: Bool
    let remainingStars: Int
}

struct DecorationPurchaseLogic: Sendable {
    func purchase(item: DecorationItem, availableStars: Int) -> DecorationPurchaseResult {
        guard availableStars >= item.cost else {
            return DecorationPurchaseResult(success: false, remainingStars: availableStars)
        }
        return DecorationPurchaseResult(success: true, remainingStars: availableStars - item.cost)
    }
}
