import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSpacing.lg) {
                header

                levelHero

                dailyGoalCard

                InsightsSectionHeader("Performance")
                InsightsStatGrid(items: performanceItems)

                streakCard

                difficultyCard

                deckHealthCard

                activityCard
            }
            .padding(.horizontal, NSpacing.md)
            .padding(.vertical, NSpacing.md)
        }
        .background(backgroundView.ignoresSafeArea())
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.load(using: modelContext)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text("This week")
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            if viewModel.isEmptyState {
                Text("No activity yet")
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text("Start a session to see your progress here.")
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Feedback.danger)
            }
        }
    }

    private var levelHero: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Level \(viewModel.currentLevel)", subtitle: "Total progress")

                Text("\(viewModel.totalXP) XP")
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                NProgressBar(progress: viewModel.levelProgress, height: 8)
                    .frame(height: 8)

                Text("\(viewModel.xpToNextLevel) XP to next level")
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
        }
    }

    private var dailyGoalCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Daily Goal", subtitle: viewModel.isGoalMet ? "Goal met today" : "Keep going")

                Text("\(viewModel.todayProgress)/\(viewModel.dailyGoal) cards")
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                NProgressBar(
                    progress: viewModel.dailyGoal == 0 ? 0 : Double(viewModel.todayProgress) / Double(viewModel.dailyGoal),
                    height: 8
                )
                .frame(height: 8)
            }
        }
    }

    private var streakCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Streak", subtitle: "Daily consistency")

                HStack(spacing: NSpacing.md) {
                    streakMetric(value: "\(viewModel.currentStreak)", label: "Current")
                    streakMetric(value: "\(viewModel.longestStreak)", label: "Longest")
                }
            }
        }
    }

    private func streakMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(value)
                .font(NTypography.title.weight(.bold))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activityCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Last 7 Days", subtitle: "Review activity")

                HStack(alignment: .bottom, spacing: NSpacing.sm) {
                    ForEach(viewModel.activityBars) { bar in
                        VStack(spacing: NSpacing.xs) {
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                .fill(bar.isToday ? NColors.Brand.neuroBlue : NColors.Home.surfaceL2)
                                .frame(height: max(10, 56 * bar.normalizedHeight))

                            Text(bar.label)
                                .font(NTypography.caption)
                                .foregroundStyle(NColors.Text.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var difficultyCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Difficulty", subtitle: "Last 7 days")

                InsightsStatGrid(
                    items: [
                        .init(
                            systemImage: "tortoise",
                            iconColor: NColors.Feedback.warning,
                            value: percentageText(viewModel.hardRate),
                            label: "Hard"
                        ),
                        .init(
                            systemImage: "checkmark.circle",
                            iconColor: NColors.Brand.neuroBlue,
                            value: percentageText(viewModel.goodRate),
                            label: "Good"
                        ),
                        .init(
                            systemImage: "star",
                            iconColor: NColors.Feedback.success,
                            value: percentageText(viewModel.easyRate),
                            label: "Easy"
                        ),
                        .init(
                            systemImage: "forward",
                            iconColor: NColors.Text.textSecondary,
                            value: percentageText(viewModel.skipRate),
                            label: "Skip"
                        )
                    ]
                )
            }
        }
    }

    private var deckHealthCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader("Deck health", subtitle: "Top decks needing attention")

                if viewModel.topDeckHealth.isEmpty {
                    Text("No recent review data yet.")
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textSecondary)
                } else {
                    VStack(spacing: NSpacing.sm) {
                        ForEach(viewModel.topDeckHealth) { deck in
                            HStack(spacing: NSpacing.sm) {
                                VStack(alignment: .leading, spacing: NSpacing.xs) {
                                    Text(deck.deckTitle)
                                        .font(NTypography.bodyEmphasis.weight(.semibold))
                                        .foregroundStyle(NColors.Text.textPrimary)

                                    Text(deck.label)
                                        .font(NTypography.caption)
                                        .foregroundStyle(NColors.Text.textSecondary)
                                }

                                Spacer()

                                Text("\(deck.score)")
                                    .font(NTypography.bodyEmphasis.weight(.semibold))
                                    .foregroundStyle(healthScoreColor(for: deck.score))
                            }
                            .padding(.vertical, NSpacing.xs)
                        }
                    }
                }
            }
        }
    }

    private var performanceItems: [InsightsStatGrid.Item] {
        [
            .init(
                systemImage: "clock.arrow.circlepath",
                iconColor: NColors.Brand.neuroBlue,
                value: "\(viewModel.totalDueCards)",
                label: "Due"
            ),
            .init(
                systemImage: "sparkles.rectangle.stack",
                iconColor: NColors.Brand.neuralMint,
                value: "\(viewModel.totalNewCards)",
                label: "New"
            )
        ]
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func percentageText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func healthScoreColor(for score: Int) -> Color {
        switch score {
        case ..<45:
            return NColors.Feedback.danger
        case ..<70:
            return NColors.Feedback.warning
        default:
            return NColors.Feedback.success
        }
    }
}

#Preview("Insights Light") {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
    .preferredColorScheme(.light)
}

#Preview("Insights Dark") {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
    .preferredColorScheme(.dark)
}
