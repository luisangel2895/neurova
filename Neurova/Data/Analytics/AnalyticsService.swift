import Foundation
import SwiftData

struct DeckHealthInsight: Identifiable {
    let id: UUID
    let deckTitle: String
    let score: Int
    let label: String
    let analytics: ReviewAnalytics
}

struct AnalyticsSnapshot {
    let analytics: ReviewAnalytics
    let deckHealth: [DeckHealthInsight]
}

struct AnalyticsService {
    private let analyticsRepository: any AnalyticsRepository
    private let deckRepository: any DeckRepository
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.analyticsRepository = SwiftDataAnalyticsRepository(context: context)
        self.deckRepository = SwiftDataDeckRepository(context: context)
        self.calendar = calendar
    }

    init(
        analyticsRepository: any AnalyticsRepository,
        deckRepository: any DeckRepository,
        calendar: Calendar = .current
    ) {
        self.analyticsRepository = analyticsRepository
        self.deckRepository = deckRepository
        self.calendar = calendar
    }

    func snapshot(lastDays: Int = 7, endingOn date: Date = .now) throws -> AnalyticsSnapshot {
        let range = try dateRange(lastDays: lastDays, endingOn: date)
        let globalCounts = try analyticsRepository.eventCountsByType(in: range)
        let perDeckCounts = try analyticsRepository.eventCountsByDeck(in: range)
        let decks = try deckRepository.listDecks(includeArchived: false)
        let deckTitles = Dictionary(uniqueKeysWithValues: decks.map { ($0.id, $0.title) })

        let deckHealth = perDeckCounts.compactMap { deckId, counts -> DeckHealthInsight? in
            guard let title = deckTitles[deckId] else { return nil }
            let analytics = ReviewAnalytics(counts: counts)
            let score = DeckHealthScore(analytics: analytics)

            return DeckHealthInsight(
                id: deckId,
                deckTitle: title,
                score: score.score,
                label: score.label,
                analytics: analytics
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.deckTitle < rhs.deckTitle
            }
            return lhs.score < rhs.score
        }

        return AnalyticsSnapshot(
            analytics: ReviewAnalytics(counts: globalCounts),
            deckHealth: Array(deckHealth.prefix(3))
        )
    }

    private func dateRange(lastDays: Int, endingOn date: Date) throws -> Range<Date> {
        let safeDays = max(lastDays, 1)
        let end = date
        guard let start = calendar.date(byAdding: .day, value: -(safeDays - 1), to: end) else {
            throw NSError(domain: "AnalyticsService", code: 1)
        }
        return start..<end.addingTimeInterval(1)
    }
}
