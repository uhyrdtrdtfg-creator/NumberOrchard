import Foundation

struct StationReward: Sendable {
    let starsEarned: Int
    let seedsEarned: Int
    let fruitIdEarned: String?
}

struct RewardCalculator: Sendable {

    func calculate(stars: Int, isFirstCompletion: Bool, station: Station) -> StationReward {
        var starsEarned = 3
        if stars >= 2 { starsEarned += 2 }
        if stars >= 3 { starsEarned += 3 }

        let seedsEarned = isFirstCompletion ? 1 : 0
        let fruitIdEarned: String? = (stars == 3 && isFirstCompletion) ? station.starFruitId : nil

        return StationReward(
            starsEarned: starsEarned,
            seedsEarned: seedsEarned,
            fruitIdEarned: fruitIdEarned
        )
    }
}
