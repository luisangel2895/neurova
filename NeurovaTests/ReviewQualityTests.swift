import Testing
@testable import Neurova

struct ReviewQualityTests {
    @Test
    func sm2ScoresMatchExpectedMapping() {
        #expect(ReviewQuality.again.sm2Score == 0)
        #expect(ReviewQuality.hard.sm2Score == 3)
        #expect(ReviewQuality.good.sm2Score == 4)
        #expect(ReviewQuality.easy.sm2Score == 5)
    }
}
