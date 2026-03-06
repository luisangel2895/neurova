import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var systemImageName: String?
    var colorTokenReference: String?
    @Relationship(deleteRule: .nullify, inverse: \Deck.subject)
    var decks: [Deck]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        systemImageName: String? = nil,
        colorTokenReference: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.systemImageName = systemImageName
        self.colorTokenReference = colorTokenReference
        self.decks = nil
    }
}
