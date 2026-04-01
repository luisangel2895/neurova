import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID = UUID()
    var title: String = ""
    var deckDescription: String?
    var createdAt: Date = Date()
    var isArchived: Bool = false
    var subject: Subject?
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]?

    init(
        id: UUID = UUID(),
        subject: Subject,
        title: String,
        description: String? = nil,
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.subject = subject
        self.title = title
        self.deckDescription = description
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.cards = nil
    }

    var description: String? {
        get { deckDescription }
        set { deckDescription = newValue }
    }
}
