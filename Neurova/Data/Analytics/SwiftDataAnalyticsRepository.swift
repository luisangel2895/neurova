import Foundation
import SwiftData

struct SwiftDataAnalyticsRepository: AnalyticsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func eventCountsByType(in range: Range<Date>) throws -> [XPEventType: Int] {
        let events = try fetchEvents(in: range)
        return countsByType(from: events)
    }

    func eventCountsByDeck(in range: Range<Date>) throws -> [UUID: [XPEventType: Int]] {
        let events = try fetchEvents(in: range)
        var grouped: [UUID: [XPEventType: Int]] = [:]

        for event in events {
            guard let deckId = event.deckId,
                  let eventType = XPEventType(rawValue: event.eventTypeRaw) else { continue }
            grouped[deckId, default: [:]][eventType, default: 0] += 1
        }

        return grouped
    }

    private func fetchEvents(in range: Range<Date>) throws -> [XPEventEntity] {
        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        let descriptor = FetchDescriptor<XPEventEntity>(
            predicate: #Predicate<XPEventEntity> { event in
                event.date >= lowerBound && event.date < upperBound
            }
        )

        return try context.fetch(descriptor)
    }

    private func countsByType(from events: [XPEventEntity]) -> [XPEventType: Int] {
        var counts: [XPEventType: Int] = [:]

        for event in events {
            guard let eventType = XPEventType(rawValue: event.eventTypeRaw) else { continue }
            counts[eventType, default: 0] += 1
        }

        return counts
    }
}
