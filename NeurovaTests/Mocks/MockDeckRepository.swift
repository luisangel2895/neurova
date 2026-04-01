import Foundation
@testable import Neurova

final class MockDeckRepository: DeckRepository {
    var storedDecks: [Deck] = []
    var shouldThrow = false

    func listDecks(includeArchived: Bool) throws -> [Deck] {
        if shouldThrow { throw MockError.forced }
        return storedDecks
    }

    func decks(for subject: Subject, includeArchived: Bool) throws -> [Deck] {
        if shouldThrow { throw MockError.forced }
        return storedDecks.filter { $0.subject?.id == subject.id }
    }

    func createDeck(in subject: Subject, title: String, description: String?) throws -> Deck {
        if shouldThrow { throw MockError.forced }
        let deck = Deck(subject: subject, title: title, description: description)
        storedDecks.append(deck)
        return deck
    }

    func updateDeck(_ deck: Deck, title: String, description: String?, isArchived: Bool) throws {
        if shouldThrow { throw MockError.forced }
    }

    func archiveDeck(_ deck: Deck) throws {
        if shouldThrow { throw MockError.forced }
    }

    func deleteDeck(_ deck: Deck) throws {
        if shouldThrow { throw MockError.forced }
        storedDecks.removeAll { $0.id == deck.id }
    }
}
