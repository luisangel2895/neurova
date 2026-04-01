import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var key: String = "global"
    var dailyGoalCards: Int = 20
    var hasCompletedOnboarding: Bool = false
    var preferredThemeRaw: String?
    var preferredLanguageRaw: String?

    init(
        key: String = "global",
        dailyGoalCards: Int = 20,
        hasCompletedOnboarding: Bool = false,
        preferredThemeRaw: String? = nil,
        preferredLanguageRaw: String? = nil
    ) {
        self.key = key
        self.dailyGoalCards = dailyGoalCards
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.preferredThemeRaw = preferredThemeRaw
        self.preferredLanguageRaw = preferredLanguageRaw
    }
}
