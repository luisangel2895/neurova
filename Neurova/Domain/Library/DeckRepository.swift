import Foundation

protocol DeckRepository {
    func listDecks(includeArchived: Bool) throws -> [Deck]
    func decks(for subject: Subject, includeArchived: Bool) throws -> [Deck]
    func createDeck(
        in subject: Subject,
        title: String,
        description: String?
    ) throws -> Deck
    func updateDeck(
        _ deck: Deck,
        title: String,
        description: String?,
        isArchived: Bool
    ) throws
    func archiveDeck(_ deck: Deck) throws
    func deleteDeck(_ deck: Deck) throws
}
