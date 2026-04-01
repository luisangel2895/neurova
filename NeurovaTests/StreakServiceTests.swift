import Foundation
import Testing
@testable import Neurova

struct StreakServiceTests {
    private let calendar = Calendar.current

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test
    func snapshotComputesStreakAndGoalProgress() throws {
        let today = makeDate(year: 2026, month: 3, day: 15)
        let repo = MockXPEventRepository()
        repo.storedActivityDays = [
            makeDate(year: 2026, month: 3, day: 13),
            makeDate(year: 2026, month: 3, day: 14),
            makeDate(year: 2026, month: 3, day: 15)
        ]
        repo.storedTodayReviewCount = 8

        let service = StreakService(
            repository: repo,
            dailyGoal: 10,
            dateProvider: MockDateProvider(now: today, calendar: calendar)
        )

        let snapshot = try service.snapshot()

        #expect(snapshot.currentStreak == 3)
        #expect(snapshot.isActiveToday == true)
        #expect(snapshot.todayProgress == 8)
        #expect(snapshot.dailyGoal == 10)
        #expect(snapshot.isGoalMet == false)
    }

    @Test
    func snapshotWithNoActivityReturnsZeroStreak() throws {
        let today = makeDate(year: 2026, month: 3, day: 15)
        let repo = MockXPEventRepository()
        repo.storedActivityDays = []
        repo.storedTodayReviewCount = 0

        let service = StreakService(
            repository: repo,
            dailyGoal: 5,
            dateProvider: MockDateProvider(now: today, calendar: calendar)
        )

        let snapshot = try service.snapshot()

        #expect(snapshot.currentStreak == 0)
        #expect(snapshot.isActiveToday == false)
        #expect(snapshot.isGoalMet == false)
    }

    @Test
    func snapshotReportsGoalMetWhenProgressMeetsTarget() throws {
        let today = makeDate(year: 2026, month: 3, day: 15)
        let repo = MockXPEventRepository()
        repo.storedActivityDays = [today]
        repo.storedTodayReviewCount = 10

        let service = StreakService(
            repository: repo,
            dailyGoal: 10,
            dateProvider: MockDateProvider(now: today, calendar: calendar)
        )

        let snapshot = try service.snapshot()

        #expect(snapshot.isGoalMet == true)
        #expect(snapshot.todayProgress == 10)
    }

    @Test
    func snapshotThrowsWhenRepositoryFails() {
        let repo = MockXPEventRepository()
        repo.shouldThrow = true

        let service = StreakService(
            repository: repo,
            dailyGoal: 5,
            dateProvider: MockDateProvider()
        )

        #expect(throws: MockError.self) {
            try service.snapshot()
        }
    }
}
