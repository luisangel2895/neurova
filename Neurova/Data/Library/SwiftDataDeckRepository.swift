import Foundation
import SwiftData

struct SwiftDataDeckRepository: DeckRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func listDecks(includeArchived: Bool = false) throws -> [Deck] {
        let descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate<Deck> { deck in
                includeArchived || deck.isArchived == false
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func decks(for subject: Subject, includeArchived: Bool = false) throws -> [Deck] {
        let descriptor = FetchDescriptor<Deck>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allDecks = try context.fetch(descriptor)
        return allDecks.filter { deck in
            deck.subject?.id == subject.id && (includeArchived || deck.isArchived == false)
        }
    }

    func createDeck(
        in subject: Subject,
        title: String,
        description: String?
    ) throws -> Deck {
        let deck = Deck(
            subject: subject,
            title: title,
            description: description
        )
        context.insert(deck)
        try context.save()
        return deck
    }

    func updateDeck(
        _ deck: Deck,
        title: String,
        description: String?,
        isArchived: Bool
    ) throws {
        deck.title = title
        deck.description = description
        deck.isArchived = isArchived
        try context.save()
    }

    func archiveDeck(_ deck: Deck) throws {
        deck.isArchived = true
        try context.save()
    }

    func deleteDeck(_ deck: Deck) throws {
        context.delete(deck)
        try context.save()
    }
}
