import Foundation
import Testing
@testable import Neurova

struct StreakCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func emptyActivityProducesZeroedStreak() {
        let result = StreakCalculator().calculate(
            activityDays: [],
            today: makeDate(year: 2026, month: 3, day: 13),
            calendar: calendar
        )

        #expect(result.currentStreak == 0)
        #expect(result.longestStreak == 0)
        #expect(result.isActiveToday == false)
        #expect(result.lastActiveDay == nil)
    }

    @Test
    func currentStreakDeduplicatesSameDayActivity() {
        let today = makeDate(year: 2026, month: 3, day: 13)
        let result = StreakCalculator().calculate(
            activityDays: [
                makeDate(year: 2026, month: 3, day: 11),
                makeDate(year: 2026, month: 3, day: 12),
                makeDate(year: 2026, month: 3, day: 13),
                makeDate(year: 2026, month: 3, day: 13)
            ],
            today: today,
            calendar: calendar
        )

        #expect(result.currentStreak == 3)
        #expect(result.longestStreak == 3)
        #expect(result.isActiveToday)
        #expect(calendar.isDate(result.lastActiveDay!, inSameDayAs: today))
    }

    @Test
    func missingYesterdayResetsCurrentButKeepsLongest() {
        let result = StreakCalculator().calculate(
            activityDays: [
                makeDate(year: 2026, month: 3, day: 8),
                makeDate(year: 2026, month: 3, day: 9),
                makeDate(year: 2026, month: 3, day: 10),
                makeDate(year: 2026, month: 3, day: 13)
            ],
            today: makeDate(year: 2026, month: 3, day: 13),
            calendar: calendar
        )

        #expect(result.currentStreak == 1)
        #expect(result.longestStreak == 3)
        #expect(result.isActiveToday)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
