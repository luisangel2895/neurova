import Foundation
import SwiftData

struct ReviewService {
    private let engine: any SpacedRepetitionEngine
    private let xpPolicy: any XPPolicy

    init(
        engine: any SpacedRepetitionEngine = SM2Engine(),
        xpPolicy: any XPPolicy = DefaultXPPolicy()
    ) {
        self.engine = engine
        self.xpPolicy = xpPolicy
    }

    @discardableResult
    func review(
        card: Card,
        quality: ReviewQuality,
        eventType: XPEventType? = nil,
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

        let resolvedEventType = eventType ?? defaultXPEventType(for: quality)
        let xpEvent = XPEvent(
            id: UUID(),
            date: reviewDate,
            deckId: card.deck?.id,
            cardId: nil,
            eventType: resolvedEventType,
            xpDelta: xpPolicy.xpDelta(for: resolvedEventType)
        )

        let xpRepository = SwiftDataXPEventRepository(context: context)
        try xpRepository.record(
            xpEvent,
            integrityContext: XPEventIntegrityContext(
                source: "ReviewService.review",
                expectedDeckId: card.deck != nil,
                expectedCardId: false,
                cardIdDescription: "n/a",
                deckTitle: card.deck?.title
            )
        )

        return result
    }

    private func defaultXPEventType(for quality: ReviewQuality) -> XPEventType {
        switch quality {
        case .again:
            return .reviewAgain
        case .hard:
            return .reviewHard
        case .good:
            return .reviewGood
        case .easy:
            return .reviewEasy
        }
    }
}
