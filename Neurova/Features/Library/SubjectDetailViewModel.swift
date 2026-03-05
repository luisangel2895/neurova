import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SubjectDetailViewModel {
    struct DeckMetrics {
        let cardCount: Int
        let dueCount: Int
    }

    private var deckRepository: (any DeckRepository)?
    private var cardRepository: (any CardRepository)?

    private(set) var decks: [Deck] = []
    private(set) var metricsByDeckID: [UUID: DeckMetrics] = [:]
    var errorMessage: String?

    func load(subject: Subject, using context: ModelContext) {
        configureIfNeeded(context: context)
        errorMessage = nil

        do {
            let fetchedDecks = try deckRepository?.decks(for: subject, includeArchived: false) ?? []
            decks = fetchedDecks

            var metrics: [UUID: DeckMetrics] = [:]
            for deck in fetchedDecks {
                let cards = try cardRepository?.cards(for: deck) ?? []
                let dueCards = try cardRepository?.dueCards(for: deck, asOf: .now) ?? []
                metrics[deck.id] = DeckMetrics(
                    cardCount: cards.count,
                    dueCount: dueCards.count
                )
            }
            metricsByDeckID = metrics
        } catch {
            errorMessage = "Unable to load decks."
        }
    }

    func createDeck(
        in subject: Subject,
        title: String,
        description: String?,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)

        do {
            _ = try deckRepository?.createDeck(
                in: subject,
                title: title,
                description: normalized(description)
            )
            load(subject: subject, using: context)
        } catch {
            errorMessage = "Unable to save deck."
        }
    }

    func updateDeck(
        _ deck: Deck,
        title: String,
        description: String?,
        isArchived: Bool,
        subject: Subject,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)

        do {
            try deckRepository?.updateDeck(
                deck,
                title: title,
                description: normalized(description),
                isArchived: isArchived
            )
            load(subject: subject, using: context)
        } catch {
            errorMessage = "Unable to update deck."
        }
    }

    func archiveDeck(
        _ deck: Deck,
        subject: Subject,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)

        do {
            try deckRepository?.archiveDeck(deck)
            load(subject: subject, using: context)
        } catch {
            errorMessage = "Unable to archive deck."
        }
    }

    func deleteDeck(
        _ deck: Deck,
        subject: Subject,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)

        do {
            try deckRepository?.deleteDeck(deck)
            load(subject: subject, using: context)
        } catch {
            errorMessage = "Unable to delete deck."
        }
    }

    func metrics(for deck: Deck) -> DeckMetrics {
        metricsByDeckID[deck.id] ?? DeckMetrics(cardCount: 0, dueCount: 0)
    }

    private func configureIfNeeded(context: ModelContext) {
        guard deckRepository == nil else { return }
        deckRepository = SwiftDataDeckRepository(context: context)
        cardRepository = SwiftDataCardRepository(context: context)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
