import Foundation

/// Pure logic for the once-per-day free wardrobe gacha. Given the child's
/// `lastGachaDate` and a current date, answer two questions:
///   1. Is a claim available right now?
///   2. Which skin should they receive?
///
/// A "day" is a local calendar day — crossing midnight enables the next
/// claim. If the child has already owned the rolled skin, the caller is
/// free to re-roll (the VM handles that); this logic deals only with
/// eligibility and picking.
enum DailyGachaLogic {
    /// True if the child is allowed to claim today's free pull.
    static func isClaimable(lastClaim: Date?, now: Date = Date(),
                            calendar: Calendar = .current) -> Bool {
        guard let lastClaim else { return true }
        return !calendar.isDate(lastClaim, inSameDayAs: now)
    }

    /// Calendar day at which the next claim becomes available (i.e. the
    /// start of the day *after* `lastClaim`). Nil if never claimed.
    static func nextClaimDate(lastClaim: Date?,
                              calendar: Calendar = .current) -> Date? {
        guard let lastClaim else { return nil }
        let dayStart = calendar.startOfDay(for: lastClaim)
        return calendar.date(byAdding: .day, value: 1, to: dayStart)
    }

    /// Pick a random skin from the gacha-eligible pool. Caller may filter
    /// out already-owned skins and re-roll; this function itself is
    /// stateless and pool-independent so tests can seed the RNG.
    static func roll(
        pool: [NoomSkin] = NoomSkinCatalog.gachaEligible(),
        rng: inout some RandomNumberGenerator
    ) -> NoomSkin? {
        pool.randomElement(using: &rng)
    }
}
