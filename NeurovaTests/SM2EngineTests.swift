import Foundation
import Testing
@testable import Neurova

struct SM2EngineTests {
    @Test
    func firstGoodReviewStartsRepetitionWithOneDayInterval() {
        let reviewDate = Date(timeIntervalSinceReferenceDate: 0)
        let result = SM2Engine().review(previous: nil, quality: .good, reviewDate: reviewDate)

        #expect(result.repetition == 1)
        #expect(result.interval == 1)
        #expect(result.easinessFactor == 2.5)
        #expect(result.lapses == 0)
    }

    @Test
    func secondSuccessfulReviewMovesToSixDays() {
        let reviewDate = Date(timeIntervalSinceReferenceDate: 0)
        let previous = SM2Result(
            repetition: 1,
            interval: 1,
            easinessFactor: 2.5,
            nextReviewDate: reviewDate,
            lapses: 0
        )

        let result = SM2Engine().review(previous: previous, quality: .good, reviewDate: reviewDate)

        #expect(result.repetition == 2)
        #expect(result.interval == 6)
        #expect(result.lapses == 0)
    }

    @Test
    func failedReviewResetsRepetitionAndIncrementsLapses() {
        let reviewDate = Date(timeIntervalSinceReferenceDate: 0)
        let previous = SM2Result(
            repetition: 5,
            interval: 18,
            easinessFactor: 1.4,
            nextReviewDate: reviewDate,
            lapses: 2
        )

        let result = SM2Engine().review(previous: previous, quality: .again, reviewDate: reviewDate)

        #expect(result.repetition == 0)
        #expect(result.interval == 1)
        #expect(result.lapses == 3)
        #expect(result.easinessFactor == 1.3)
    }
}
