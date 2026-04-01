import Testing
@testable import Neurova

struct DeckHealthScoreTests {
    @Test
    func strongDeckGetsStrongLabel() {
        let analytics = ReviewAnalytics(counts: [.reviewEasy: 20])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 98)
        #expect(result.label == "Strong")
    }

    @Test
    func repeatedFailuresCanDropDeckIntoNeedsReview() {
        let analytics = ReviewAnalytics(counts: [.reviewAgain: 1])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 37)
        #expect(result.label == "Needs review")
    }

    @Test
    func mixedHardAndAgainAnswersStayInWatchCloselyBand() {
        let analytics = ReviewAnalytics(counts: [.reviewAgain: 10, .reviewHard: 10])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 56)
        #expect(result.label == "Watch closely")
    }

    @Test
    func scoreNeverExceedsOneHundred() {
        let analytics = ReviewAnalytics(counts: [.reviewEasy: 500])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 100)
    }

    @Test
    func scoreNeverDropsBelowZero() {
        let analytics = ReviewAnalytics(counts: [.reviewAgain: 500])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 0)
    }

    @Test
    func healthyLabelForScoreInMidRange() {
        let analytics = ReviewAnalytics(counts: [.reviewGood: 15, .reviewHard: 3])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score >= 70)
        #expect(result.score < 85)
        #expect(result.label == "Healthy")
    }

    @Test
    func emptyAnalyticsDefaultsToBaseScore() {
        let analytics = ReviewAnalytics(counts: [:])
        let result = DeckHealthScore(analytics: analytics)

        #expect(result.score == 79)
        #expect(result.label == "Healthy")
    }
}
