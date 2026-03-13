import Testing
@testable import Neurova

struct ReviewAnalyticsTests {
    @Test
    func ratesAreComputedFromEventCounts() {
        let analytics = ReviewAnalytics(counts: [
            .reviewAgain: 2,
            .reviewHard: 1,
            .reviewGood: 3,
            .reviewEasy: 4,
            .skipHard: 1,
            .autoHardTimeout: 1
        ])

        #expect(analytics.totalReviews == 12)
        #expect(analytics.againRate == 2.0 / 12.0)
        #expect(analytics.hardRate == 1.0 / 12.0)
        #expect(analytics.goodRate == 3.0 / 12.0)
        #expect(analytics.easyRate == 4.0 / 12.0)
        #expect(analytics.skipRate == 1.0 / 12.0)
        #expect(analytics.autoHardRate == 1.0 / 12.0)
    }

    @Test
    func emptyCountsProduceZeroRates() {
        let analytics = ReviewAnalytics(counts: [:])

        #expect(analytics.totalReviews == 0)
        #expect(analytics.againRate == 0)
        #expect(analytics.hardRate == 0)
        #expect(analytics.goodRate == 0)
        #expect(analytics.easyRate == 0)
        #expect(analytics.skipRate == 0)
        #expect(analytics.autoHardRate == 0)
    }
}
