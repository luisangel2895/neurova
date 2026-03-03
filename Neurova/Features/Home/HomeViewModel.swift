import Combine

final class HomeViewModel: ObservableObject {
    @Published var state: HomeState

    init() {
        state = HomeState(
            greetingName: "Adrián",
            greetingEmoji: "👋",
            subtitle: "¿Listo para estudiar?",
            studySectionTitle: "ESTUDIA HOY",
            studyTitle: "Meta diaria",
            progress: 0.64,
            progressPercentText: "64%",
            progressDetailText: "16 / 25 cards completadas",
            primaryActionTitle: "Continuar",
            secondaryActionTitle: "Elegir deck",
            settingsSymbolName: "gearshape",
            quickStats: [
                QuickStat(value: "7", label: "Racha", systemImage: "flame", iconColor: NColors.Feedback.warning),
                QuickStat(value: "340", label: "XP de hoy", systemImage: "bolt", iconColor: NColors.Brand.neuroBlue),
                QuickStat(value: "42", label: "Cards pendientes", systemImage: "square.stack.3d.up", iconColor: NColors.Brand.neuralMint),
                QuickStat(value: "2.4h", label: "Tiempo semanal", systemImage: "clock", iconColor: NColors.Text.textSecondary)
            ],
            recommendationSectionTitle: "RECOMENDADO PARA TI",
            recommendation: Recommendation(
                tags: ["Repaso", "Débil", "Nuevo"],
                title: "Biología Celular – Mitosis",
                message: "12 cards débiles detectadas. Refuerza antes de tu examen.",
                actionTitle: "Comenzar repaso"
            ),
            recentsSectionTitle: "RECIENTES",
            recentDecks: [
                RecentDeck(title: "Anatomía", cardCountText: "58 cards", accentColor: NColors.Brand.neuroBlue),
                RecentDeck(title: "Cálculo III", cardCountText: "34 cards", accentColor: NColors.Brand.neuralMint),
                RecentDeck(title: "Derecho Civil", cardCountText: "72 cards", accentColor: NColors.Brand.neuroBlueDeep)
            ],
            dailyGoalSummaryTitle: "Meta diaria: 25 cards",
            dailyGoalSummaryProgress: 0.64,
            dailyGoalSummaryTrailingText: "64%",
            dailyGoalSummarySymbolName: "sparkles",
            tipTitle: "Tip de Neurova",
            tipMessage: "Estudiar en sesiones de 25 minutos con pausas de 5 mejora la retención un 40%."
        )
    }
}
