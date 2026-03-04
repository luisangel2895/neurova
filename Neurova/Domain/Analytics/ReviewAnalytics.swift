import Foundation

struct ReviewAnalytics {
    let hardRate: Double
    let againRate: Double
    let goodRate: Double
    let easyRate: Double
    let skipRate: Double
    let autoHardRate: Double
    let totalReviews: Int

    init(counts: [XPEventType: Int]) {
        let total = counts.values.reduce(0, +)
        self.totalReviews = total

        func rate(for type: XPEventType) -> Double {
            guard total > 0 else { return 0 }
            return Double(counts[type, default: 0]) / Double(total)
        }

        hardRate = rate(for: .reviewHard)
        againRate = rate(for: .reviewAgain)
        goodRate = rate(for: .reviewGood)
        easyRate = rate(for: .reviewEasy)
        skipRate = rate(for: .skipHard)
        autoHardRate = rate(for: .autoHardTimeout)
    }
}
