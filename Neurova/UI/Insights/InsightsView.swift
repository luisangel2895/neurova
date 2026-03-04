import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSpacing.lg) {
                header

                levelHero

                dailyGoalCard

                InsightsSectionHeader(AppCopy.text(locale, en: "Performance", es: "Rendimiento"))
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
        .navigationTitle(AppCopy.text(locale, en: "Insights", es: "Insights"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.load(using: modelContext)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "This week", es: "Esta semana"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            if viewModel.isEmptyState {
                Text(AppCopy.text(locale, en: "No activity yet", es: "Aun no hay actividad"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(AppCopy.text(locale, en: "Start a session to see your progress here.", es: "Inicia una sesion para ver tu progreso aqui."))
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
                InsightsSectionHeader("\(AppCopy.text(locale, en: "Level", es: "Nivel")) \(viewModel.currentLevel)", subtitle: AppCopy.text(locale, en: "Total progress", es: "Progreso total"))

                Text("\(viewModel.totalXP) XP")
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                NProgressBar(progress: viewModel.levelProgress, height: 8)
                    .frame(height: 8)

                Text("\(viewModel.xpToNextLevel) \(AppCopy.text(locale, en: "XP to next level", es: "XP para el siguiente nivel"))")
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
        }
    }

    private var dailyGoalCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader(
                    AppCopy.text(locale, en: "Daily Goal", es: "Meta Diaria"),
                    subtitle: viewModel.isGoalMet
                        ? AppCopy.text(locale, en: "Goal met today", es: "Meta cumplida hoy")
                        : AppCopy.text(locale, en: "Keep going", es: "Sigue asi")
                )

                Text("\(viewModel.todayProgress)/\(viewModel.dailyGoal) \(AppCopy.text(locale, en: "cards", es: "tarjetas"))")
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
                InsightsSectionHeader(AppCopy.text(locale, en: "Streak", es: "Racha"), subtitle: AppCopy.text(locale, en: "Consecutive study days", es: "Dias consecutivos de estudio"))

                HStack(spacing: NSpacing.md) {
                    streakMetric(value: "\(viewModel.currentStreak)", label: AppCopy.text(locale, en: "Current Streak", es: "Racha Actual"))
                    streakMetric(value: "\(viewModel.longestStreak)", label: AppCopy.text(locale, en: "Best Streak", es: "Mejor Racha"))
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
                InsightsSectionHeader(AppCopy.text(locale, en: "Last 7 Days", es: "Ultimos 7 Dias"), subtitle: AppCopy.text(locale, en: "Review activity", es: "Actividad de repaso"))

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
                InsightsSectionHeader(AppCopy.text(locale, en: "Difficulty", es: "Dificultad"), subtitle: AppCopy.text(locale, en: "Last 7 days", es: "Ultimos 7 dias"))

                InsightsStatGrid(
                    items: [
                        .init(
                            systemImage: "tortoise",
                            iconColor: NColors.Feedback.warning,
                            value: percentageText(viewModel.hardRate),
                            label: AppCopy.text(locale, en: "Hard", es: "Dificil")
                        ),
                        .init(
                            systemImage: "checkmark.circle",
                            iconColor: NColors.Brand.neuroBlue,
                            value: percentageText(viewModel.goodRate),
                            label: AppCopy.text(locale, en: "Good", es: "Bien")
                        ),
                        .init(
                            systemImage: "star",
                            iconColor: NColors.Feedback.success,
                            value: percentageText(viewModel.easyRate),
                            label: AppCopy.text(locale, en: "Easy", es: "Facil")
                        ),
                        .init(
                            systemImage: "forward",
                            iconColor: NColors.Text.textSecondary,
                            value: percentageText(viewModel.skipRate),
                            label: AppCopy.text(locale, en: "Skip", es: "Saltar")
                        )
                    ]
                )
            }
        }
    }

    private var deckHealthCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                InsightsSectionHeader(AppCopy.text(locale, en: "Deck Health Score", es: "Score de Salud del Mazo"), subtitle: AppCopy.text(locale, en: "Health score for each deck", es: "Score de salud de cada mazo"))

                if viewModel.topDeckHealth.isEmpty {
                    Text(AppCopy.text(locale, en: "No recent review data yet.", es: "Aun no hay datos recientes de repaso."))
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textSecondary)
                } else {
                    VStack(spacing: NSpacing.sm) {
                        ForEach(viewModel.topDeckHealth) { deck in
                            HStack(spacing: NSpacing.sm) {
                                VStack(alignment: .leading, spacing: NSpacing.xs) {
                                    Text(AppCopy.text(locale, en: "DECK", es: "MAZO"))
                                        .font(NTypography.caption.weight(.semibold))
                                        .foregroundStyle(NColors.Text.textSecondary)

                                    Text(deck.deckTitle)
                                        .font(NTypography.bodyEmphasis.weight(.semibold))
                                        .foregroundStyle(NColors.Text.textPrimary)

                                    Text(healthLabel(for: deck.score))
                                        .font(NTypography.caption)
                                        .foregroundStyle(NColors.Text.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: NSpacing.xs) {
                                    Text(AppCopy.text(locale, en: "Score", es: "Score"))
                                        .font(NTypography.caption.weight(.semibold))
                                        .foregroundStyle(NColors.Text.textSecondary)

                                    Text("\(deck.score)")
                                        .font(NTypography.bodyEmphasis.weight(.semibold))
                                        .foregroundStyle(healthScoreColor(for: deck.score))
                                        .padding(.horizontal, NSpacing.sm)
                                        .padding(.vertical, NSpacing.xs)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(healthScoreColor(for: deck.score).opacity(0.14))
                                        )
                                }
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
                label: AppCopy.text(locale, en: "Ready", es: "Listo")
            ),
            .init(
                systemImage: "sparkles.rectangle.stack",
                iconColor: NColors.Brand.neuralMint,
                value: "\(viewModel.totalNewCards)",
                label: AppCopy.text(locale, en: "New", es: "Nuevo")
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

    private func healthLabel(for score: Int) -> String {
        switch score {
        case ..<45:
            return AppCopy.text(locale, en: "Needs attention", es: "Necesita atencion")
        case ..<70:
            return AppCopy.text(locale, en: "Watch closely", es: "Vigilar de cerca")
        case ..<85:
            return AppCopy.text(locale, en: "Healthy", es: "Saludable")
        default:
            return AppCopy.text(locale, en: "Strong", es: "Fuerte")
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
