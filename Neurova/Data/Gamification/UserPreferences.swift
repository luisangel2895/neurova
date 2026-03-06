import Foundation
import SwiftData

@Model
final class UserPreferences {
    var key: String = "global"
    var dailyGoalCards: Int = 20
    var hasCompletedOnboarding: Bool = false
    var preferredThemeRaw: String?
    var preferredLanguageRaw: String?
    var newCardsPerDay: Int?
    var maxReviewsPerDay: Int?
    var sessionTimeCapSeconds: Int?
    var avoidNewWhenDueBacklogHigh: Bool?
    var dueBacklogThreshold: Int?

    init(
        key: String = "global",
        dailyGoalCards: Int = 20,
        hasCompletedOnboarding: Bool = false,
        preferredThemeRaw: String? = nil,
        preferredLanguageRaw: String? = nil,
        newCardsPerDay: Int? = nil,
        maxReviewsPerDay: Int? = nil,
        sessionTimeCapSeconds: Int? = nil,
        avoidNewWhenDueBacklogHigh: Bool? = nil,
        dueBacklogThreshold: Int? = nil
    ) {
        self.key = key
        self.dailyGoalCards = dailyGoalCards
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.preferredThemeRaw = preferredThemeRaw
        self.preferredLanguageRaw = preferredLanguageRaw
        self.newCardsPerDay = newCardsPerDay
        self.maxReviewsPerDay = maxReviewsPerDay
        self.sessionTimeCapSeconds = sessionTimeCapSeconds
        self.avoidNewWhenDueBacklogHigh = avoidNewWhenDueBacklogHigh
        self.dueBacklogThreshold = dueBacklogThreshold
    }

    var resolvedNewCardsPerDay: Int {
        newCardsPerDay ?? 20
    }

    var resolvedMaxReviewsPerDay: Int {
        maxReviewsPerDay ?? 200
    }

    var resolvedSessionTimeCapSeconds: Int? {
        sessionTimeCapSeconds
    }

    var resolvedAvoidNewWhenDueBacklogHigh: Bool {
        avoidNewWhenDueBacklogHigh ?? false
    }

    var resolvedDueBacklogThreshold: Int {
        dueBacklogThreshold ?? 50
    }
}
