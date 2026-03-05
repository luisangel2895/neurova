import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var title: String
    var deckDescription: String?
    var createdAt: Date
    var isArchived: Bool
    var subject: Subject
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]
    @Relationship(deleteRule: .cascade, inverse: \MindMapEntity.deck)
    var generatedMindMaps: [MindMapEntity]
    @Relationship(deleteRule: .cascade, inverse: \StudyGuideEntity.deck)
    var generatedStudyGuides: [StudyGuideEntity]

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
        self.cards = []
        self.generatedMindMaps = []
        self.generatedStudyGuides = []
    }

    var description: String? {
        get { deckDescription }
        set { deckDescription = newValue }
    }
}
