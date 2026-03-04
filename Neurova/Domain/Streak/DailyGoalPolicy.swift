import Foundation

struct DailyGoalProgress {
    let progressCount: Int
    let dailyGoal: Int
    let isGoalMet: Bool
}

struct DailyGoalPolicy {
    let defaultGoal: Int

    init(defaultGoal: Int = 20) {
        self.defaultGoal = max(defaultGoal, 1)
    }

    func progress(for reviewsToday: Int, dailyGoal: Int? = nil) -> DailyGoalProgress {
        let resolvedGoal = max(dailyGoal ?? defaultGoal, 1)
        let progressCount = max(reviewsToday, 0)

        return DailyGoalProgress(
            progressCount: progressCount,
            dailyGoal: resolvedGoal,
            isGoalMet: progressCount >= resolvedGoal
        )
    }
}
