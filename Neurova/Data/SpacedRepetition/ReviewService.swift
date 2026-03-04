import Foundation
import SwiftData

struct ReviewService {
    private let engine: any SpacedRepetitionEngine

    init(engine: any SpacedRepetitionEngine = SM2Engine()) {
        self.engine = engine
    }

    @discardableResult
    func review(
        card: Card,
        quality: ReviewQuality,
        at reviewDate: Date = .now,
        in context: ModelContext
    ) throws -> SM2Result {
        let previousState = SM2Result(
            repetition: card.repetition,
            interval: card.interval,
            easinessFactor: card.easinessFactor,
            nextReviewDate: card.nextReviewDate,
            lapses: card.lapses
        )

        let result = engine.review(
            previous: previousState,
            quality: quality,
            reviewDate: reviewDate
        )

        card.repetition = result.repetition
        card.interval = result.interval
        card.easinessFactor = result.easinessFactor
        card.nextReviewDate = result.nextReviewDate
        card.lastReviewDate = reviewDate
        card.lapses = result.lapses
        card.lastReviewQuality = quality

        try context.save()

        return result
    }
}
