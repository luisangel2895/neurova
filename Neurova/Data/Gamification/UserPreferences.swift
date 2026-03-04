import Foundation
import SwiftData

@Model
final class UserPreferences {
    var key: String
    var dailyGoalCards: Int

    init(key: String = "global", dailyGoalCards: Int = 20) {
        self.key = key
        self.dailyGoalCards = dailyGoalCards
    }
}
