import Foundation

protocol CardRepository {
    func cards(for deck: Deck) throws -> [Card]
    func dueCards(for deck: Deck, asOf date: Date) throws -> [Card]
    func dueCardCount(asOf date: Date) throws -> Int
    func newCardCount() throws -> Int
    func createCard(
        in deck: Deck,
        frontText: String,
        backText: String,
        createdAt: Date
    ) throws -> Card
    func updateCardContent(
        _ card: Card,
        frontText: String,
        backText: String
    ) throws
    func deleteCard(_ card: Card) throws
}
