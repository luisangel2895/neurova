import Foundation
import Testing
@testable import Neurova

struct AnalyticsServiceTests {
    @Test
    func snapshotAggregatesGlobalAnalyticsAndDeckHealth() throws {
        let analyticsRepo = MockAnalyticsRepository()
        analyticsRepo.eventCountsByTypeResult = [
            .reviewEasy: 20,
            .reviewGood: 10,
            .reviewHard: 5,
            .reviewAgain: 2
        ]

        let deckId = UUID()
        analyticsRepo.eventCountsByDeckResult = [
            deckId: [.reviewEasy: 20]
        ]

        let deckRepo = MockDeckRepository()
        let deck = Deck(title: "Biology")
        deckRepo.storedDecks = [deck]

        // Patch deckId to match
        analyticsRepo.eventCountsByDeckResult = [
            deck.id: [.reviewEasy: 20]
        ]

        let service = AnalyticsService(
            analyticsRepository: analyticsRepo,
            deckRepository: deckRepo
        )

        let snapshot = try service.snapshot(lastDays: 7)

        #expect(snapshot.analytics.totalReviews == 37)
        #expect(snapshot.deckHealth.count == 1)
        #expect(snapshot.deckHealth.first?.deckTitle == "Biology")
        #expect(snapshot.deckHealth.first?.label == "Strong")
    }

    @Test
    func snapshotReturnsEmptyHealthWhenNoDecks() throws {
        let analyticsRepo = MockAnalyticsRepository()
        let deckRepo = MockDeckRepository()

        let service = AnalyticsService(
            analyticsRepository: analyticsRepo,
            deckRepository: deckRepo
        )

        let snapshot = try service.snapshot(lastDays: 7)

        #expect(snapshot.analytics.totalReviews == 0)
        #expect(snapshot.deckHealth.isEmpty)
    }

    @Test
    func snapshotThrowsWhenAnalyticsRepositoryFails() {
        let analyticsRepo = MockAnalyticsRepository()
        analyticsRepo.shouldThrow = true
        let deckRepo = MockDeckRepository()

        let service = AnalyticsService(
            analyticsRepository: analyticsRepo,
            deckRepository: deckRepo
        )

        #expect(throws: MockError.self) {
            try service.snapshot(lastDays: 7)
        }
    }

    @Test
    func snapshotLimitsToThreeWorstDecks() throws {
        let analyticsRepo = MockAnalyticsRepository()
        let deckRepo = MockDeckRepository()

        var deckCounts: [UUID: [XPEventType: Int]] = [:]
        for i in 0..<5 {
            let deck = Deck(title: "Deck \(i)")
            deckRepo.storedDecks.append(deck)
            deckCounts[deck.id] = [.reviewAgain: (i + 1) * 3]
        }
        analyticsRepo.eventCountsByDeckResult = deckCounts

        let service = AnalyticsService(
            analyticsRepository: analyticsRepo,
            deckRepository: deckRepo
        )

        let snapshot = try service.snapshot(lastDays: 7)

        #expect(snapshot.deckHealth.count == 3)
    }
}
