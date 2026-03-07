import Foundation
import Observation
import SwiftData

enum StudyCardFilter: String, CaseIterable, Identifiable {
    case due
    case new
    case review
    case all

    var id: String { rawValue }

    func title(for locale: Locale) -> String {
        switch self {
        case .due:
            return AppCopy.text(locale, en: "Ready", es: "Listo")
        case .new:
            return AppCopy.text(locale, en: "New", es: "Nuevo")
        case .review:
            return AppCopy.text(locale, en: "Needs Review", es: "Necesita Repaso")
        case .all:
            return AppCopy.text(locale, en: "All", es: "Todo")
        }
    }

    func subtitle(for locale: Locale) -> String {
        switch self {
        case .due:
            return AppCopy.text(locale, en: "Cards available to study right now.", es: "Tarjetas disponibles para estudiar ahora.")
        case .new:
            return AppCopy.text(locale, en: "Brand new cards you have not studied yet.", es: "Tarjetas nuevas que aun no has estudiado.")
        case .review:
            return AppCopy.text(locale, en: "Cards that need extra reinforcement.", es: "Tarjetas que necesitan refuerzo extra.")
        case .all:
            return AppCopy.text(locale, en: "Every card in this deck.", es: "Todas las tarjetas de este mazo.")
        }
    }

    var queueFilter: StudyQueueFilter {
        switch self {
        case .due:
            return .ready
        case .new:
            return .new
        case .review:
            return .markedHard
        case .all:
            return .all
        }
    }
}

@MainActor
@Observable
final class DeckDetailViewModel {
    private var cardRepository: (any CardRepository)?
    private let queueEngine = StudyQueueEngine()
    private var sessionPolicy = StudySessionPolicy.default

    private(set) var cards: [Card] = []
    var errorMessage: String?

    func load(deck: Deck, using context: ModelContext) {
        configureIfNeeded(context: context)
        errorMessage = nil

        do {
            cards = try cardRepository?.cards(for: deck) ?? []
            sessionPolicy = loadSessionPolicy(using: context)
        } catch {
            errorMessage = "Unable to load cards."
        }
    }

    func createCard(
        in deck: Deck,
        frontText: String,
        backText: String,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)

        do {
            _ = try cardRepository?.createCard(
                in: deck,
                frontText: frontText,
                backText: backText,
                createdAt: .now
            )
            load(deck: deck, using: context)
        } catch {
            errorMessage = "Unable to save card."
        }
    }

    func deleteCard(
        at index: Int,
        in deck: Deck,
        using context: ModelContext
    ) {
        guard cards.indices.contains(index) else { return }
        configureIfNeeded(context: context)

        do {
            try cardRepository?.deleteCard(cards[index])
            load(deck: deck, using: context)
        } catch {
            errorMessage = "Unable to delete card."
        }
    }

    var totalCards: Int {
        cards.count
    }

    var dueTodayCount: Int {
        queueEngine.buildQueue(
            cards: cards,
            filter: .ready,
            policy: sessionPolicy,
            now: .now
        ).count
    }

    var newCardsCount: Int {
        queueEngine.buildQueue(
            cards: cards,
            filter: .new,
            policy: sessionPolicy,
            now: .now
        ).count
    }

    func count(for filter: StudyCardFilter) -> Int {
        filteredCards(for: filter).count
    }

    func filteredCards(for filter: StudyCardFilter) -> [Card] {
        queueEngine.buildQueue(
            cards: cards,
            filter: filter.queueFilter,
            policy: sessionPolicy,
            now: .now
        )
    }

    private func configureIfNeeded(context: ModelContext) {
        guard cardRepository == nil else { return }
        cardRepository = SwiftDataCardRepository(context: context)
    }

    private func loadSessionPolicy(using context: ModelContext) -> StudySessionPolicy {
        _ = context
        return .default
    }
}
