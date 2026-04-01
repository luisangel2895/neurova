import Foundation
import SwiftData
import Testing
@testable import Neurova

@MainActor
struct ReviewServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(in context: ModelContext) -> Card {
        let subject = Subject(name: "Test")
        context.insert(subject)
        let deck = Deck(subject: subject, title: "Test Deck")
        context.insert(deck)
        let card = Card(frontText: "Q", backText: "A", deck: deck)
        context.insert(card)
        try? context.save()
        return card
    }

    @Test
    func newCardAnsweredGoodGraduatesToReview() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        let result = try service.review(card: card, quality: .good, in: context)

        #expect(card.learningState == .review)
        #expect(result.interval == 1)
        #expect(result.repetition >= 1)
    }

    @Test
    func newCardAnsweredEasyGraduatesWithLongerInterval() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        let result = try service.review(card: card, quality: .easy, in: context)

        #expect(card.learningState == .review)
        #expect(result.interval == 3)
        #expect(result.repetition >= 2)
    }

    @Test
    func newCardAnsweredAgainEntersLearning() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        _ = try service.review(card: card, quality: .again, in: context)

        #expect(card.learningState == .learning)
        #expect(card.lapses == 1)
        #expect(card.learningStepIndex == 0)
    }

    @Test
    func reviewCardAnsweredAgainEntersRelearning() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        // Graduate to review state first
        _ = try service.review(card: card, quality: .good, in: context)
        #expect(card.learningState == .review)

        let previousLapses = card.lapses

        // Answer again to trigger relearning
        _ = try service.review(card: card, quality: .again, in: context)

        #expect(card.learningState == .relearning)
        #expect(card.lapses == previousLapses + 1)
    }

    @Test
    func reviewIncrementsTotalReviewsCounter() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        #expect(card.resolvedTotalReviews == 0)

        _ = try service.review(card: card, quality: .good, in: context)
        #expect(card.resolvedTotalReviews == 1)

        _ = try service.review(card: card, quality: .good, in: context)
        #expect(card.resolvedTotalReviews == 2)
    }

    @Test
    func reviewRecordsXPEvent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let card = makeCard(in: context)
        let service = ReviewService()

        _ = try service.review(card: card, quality: .good, in: context)

        let descriptor = FetchDescriptor<XPEventEntity>()
        let events = try context.fetch(descriptor)

        #expect(events.count == 1)
        #expect(events.first?.eventTypeRaw == XPEventType.reviewGood.rawValue)
    }

    @Test
    func easyReviewGrantsMoreXPThanAgain() throws {
        let container = try makeContainer()
        let easyContext = ModelContext(container)
        let easyCard = makeCard(in: easyContext)
        let service = ReviewService()

        _ = try service.review(card: easyCard, quality: .easy, in: easyContext)

        let againContext = ModelContext(container)
        let againCard = makeCard(in: againContext)
        _ = try service.review(card: againCard, quality: .again, in: againContext)

        let easyEvents = try easyContext.fetch(FetchDescriptor<XPEventEntity>())
        let againEvents = try againContext.fetch(FetchDescriptor<XPEventEntity>())

        let easyXP = easyEvents.first?.xpDelta ?? 0
        let againXP = againEvents.first?.xpDelta ?? 0

        #expect(easyXP > againXP)
    }
}
