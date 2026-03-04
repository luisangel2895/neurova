import Foundation
import SwiftData

struct StreakSnapshot {
    let currentStreak: Int
    let longestStreak: Int
    let isActiveToday: Bool
    let lastActiveDay: Date?
    let todayProgress: Int
    let dailyGoal: Int
    let isGoalMet: Bool
}

struct StreakService {
    private let repository: any XPEventRepository
    private let preferences: UserPreferences
    private let streakCalculator: StreakCalculator
    private let dailyGoalPolicy: DailyGoalPolicy
    private let dateProvider: any DateProvider

    init(
        context: ModelContext,
        dateProvider: any DateProvider = SystemDateProvider(),
        streakCalculator: StreakCalculator = StreakCalculator(),
        dailyGoalPolicy: DailyGoalPolicy = DailyGoalPolicy()
    ) throws {
        self.repository = SwiftDataXPEventRepository(context: context)
        self.preferences = try StreakService.fetchOrCreatePreferences(in: context, defaultGoal: dailyGoalPolicy.defaultGoal)
        self.streakCalculator = streakCalculator
        self.dailyGoalPolicy = dailyGoalPolicy
        self.dateProvider = dateProvider
    }

    init(
        repository: any XPEventRepository,
        dailyGoal: Int,
        dateProvider: any DateProvider = SystemDateProvider(),
        streakCalculator: StreakCalculator = StreakCalculator(),
        dailyGoalPolicy: DailyGoalPolicy = DailyGoalPolicy()
    ) {
        self.repository = repository
        self.preferences = UserPreferences(dailyGoalCards: dailyGoal)
        self.streakCalculator = streakCalculator
        self.dailyGoalPolicy = dailyGoalPolicy
        self.dateProvider = dateProvider
    }

    func snapshot(lookbackDays: Int = 365) throws -> StreakSnapshot {
        let activityDays = try repository.activityDays(
            inLast: lookbackDays,
            endingOn: dateProvider.now,
            calendar: dateProvider.calendar
        )
        let streak = streakCalculator.calculate(
            activityDays: activityDays,
            today: dateProvider.now,
            calendar: dateProvider.calendar
        )
        let reviewsToday = try repository.todayReviewCount(on: dateProvider.now, calendar: dateProvider.calendar)
        let goal = dailyGoalPolicy.progress(for: reviewsToday, dailyGoal: preferences.dailyGoalCards)

        return StreakSnapshot(
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            isActiveToday: streak.isActiveToday,
            lastActiveDay: streak.lastActiveDay,
            todayProgress: goal.progressCount,
            dailyGoal: goal.dailyGoal,
            isGoalMet: goal.isGoalMet
        )
    }

    private static func fetchOrCreatePreferences(
        in context: ModelContext,
        defaultGoal: Int
    ) throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let preferences = UserPreferences(dailyGoalCards: defaultGoal)
        context.insert(preferences)
        try context.save()
        return preferences
    }
}
