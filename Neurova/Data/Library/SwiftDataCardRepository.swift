import Foundation
import SwiftData

struct SwiftDataCardRepository: CardRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func cards(for deck: Deck) throws -> [Card] {
        let deckID = deck.id
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.deck?.id == deckID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func dueCards(for deck: Deck, asOf date: Date = .now) throws -> [Card] {
        let deckID = deck.id
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.deck?.id == deckID && card.nextReviewDate <= date
            },
            sortBy: [SortDescriptor(\.nextReviewDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func createCard(
        in deck: Deck,
        frontText: String,
        backText: String,
        createdAt: Date = .now
    ) throws -> Card {
        let card = Card(
            frontText: frontText,
            backText: backText,
            deck: deck,
            createdAt: createdAt
        )
        context.insert(card)
        try context.save()
        return card
    }

    func updateCardContent(
        _ card: Card,
        frontText: String,
        backText: String
    ) throws {
        card.frontText = frontText
        card.backText = backText
        try context.save()
    }

    func deleteCard(_ card: Card) throws {
        context.delete(card)
        try context.save()
    }
}
