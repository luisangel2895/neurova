import Foundation
import SwiftData
import SwiftUI

struct HomeUseCases {
    private let context: ModelContext
    private let deckRepository: any DeckRepository
    private let queueEngine: StudyQueueEngine
    private let sessionPolicy: StudySessionPolicy

    init(
        context: ModelContext,
        deckRepository: (any DeckRepository)? = nil,
        queueEngine: StudyQueueEngine = StudyQueueEngine()
    ) {
        self.context = context
        self.deckRepository = deckRepository ?? SwiftDataDeckRepository(context: context)
        self.queueEngine = queueEngine
        self.sessionPolicy = Self.loadSessionPolicy(from: context)
    }

    func makeState(language: AppLanguage, now: Date = .now) throws -> HomeState {
        let isEnglish = language == .english

        let gamification = try GamificationService(context: context).snapshot()
        let streak = try StreakService(context: context).snapshot()
        let decks = try deckRepository.listDecks(includeArchived: false)

        let summaries = deckSummaries(for: decks, now: now)
        let recommended = recommendedDeck(from: summaries)
        let recent = Array(summaries.prefix(5))

        let totalReady = summaries.reduce(0) { $0 + $1.readyCount }
        let totalNew = summaries.reduce(0) { $0 + $1.newCount }

        let dailyProgress = streak.dailyGoal > 0
            ? min(Double(streak.todayProgress) / Double(streak.dailyGoal), 1)
            : 0

        let progressText = "\(Int((dailyProgress * 100).rounded()))%"
        let progressDetailText = isEnglish
            ? "\(streak.todayProgress) / \(streak.dailyGoal) cards completed"
            : "\(streak.todayProgress) / \(streak.dailyGoal) tarjetas completadas"
        let recommendedDeckText = recommended.map { summary in
            let deckPath = deckPathText(for: summary.deck)
            return isEnglish
                ? "Recommended deck: \(deckPath)"
                : "Deck recomendado: \(deckPath)"
        }

        let recommendation = recommendedRecommendation(
            from: recommended,
            isEnglish: isEnglish
        )
        let studyRecommendations = summaries
            .filter { $0.readyCount > 0 }
            .sorted { lhs, rhs in
                if lhs.readyCount != rhs.readyCount {
                    return lhs.readyCount > rhs.readyCount
                }
                return lhs.lastActivityDate > rhs.lastActivityDate
            }
            .prefix(6)
            .map { summary in
                StudyDeckRecommendation(
                    id: summary.deck.id,
                    deck: summary.deck,
                    subjectPathText: deckPathText(for: summary.deck),
                    readyCount: summary.readyCount,
                    totalCards: summary.totalCards,
                    accentColor: summary.accentColor
                )
            }

        return HomeState(
            greetingName: "Adrián",
            greetingEmoji: "👋",
            subtitle: isEnglish ? "Ready to study?" : "¿Listo para estudiar?",
            studySectionTitle: isEnglish ? "STUDY TODAY" : "ESTUDIA HOY",
            studyTitle: isEnglish ? "Daily goal" : "Meta diaria",
            recommendedDeckText: recommendedDeckText,
            progress: dailyProgress,
            progressPercentText: progressText,
            progressDetailText: progressDetailText,
            primaryActionTitle: recommended == nil
                ? (isEnglish ? "Open library" : "Abrir biblioteca")
                : (isEnglish ? "Study now" : "Estudiar ahora"),
            secondaryActionTitle: isEnglish ? "Choose deck" : "Elegir deck",
            settingsSymbolName: "gearshape",
            quickStats: [
                QuickStat(
                    value: "\(streak.currentStreak)",
                    label: isEnglish ? "Day streak" : "Racha diaria",
                    systemImage: "flame",
                    iconColor: NColors.Feedback.warning
                ),
                QuickStat(
                    value: "\(gamification.todayXP)",
                    label: isEnglish ? "XP today" : "XP hoy",
                    systemImage: "bolt",
                    iconColor: NColors.Brand.neuroBlue
                ),
                QuickStat(
                    value: "\(totalReady)",
                    label: isEnglish ? "Ready cards" : "Tarjetas listas",
                    systemImage: "square.stack.3d.up",
                    iconColor: NColors.Brand.neuralMint
                ),
                QuickStat(
                    value: "\(decks.count)",
                    label: isEnglish ? "Decks" : "Decks",
                    systemImage: "rectangle.stack",
                    iconColor: NColors.Brand.neuroBlueDeep
                )
            ],
            recommendationSectionTitle: isEnglish ? "RECOMMENDED FOR YOU" : "RECOMENDADO PARA TI",
            recommendation: recommendation,
            studyRecommendations: studyRecommendations,
            recentsSectionTitle: isEnglish ? "RECENT DECKS" : "DECKS RECIENTES",
            recentDecks: recent.map { summary in
                RecentDeck(
                    id: summary.deck.id,
                    deck: summary.deck,
                    subjectPathText: subjectNameText(for: summary.deck),
                    title: summary.deck.title,
                    cardCountText: isEnglish
                        ? "\(summary.totalCards) cards"
                        : "\(summary.totalCards) tarjetas",
                    readyCountText: isEnglish
                        ? "\(summary.readyCount) ready"
                        : "\(summary.readyCount) listas",
                    accentColor: summary.accentColor
                )
            },
            dailyGoalSummaryTitle: isEnglish
                ? "Daily goal: \(streak.dailyGoal) cards"
                : "Meta diaria: \(streak.dailyGoal) tarjetas",
            dailyGoalSummaryProgress: dailyProgress,
            dailyGoalSummaryTrailingText: progressText,
            dailyGoalSummarySymbolName: "sparkles",
            tipTitle: isEnglish ? "Neurova tip" : "Tip de Neurova",
            tipMessage: isEnglish
                ? "Focus on ready cards first, then introduce new cards to avoid backlog."
                : "Prioriza tarjetas listas y luego agrega nuevas para evitar acumulación.",
            highlightedDeck: recommended?.deck,
            isEmptyState: decks.isEmpty && totalNew == 0 && totalReady == 0
        )
    }

    func studyCards(for deck: Deck, filter: StudyCardFilter, now: Date = .now) -> [Card] {
        queueEngine.buildQueue(
            cards: deck.cards,
            filter: filter.queueFilter,
            policy: sessionPolicy,
            now: now
        )
    }

    func studyCounts(for deck: Deck, now: Date = .now) -> [StudyCardFilter: Int] {
        StudyCardFilter.allCases.reduce(into: [:]) { partialResult, filter in
            partialResult[filter] = studyCards(for: deck, filter: filter, now: now).count
        }
    }

    private func deckSummaries(for decks: [Deck], now: Date) -> [DeckSummary] {
        let accentPalette: [Color] = [
            NColors.Brand.neuroBlue,
            NColors.Brand.neuralMint,
            NColors.Brand.neuroBlueDeep
        ]

        return decks.enumerated()
            .map { index, deck in
                let allCards = deck.cards
                let readyCards = queueEngine.buildQueue(
                    cards: allCards,
                    filter: .ready,
                    policy: sessionPolicy,
                    now: now
                )
                let newCards = allCards.filter { $0.learningState == .new }
                let activityDate = allCards
                    .map(\.lastReviewDate)
                    .max() ?? deck.createdAt

                return DeckSummary(
                    deck: deck,
                    readyCount: readyCards.count,
                    newCount: newCards.count,
                    totalCards: allCards.count,
                    lastActivityDate: activityDate,
                    accentColor: accentPalette[index % accentPalette.count]
                )
            }
            .sorted { lhs, rhs in
                lhs.lastActivityDate > rhs.lastActivityDate
            }
    }

    private func recommendedDeck(from summaries: [DeckSummary]) -> DeckSummary? {
        summaries
            .sorted { lhs, rhs in
                if lhs.readyCount != rhs.readyCount {
                    return lhs.readyCount > rhs.readyCount
                }
                if lhs.newCount != rhs.newCount {
                    return lhs.newCount > rhs.newCount
                }
                if lhs.totalCards != rhs.totalCards {
                    return lhs.totalCards > rhs.totalCards
                }
                return lhs.deck.title < rhs.deck.title
            }
            .first
    }

    private func recommendedRecommendation(from summary: DeckSummary?, isEnglish: Bool) -> Recommendation {
        guard let summary else {
            return Recommendation(
                tags: isEnglish ? ["Low", "0 min"] : ["Baja", "0 min"],
                title: isEnglish ? "Create your first deck" : "Crea tu primer deck",
                message: isEnglish
                    ? "You do not have decks yet. Start by creating one in Library."
                    : "Aún no tienes decks. Comienza creando uno en Biblioteca.",
                actionTitle: isEnglish ? "Open library" : "Abrir biblioteca"
            )
        }

        let difficulty = difficultyLabel(for: summary.deck, isEnglish: isEnglish)
        let estimatedMinutes = estimatedStudyMinutes(forReadyCount: summary.readyCount)

        return Recommendation(
            tags: [
                difficulty,
                "\(estimatedMinutes) min"
            ],
            title: summary.deck.title,
            message: isEnglish
                ? "\(summary.readyCount) ready and \(summary.newCount) new cards in this deck."
                : "\(summary.readyCount) listas y \(summary.newCount) nuevas en este deck.",
            actionTitle: isEnglish ? "Open study options" : "Abrir opciones de estudio"
        )
    }

    private static func loadSessionPolicy(from context: ModelContext) -> StudySessionPolicy {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        let preferences = try? context.fetch(descriptor).first

        return StudySessionPolicy(
            newCardsPerDay: preferences?.resolvedNewCardsPerDay ?? StudySessionPolicy.default.newCardsPerDay,
            maxReviewsPerDay: preferences?.resolvedMaxReviewsPerDay ?? StudySessionPolicy.default.maxReviewsPerDay,
            sessionTimeCapSeconds: preferences?.resolvedSessionTimeCapSeconds,
            avoidNewWhenDueBacklogHigh: preferences?.resolvedAvoidNewWhenDueBacklogHigh ?? StudySessionPolicy.default.avoidNewWhenDueBacklogHigh,
            dueBacklogThreshold: preferences?.resolvedDueBacklogThreshold ?? StudySessionPolicy.default.dueBacklogThreshold
        )
    }

    private func deckPathText(for deck: Deck) -> String {
        let subjectName = subjectNameText(for: deck)
        return "\(subjectName) / \(deck.title)"
    }

    private func subjectNameText(for deck: Deck) -> String {
        deck.subject.name
    }

    private func difficultyLabel(for deck: Deck, isEnglish: Bool) -> String {
        let cards = deck.cards
        guard cards.isEmpty == false else {
            return isEnglish ? "Low" : "Baja"
        }

        var reviewedCount = 0
        let score = cards.reduce(into: 0) { partialResult, card in
            guard let quality = card.lastReviewQualityRaw else { return }
            reviewedCount += 1
            switch quality {
            case "easy":
                partialResult += 1
            case "good":
                partialResult += 3
            case "hard", "again":
                partialResult += 5
            default:
                break
            }
        }

        guard reviewedCount > 0 else {
            return isEnglish ? "Medium" : "Media"
        }

        let averageScore = Double(score) / Double(reviewedCount)
        if averageScore >= 4.2 {
            return isEnglish ? "High" : "Alta"
        }
        if averageScore >= 2.4 {
            return isEnglish ? "Medium" : "Media"
        }
        return isEnglish ? "Low" : "Baja"
    }

    private func estimatedStudyMinutes(forReadyCount readyCount: Int) -> Int {
        guard readyCount > 0 else { return 0 }
        let secondsPerCard = 10
        return Int(ceil(Double(readyCount * secondsPerCard) / 60.0))
    }
}

private struct DeckSummary {
    let deck: Deck
    let readyCount: Int
    let newCount: Int
    let totalCards: Int
    let lastActivityDate: Date
    let accentColor: Color
}
