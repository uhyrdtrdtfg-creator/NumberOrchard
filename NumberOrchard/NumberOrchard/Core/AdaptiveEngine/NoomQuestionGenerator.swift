import Foundation

enum NoomChallengeType: Sendable, Equatable {
    case merge(a: Int, b: Int)
    case split(total: Int)
}

struct NoomQuestionGenerator: Sendable {
    /// Generate 5 questions: Q1-Q2 merge ≤5, Q3 split, Q4-Q5 merge ≤10.
    /// Prefers Nooms that haven't been unlocked yet (3x weight).
    func generateSession(alreadyUnlocked: Set<Int>) -> [NoomChallengeType] {
        var session: [NoomChallengeType] = []
        session.append(generateMerge(maxSum: 5, alreadyUnlocked: alreadyUnlocked))
        session.append(generateMerge(maxSum: 5, alreadyUnlocked: alreadyUnlocked))
        session.append(generateSplit(alreadyUnlocked: alreadyUnlocked))
        session.append(generateMerge(maxSum: 10, alreadyUnlocked: alreadyUnlocked))
        session.append(generateMerge(maxSum: 10, alreadyUnlocked: alreadyUnlocked))
        return session
    }

    private func generateMerge(maxSum: Int, alreadyUnlocked: Set<Int>) -> NoomChallengeType {
        var weighted: [((Int, Int), Int)] = []
        for a in 1..<maxSum {
            for b in 1...(maxSum - a) {
                let sum = a + b
                let weight = alreadyUnlocked.contains(sum) ? 1 : 3
                weighted.append(((a, b), weight))
            }
        }
        let pick = weightedRandom(weighted)
        return .merge(a: pick.0, b: pick.1)
    }

    private func generateSplit(alreadyUnlocked: Set<Int>) -> NoomChallengeType {
        var weighted: [(Int, Int)] = []
        for total in 3...5 {
            let weight = alreadyUnlocked.contains(total) ? 1 : 3
            weighted.append((total, weight))
        }
        return .split(total: weightedRandom(weighted))
    }

    private func weightedRandom<T>(_ items: [(T, Int)]) -> T {
        let totalWeight = items.reduce(0) { $0 + $1.1 }
        var roll = Int.random(in: 0..<max(totalWeight, 1))
        for (item, weight) in items {
            roll -= weight
            if roll < 0 { return item }
        }
        return items.last!.0
    }
}
