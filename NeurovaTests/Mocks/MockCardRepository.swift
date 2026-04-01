import Foundation
@testable import Neurova

final class MockCardRepository: CardRepository {
    var storedCards: [Card] = []
    var storedDueCards: [Card] = []
    var storedDueCardCount: Int = 0
    var storedNewCardCount: Int = 0
    var shouldThrow = false

    func cards(for deck: Deck) throws -> [Card] {
        if shouldThrow { throw MockError.forced }
        return storedCards
    }

    func dueCards(for deck: Deck, asOf date: Date) throws -> [Card] {
        if shouldThrow { throw MockError.forced }
        return storedDueCards
    }

    func dueCardCount(asOf date: Date) throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedDueCardCount
    }

    func newCardCount() throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedNewCardCount
    }

    func createCard(in deck: Deck, frontText: String, backText: String, createdAt: Date) throws -> Card {
        if shouldThrow { throw MockError.forced }
        return Card(frontText: frontText, backText: backText)
    }

    func updateCardContent(_ card: Card, frontText: String, backText: String) throws {
        if shouldThrow { throw MockError.forced }
        card.frontText = frontText
        card.backText = backText
    }

    func deleteCard(_ card: Card) throws {
        if shouldThrow { throw MockError.forced }
    }
}
