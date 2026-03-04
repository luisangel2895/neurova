import Foundation
import Observation
import SwiftData

enum StudyCardFilter: String, CaseIterable, Identifiable {
    case due
    case new
    case review
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .due:
            return "Ready"
        case .new:
            return "New"
        case .review:
            return "Needs Review"
        case .all:
            return "All"
        }
    }

    var subtitle: String {
        switch self {
        case .due:
            return "Cards available to study right now."
        case .new:
            return "Brand new cards you have not studied yet."
        case .review:
            return "Cards that need extra reinforcement."
        case .all:
            return "Every card in this deck."
        }
    }
}

@MainActor
@Observable
final class DeckDetailViewModel {
    private var cardRepository: (any CardRepository)?

    private(set) var cards: [Card] = []
    var errorMessage: String?

    func load(deck: Deck, using context: ModelContext) {
        configureIfNeeded(context: context)
        errorMessage = nil

        do {
            cards = try cardRepository?.cards(for: deck) ?? []
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
        cards.filter(\.isDue).count
    }

    var newCardsCount: Int {
        cards.filter(\.isNew).count
    }

    func count(for filter: StudyCardFilter) -> Int {
        filteredCards(for: filter).count
    }

    func filteredCards(for filter: StudyCardFilter) -> [Card] {
        switch filter {
        case .due:
            return cards.filter(\.isDue)
        case .new:
            return cards.filter(\.isNew)
        case .review:
            return cards.filter { $0.lastReviewQuality == .hard }
        case .all:
            return cards
        }
    }

    private func configureIfNeeded(context: ModelContext) {
        guard cardRepository == nil else { return }
        cardRepository = SwiftDataCardRepository(context: context)
    }
}
