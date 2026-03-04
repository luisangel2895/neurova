#if DEBUG
import Foundation

struct DayBoundaryValidationResult {
    let beforeMidnightTodayXP: Int
    let afterMidnightTodayXP: Int
    let streakAfterSecondDay: Int
    let isActiveAfterSecondDay: Bool
}

enum DayBoundaryDebugValidator {
    static func validate(timeZone: TimeZone = .current) throws -> DayBoundaryValidationResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let repository = InMemoryXPEventRepository()

        let dayOne2359 = makeDate(
            year: 2026, month: 3, day: 4,
            hour: 23, minute: 59,
            calendar: calendar
        )
        let dayTwo0001 = makeDate(
            year: 2026, month: 3, day: 5,
            hour: 0, minute: 1,
            calendar: calendar
        )

        try repository.record(
            XPEvent(
                id: UUID(),
                date: dayOne2359,
                deckId: UUID(),
                cardId: nil,
                eventType: .reviewGood,
                xpDelta: 10
            )
        )

        let beforeProvider = FixedDateProvider(now: dayOne2359, calendar: calendar)
        let beforeSnapshot = try GamificationService(
            repository: repository,
            dateProvider: beforeProvider
        ).snapshot()

        let afterFirstMidnightProvider = FixedDateProvider(now: dayTwo0001, calendar: calendar)
        let afterFirstMidnightSnapshot = try GamificationService(
            repository: repository,
            dateProvider: afterFirstMidnightProvider
        ).snapshot()

        try repository.record(
            XPEvent(
                id: UUID(),
                date: dayTwo0001,
                deckId: UUID(),
                cardId: nil,
                eventType: .reviewHard,
                xpDelta: 5
            )
        )

        let streakSnapshot = try StreakService(
            repository: repository,
            dailyGoal: 20,
            dateProvider: afterFirstMidnightProvider
        ).snapshot()

        return DayBoundaryValidationResult(
            beforeMidnightTodayXP: beforeSnapshot.todayXP,
            afterMidnightTodayXP: afterFirstMidnightSnapshot.todayXP,
            streakAfterSecondDay: streakSnapshot.currentStreak,
            isActiveAfterSecondDay: streakSnapshot.isActiveToday
        )
    }

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        return components.date ?? .distantPast
    }
}

private final class InMemoryXPEventRepository: XPEventRepository {
    private var eventsStorage: [XPEvent] = []

    func record(_ event: XPEvent) throws {
        eventsStorage.append(event)
    }

    func events(in range: Range<Date>) throws -> [XPEvent] {
        eventsStorage.filter { range.contains($0.date) }
    }

    func totalXP() throws -> Int {
        eventsStorage.reduce(0) { $0 + $1.xpDelta }
    }

    func totalEventCount() throws -> Int {
        eventsStorage.count
    }

    func todayXP(on date: Date, calendar: Calendar) throws -> Int {
        try todayEvents(on: date, calendar: calendar).reduce(0) { $0 + $1.xpDelta }
    }

    func activityDays(inLast numberOfDays: Int, endingOn date: Date, calendar: Calendar) throws -> [Date] {
        let safeDays = max(numberOfDays, 1)
        let endDay = calendar.startOfDay(for: date)
        guard let rangeEnd = calendar.date(byAdding: .day, value: 1, to: endDay),
              let rangeStart = calendar.date(byAdding: .day, value: -(safeDays - 1), to: endDay) else {
            return []
        }

        let events = try self.events(in: rangeStart..<rangeEnd)
        return Array(Set(events.map { calendar.startOfDay(for: $0.date) })).sorted()
    }

    func todayReviewCount(on date: Date, calendar: Calendar) throws -> Int {
        try todayEvents(on: date, calendar: calendar).count
    }

    private func todayEvents(on date: Date, calendar: Calendar) throws -> [XPEvent] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return try events(in: startOfDay..<endOfDay)
    }
}
#endif
