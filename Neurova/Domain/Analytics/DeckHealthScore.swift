import Foundation

struct DeckHealthScore {
    let score: Int

    /// Computes a 0-100 health score for a deck based on review outcome distribution.
    ///
    /// Formula: `base(78) + consistencyBonus(up to 12) + easyReward(8) − penalties`
    ///
    /// Penalty weights reflect how harmful each outcome is to long-term retention:
    /// - **Again (42)**: Highest — card was forgotten, strong negative signal.
    /// - **Hard (26)**: Moderate — recall was effortful and fragile.
    /// - **Skip (20)**: Significant — card was avoided entirely, no learning occurred.
    /// - **AutoHard (16)**: Mild — system-inferred difficulty, less decisive than user-reported.
    init(analytics: ReviewAnalytics) {
        let total = max(analytics.totalReviews, 1)
        let consistencyBonus = min(Double(total) * 0.6, 12)
        let reward = analytics.easyRate * 8
        let penalties =
            (analytics.againRate * 42) +
            (analytics.hardRate * 26) +
            (analytics.skipRate * 20) +
            (analytics.autoHardRate * 16)

        let rawScore = 78 + consistencyBonus + reward - penalties
        score = min(max(Int(rawScore.rounded()), 0), 100)
    }

    var label: String {
        switch score {
        case ..<45:
            return "Needs review"
        case ..<70:
            return "Watch closely"
        case ..<85:
            return "Healthy"
        default:
            return "Strong"
        }
    }
}
