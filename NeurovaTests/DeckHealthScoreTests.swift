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
}
