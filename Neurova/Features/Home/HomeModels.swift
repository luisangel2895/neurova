import SwiftUI

struct HomeState {
    let greetingName: String
    let greetingEmoji: String
    let subtitle: String
    let studySectionTitle: String
    let studyTitle: String
    let todayCompletedCards: Int
    let todayGoalCards: Int
    let recommendedDeckText: String?
    let progress: Double
    let progressPercentText: String
    let progressDetailText: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let settingsSymbolName: String
    let quickStats: [QuickStat]
    let recommendationSectionTitle: String
    let recommendation: Recommendation
    let studyRecommendations: [StudyDeckRecommendation]
    let recentsSectionTitle: String
    let recentDecks: [RecentDeck]
    let dailyGoalSummaryTitle: String
    let dailyGoalSummaryProgress: Double
    let dailyGoalSummaryTrailingText: String
    let dailyGoalSummarySymbolName: String
    let tipTitle: String
    let tipMessage: String
    let highlightedDeck: Deck?
    let isEmptyState: Bool

    static let placeholder = HomeState(
        greetingName: "",
        greetingEmoji: "👋",
        subtitle: "",
        studySectionTitle: "STUDY",
        studyTitle: "Daily goal",
        todayCompletedCards: 0,
        todayGoalCards: 0,
        recommendedDeckText: nil,
        progress: 0,
        progressPercentText: "0%",
        progressDetailText: "",
        primaryActionTitle: "Study now",
        secondaryActionTitle: "Choose deck",
        settingsSymbolName: "gearshape",
        quickStats: [],
        recommendationSectionTitle: "RECOMMENDED",
        recommendation: Recommendation(
            tags: [],
            title: "",
            message: "",
            actionTitle: ""
        ),
        studyRecommendations: [],
        recentsSectionTitle: "RECENT",
        recentDecks: [],
        dailyGoalSummaryTitle: "Daily goal",
        dailyGoalSummaryProgress: 0,
        dailyGoalSummaryTrailingText: "0%",
        dailyGoalSummarySymbolName: "sparkles",
        tipTitle: "",
        tipMessage: "",
        highlightedDeck: nil,
        isEmptyState: true
    )
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

struct StudyDeckRecommendation: Identifiable {
    let id: UUID
    let deck: Deck
    let subjectPathText: String
    let readyCount: Int
    let totalCards: Int
    let accentColor: Color
}

struct RecentDeck: Identifiable {
    let id: UUID
    let deck: Deck
    let subjectPathText: String
    let subjectIconName: String
    let title: String
    let totalCards: Int
    let readyCount: Int
    let cardCountText: String
    let readyCountText: String
    let accentColor: Color

    var completionProgress: Double {
        guard totalCards > 0 else { return 0 }
        let remaining = max(0, totalCards - readyCount)
        return min(max(Double(remaining) / Double(totalCards), 0), 1)
    }

    var completionPercentText: String {
        "\(Int((completionProgress * 100).rounded()))%"
    }
}
