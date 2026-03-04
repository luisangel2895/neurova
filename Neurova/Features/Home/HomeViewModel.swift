import Combine

final class HomeViewModel: ObservableObject {
    @Published var state: HomeState

    init(language: AppLanguage = .spanish) {
        let isEnglish = language == .english

        state = HomeState(
            greetingName: "Adrián",
            greetingEmoji: "👋",
            subtitle: isEnglish ? "Ready to study?" : "¿Listo para estudiar?",
            studySectionTitle: isEnglish ? "STUDY TODAY" : "ESTUDIA HOY",
            studyTitle: isEnglish ? "Daily goal" : "Meta diaria",
            progress: 0.64,
            progressPercentText: "64%",
            progressDetailText: isEnglish ? "16 / 25 cards completed" : "16 / 25 cards completadas",
            primaryActionTitle: isEnglish ? "Continue" : "Continuar",
            secondaryActionTitle: isEnglish ? "Choose deck" : "Elegir deck",
            settingsSymbolName: "gearshape",
            quickStats: [
                QuickStat(value: "7", label: isEnglish ? "Streak" : "Racha", systemImage: "flame", iconColor: NColors.Feedback.warning),
                QuickStat(value: "340", label: isEnglish ? "XP today" : "XP de hoy", systemImage: "bolt", iconColor: NColors.Brand.neuroBlue),
                QuickStat(value: "42", label: isEnglish ? "Cards ready" : "Cards pendientes", systemImage: "square.stack.3d.up", iconColor: NColors.Brand.neuralMint),
                QuickStat(value: "2.4h", label: isEnglish ? "Weekly time" : "Tiempo semanal", systemImage: "clock", iconColor: NColors.Text.textSecondary)
            ],
            recommendationSectionTitle: isEnglish ? "RECOMMENDED FOR YOU" : "RECOMENDADO PARA TI",
            recommendation: Recommendation(
                tags: isEnglish ? ["Review", "Weak", "New"] : ["Repaso", "Débil", "Nuevo"],
                title: isEnglish ? "Cell Biology - Mitosis" : "Biología Celular – Mitosis",
                message: isEnglish ? "12 weak cards detected. Reinforce them before your exam." : "12 cards débiles detectadas. Refuerza antes de tu examen.",
                actionTitle: isEnglish ? "Start review" : "Comenzar repaso"
            ),
            recentsSectionTitle: isEnglish ? "RECENT" : "RECIENTES",
            recentDecks: [
                RecentDeck(title: "Anatomía", cardCountText: "58 cards", accentColor: NColors.Brand.neuroBlue),
                RecentDeck(title: "Cálculo III", cardCountText: "34 cards", accentColor: NColors.Brand.neuralMint),
                RecentDeck(title: "Derecho Civil", cardCountText: "72 cards", accentColor: NColors.Brand.neuroBlueDeep)
            ],
            dailyGoalSummaryTitle: isEnglish ? "Daily goal: 25 cards" : "Meta diaria: 25 cards",
            dailyGoalSummaryProgress: 0.64,
            dailyGoalSummaryTrailingText: "64%",
            dailyGoalSummarySymbolName: "sparkles",
            tipTitle: isEnglish ? "Neurova tip" : "Tip de Neurova",
            tipMessage: isEnglish ? "Studying in 25-minute sessions with 5-minute breaks can improve retention by 40%." : "Estudiar en sesiones de 25 minutos con pausas de 5 mejora la retención un 40%."
        )
    }
}
