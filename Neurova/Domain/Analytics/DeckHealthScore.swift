import Foundation

struct DeckHealthScore {
    let score: Int

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
