import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class InsightsViewModel {
    struct Snapshot {
        let currentLevel: Int
        let totalXP: Int
        let xpToNextLevel: Int
        let levelProgress: Double
        let todayProgress: Int
        let dailyGoal: Int
        let isGoalMet: Bool
        let currentStreak: Int
        let longestStreak: Int
        let totalDueCards: Int
        let totalNewCards: Int
        let hardRate: Double
        let goodRate: Double
        let easyRate: Double
        let skipRate: Double
        let topDeckHealth: [DeckHealthInsight]
        let activityBars: [ActivityBar]
        let isEmptyState: Bool
    }

    struct ActivityBar: Identifiable {
        let id: String
        let label: String
        let count: Int
        let normalizedHeight: Double
        let isToday: Bool
    }

    private(set) var isLoading = false
    var errorMessage: String?

    private(set) var currentLevel = 1
    private(set) var totalXP = 0
    private(set) var xpToNextLevel = 0
    private(set) var levelProgress: Double = 0

    private(set) var todayProgress = 0
    private(set) var dailyGoal = 20
    private(set) var isGoalMet = false

    private(set) var currentStreak = 0
    private(set) var longestStreak = 0

    private(set) var totalDueCards = 0
    private(set) var totalNewCards = 0

    private(set) var hardRate: Double = 0
    private(set) var goodRate: Double = 0
    private(set) var easyRate: Double = 0
    private(set) var skipRate: Double = 0
    private(set) var topDeckHealth: [DeckHealthInsight] = []

    private(set) var activityBars: [ActivityBar] = []
    private(set) var isEmptyState = false

    private let cacheTTL: TimeInterval = 1.5
    private var cachedSnapshot: Snapshot?
    private var lastLoadTime: Date?
    private var lastContextIdentifier: ObjectIdentifier?

    func load(using context: ModelContext, forceRefresh: Bool = false) {
        let contextIdentifier = ObjectIdentifier(context)
        if forceRefresh == false,
           let cachedSnapshot,
           let lastLoadTime,
           lastContextIdentifier == contextIdentifier,
           Date().timeIntervalSince(lastLoadTime) <= cacheTTL {
            apply(snapshot: cachedSnapshot)
            return
        }

        guard isLoading == false else { return }
        isLoading = true
        errorMessage = nil

        do {
            let gamification = try GamificationService(context: context).snapshot()
            let streak = try StreakService(context: context).snapshot()
            let analytics = try AnalyticsService(context: context).snapshot(lastDays: 7)
            let cardRepository = SwiftDataCardRepository(context: context)
            let xpRepository = SwiftDataXPEventRepository(context: context)
            let totalEventCount = try xpRepository.totalEventCount()

            let snapshot = Snapshot(
                currentLevel: gamification.currentLevel,
                totalXP: gamification.totalXP,
                xpToNextLevel: gamification.xpToNextLevel,
                levelProgress: gamification.progressToNextLevel,
                todayProgress: streak.todayProgress,
                dailyGoal: streak.dailyGoal,
                isGoalMet: streak.isGoalMet,
                currentStreak: streak.currentStreak,
                longestStreak: streak.longestStreak,
                totalDueCards: try cardRepository.dueCardCount(asOf: .now),
                totalNewCards: try cardRepository.newCardCount(),
                hardRate: analytics.analytics.hardRate,
                goodRate: analytics.analytics.goodRate,
                easyRate: analytics.analytics.easyRate,
                skipRate: analytics.analytics.skipRate,
                topDeckHealth: analytics.deckHealth,
                activityBars: try buildActivityBars(using: xpRepository),
                isEmptyState: gamification.totalXP == 0 && totalEventCount == 0
            )

            apply(snapshot: snapshot)
            cachedSnapshot = snapshot
            lastLoadTime = Date()
            lastContextIdentifier = contextIdentifier
        } catch {
            errorMessage = "Unable to load insights."
        }

        isLoading = false
    }

    private func buildActivityBars(using repository: any XPEventRepository) throws -> [ActivityBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }

        let events = try repository.events(in: start..<end)
        let countsByDay = Dictionary(grouping: events) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.count }

        let values: [(Date, Int)] = (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return (day, countsByDay[day] ?? 0)
        }

        let maxCount = max(values.map(\.1).max() ?? 0, 1)

        return values.map { day, count in
            ActivityBar(
                id: day.formatted(date: .numeric, time: .omitted),
                label: shortWeekday(for: day, calendar: calendar),
                count: count,
                normalizedHeight: count == 0 ? 0.12 : max(Double(count) / Double(maxCount), 0.18),
                isToday: calendar.isDate(day, inSameDayAs: today)
            )
        }
    }

    private func shortWeekday(for date: Date, calendar: Calendar) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.shortWeekdaySymbols
        guard symbols.indices.contains(index) else { return "" }
        return String(symbols[index].prefix(1))
    }

    private func apply(snapshot: Snapshot) {
        currentLevel = snapshot.currentLevel
        totalXP = snapshot.totalXP
        xpToNextLevel = snapshot.xpToNextLevel
        levelProgress = snapshot.levelProgress
        todayProgress = snapshot.todayProgress
        dailyGoal = snapshot.dailyGoal
        isGoalMet = snapshot.isGoalMet
        currentStreak = snapshot.currentStreak
        longestStreak = snapshot.longestStreak
        totalDueCards = snapshot.totalDueCards
        totalNewCards = snapshot.totalNewCards
        hardRate = snapshot.hardRate
        goodRate = snapshot.goodRate
        easyRate = snapshot.easyRate
        skipRate = snapshot.skipRate
        topDeckHealth = snapshot.topDeckHealth
        activityBars = snapshot.activityBars
        isEmptyState = snapshot.isEmptyState
    }
}
