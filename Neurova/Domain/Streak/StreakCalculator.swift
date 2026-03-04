import Foundation

struct StreakCalculation {
    let currentStreak: Int
    let longestStreak: Int
    let isActiveToday: Bool
    let lastActiveDay: Date?
}

struct StreakCalculator {
    func calculate(
        activityDays: [Date],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> StreakCalculation {
        let normalizedToday = calendar.startOfDay(for: today)
        let normalizedDays = Array(Set(activityDays.map { calendar.startOfDay(for: $0) })).sorted()

        guard let lastActiveDay = normalizedDays.last else {
            return StreakCalculation(
                currentStreak: 0,
                longestStreak: 0,
                isActiveToday: false,
                lastActiveDay: nil
            )
        }

        let isActiveToday = calendar.isDate(lastActiveDay, inSameDayAs: normalizedToday)
        let currentStreak = currentStreakLength(
            in: normalizedDays,
            today: normalizedToday,
            isActiveToday: isActiveToday,
            calendar: calendar
        )
        let longestStreak = longestStreakLength(in: normalizedDays, calendar: calendar)

        return StreakCalculation(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            isActiveToday: isActiveToday,
            lastActiveDay: lastActiveDay
        )
    }

    private func currentStreakLength(
        in activityDays: [Date],
        today: Date,
        isActiveToday: Bool,
        calendar: Calendar
    ) -> Int {
        guard activityDays.isEmpty == false else { return 0 }

        let expectedStart = isActiveToday
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)

        guard let expectedStart else { return 0 }
        guard let startIndex = activityDays.lastIndex(where: { calendar.isDate($0, inSameDayAs: expectedStart) }) else {
            return 0
        }

        var streak = 1
        var expectedDay = expectedStart

        var index = startIndex
        while index > activityDays.startIndex {
            let previousIndex = activityDays.index(before: index)
            guard let previousExpectedDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) else {
                break
            }

            if calendar.isDate(activityDays[previousIndex], inSameDayAs: previousExpectedDay) {
                streak += 1
                expectedDay = previousExpectedDay
                index = previousIndex
            } else {
                break
            }
        }

        return streak
    }

    private func longestStreakLength(
        in activityDays: [Date],
        calendar: Calendar
    ) -> Int {
        guard activityDays.isEmpty == false else { return 0 }

        var longest = 1
        var current = 1

        for index in 1..<activityDays.count {
            let previousDay = activityDays[index - 1]
            let currentDay = activityDays[index]
            let expectedDay = calendar.date(byAdding: .day, value: 1, to: previousDay)

            if let expectedDay, calendar.isDate(currentDay, inSameDayAs: expectedDay) {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }

        return max(longest, current)
    }
}
