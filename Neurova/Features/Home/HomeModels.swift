import SwiftUI

struct HomeState {
    let greetingName: String
    let greetingEmoji: String
    let subtitle: String
    let studySectionTitle: String
    let studyTitle: String
    let progress: Double
    let progressPercentText: String
    let progressDetailText: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let settingsSymbolName: String
    let quickStats: [QuickStat]
    let recommendationSectionTitle: String
    let recommendation: Recommendation
    let recentsSectionTitle: String
    let recentDecks: [RecentDeck]
    let dailyGoalSummaryTitle: String
    let dailyGoalSummaryProgress: Double
    let dailyGoalSummaryTrailingText: String
    let dailyGoalSummarySymbolName: String
    let tipTitle: String
    let tipMessage: String
}

struct QuickStat: Identifiable {
    let id = UUID()
    let value: String
    let label: String
    let systemImage: String
    let iconColor: Color
}

struct Recommendation {
    let tags: [String]
    let title: String
    let message: String
    let actionTitle: String
}

struct RecentDeck: Identifiable {
    let id = UUID()
    let title: String
    let cardCountText: String
    let accentColor: Color
}
