import Foundation
import OSLog
import SwiftData

struct SwiftDataXPEventRepository: XPEventRepository {
    private let context: ModelContext
#if DEBUG
    private static let logger = Logger(subsystem: "com.neurova.app", category: "XPEventIntegrity")
#endif

    init(context: ModelContext) {
        self.context = context
    }

    func record(_ event: XPEvent) throws {
        try record(event, integrityContext: nil)
    }

    func record(_ event: XPEvent, integrityContext: XPEventIntegrityContext?) throws {
#if DEBUG
        logIntegrityWarningIfNeeded(for: event, context: integrityContext)
#endif

        let entity = XPEventEntity(
            id: event.id,
            date: event.date,
            deckId: event.deckId,
            cardId: event.cardId,
            eventTypeRaw: event.eventType.rawValue,
            xpDelta: event.xpDelta
        )

        context.insert(entity)

        let stats = try fetchOrCreateStatsEntity()
        stats.totalXP += event.xpDelta

        try context.save()
    }

    func events(in range: Range<Date>) throws -> [XPEvent] {
        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        let descriptor = FetchDescriptor<XPEventEntity>(
            predicate: #Predicate<XPEventEntity> { event in
                event.date >= lowerBound && event.date < upperBound
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try context.fetch(descriptor).compactMap(mapToDomain)
    }

    func totalXP() throws -> Int {
        try fetchOrCreateStatsEntity().totalXP
    }

    func totalEventCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<XPEventEntity>())
    }

    func todayXP(on date: Date = .now, calendar: Calendar = .current) throws -> Int {
        try todayEvents(on: date, calendar: calendar).reduce(0) { $0 + $1.xpDelta }
    }

    func activityDays(
        inLast numberOfDays: Int,
        endingOn date: Date = .now,
        calendar: Calendar = .current
    ) throws -> [Date] {
        let safeDays = max(numberOfDays, 1)
        let endDay = calendar.startOfDay(for: date)
        guard let rangeEnd = calendar.date(byAdding: .day, value: 1, to: endDay),
              let rangeStart = calendar.date(byAdding: .day, value: -(safeDays - 1), to: endDay) else {
            return []
        }

        let events = try fetchEntities(in: rangeStart..<rangeEnd)
        let distinctDays = Set(events.map { calendar.startOfDay(for: $0.date) })
        return distinctDays.sorted()
    }

    func todayReviewCount(on date: Date = .now, calendar: Calendar = .current) throws -> Int {
        let reviewTypes: Set<String> = [
            XPEventType.reviewAgain.rawValue,
            XPEventType.reviewHard.rawValue,
            XPEventType.reviewGood.rawValue,
            XPEventType.reviewEasy.rawValue
        ]
        return try todayEvents(on: date, calendar: calendar)
            .filter { reviewTypes.contains($0.eventTypeRaw) }
            .count
    }

    private func fetchOrCreateStatsEntity() throws -> XPStatsEntity {
        let descriptor = FetchDescriptor<XPStatsEntity>(
            predicate: #Predicate<XPStatsEntity> { stats in
                stats.key == "global"
            }
        )

        let results = try context.fetch(descriptor)

        // Deduplicate if CloudKit sync created multiple "global" records
        if results.count > 1 {
            let primary = results[0]
            for duplicate in results.dropFirst() {
                context.delete(duplicate)
            }
            return primary
        }

        if let existing = results.first {
            return existing
        }

        let stats = XPStatsEntity()
        context.insert(stats)
        return stats
    }

    private func todayEvents(on date: Date, calendar: Calendar) throws -> [XPEventEntity] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return try fetchEntities(in: startOfDay..<endOfDay)
    }

    private func fetchEntities(in range: Range<Date>) throws -> [XPEventEntity] {
        let lowerBound = range.lowerBound
        let upperBound = range.upperBound
        let descriptor = FetchDescriptor<XPEventEntity>(
            predicate: #Predicate<XPEventEntity> { event in
                event.date >= lowerBound && event.date < upperBound
            }
        )

        return try context.fetch(descriptor)
    }

    private func mapToDomain(_ entity: XPEventEntity) -> XPEvent? {
        guard let eventType = XPEventType(rawValue: entity.eventTypeRaw) else {
            return nil
        }

        return XPEvent(
            id: entity.id,
            date: entity.date,
            deckId: entity.deckId,
            cardId: entity.cardId,
            eventType: eventType,
            xpDelta: entity.xpDelta
        )
    }

#if DEBUG
    private func logIntegrityWarningIfNeeded(for event: XPEvent, context: XPEventIntegrityContext?) {
        guard let context else { return }

        if event.deckId == nil && context.expectedDeckId {
            Self.logger.warning(
                "[XPEvent Integrity] Missing deckId for event=\(event.eventType.rawValue, privacy: .public) cardId=\(context.cardIdDescription, privacy: .public) deckTitle=\(context.deckTitle ?? "?", privacy: .public) date=\(event.date.formatted(date: .abbreviated, time: .standard), privacy: .public) source=\(context.source, privacy: .public)"
            )
        }

        if event.cardId == nil && context.expectedCardId {
            Self.logger.warning(
                "[XPEvent Integrity] Missing cardId for event=\(event.eventType.rawValue, privacy: .public) cardId=\(context.cardIdDescription, privacy: .public) deckTitle=\(context.deckTitle ?? "?", privacy: .public) date=\(event.date.formatted(date: .abbreviated, time: .standard), privacy: .public) source=\(context.source, privacy: .public)"
            )
        }
    }
#endif
}
