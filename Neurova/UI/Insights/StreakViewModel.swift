import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class StreakViewModel {
    private(set) var currentStreak = 0
    private(set) var longestStreak = 0
    private(set) var todayProgress = 0
    private(set) var dailyGoal = 20
    private(set) var isGoalMet = false
    private(set) var isActiveToday = false
    private(set) var lastActiveDay: Date?
    private(set) var isLoading = false
    var errorMessage: String?

    func load(using context: ModelContext) {
        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try StreakService(context: context).snapshot()
            currentStreak = snapshot.currentStreak
            longestStreak = snapshot.longestStreak
            todayProgress = snapshot.todayProgress
            dailyGoal = snapshot.dailyGoal
            isGoalMet = snapshot.isGoalMet
            isActiveToday = snapshot.isActiveToday
            lastActiveDay = snapshot.lastActiveDay
        } catch {
            errorMessage = "Unable to load streak data."
        }

        isLoading = false
    }
}
