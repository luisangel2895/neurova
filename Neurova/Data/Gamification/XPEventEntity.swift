import Foundation
import SwiftData

@Model
final class XPEventEntity {
    var id: UUID = UUID()
    var date: Date = Date()
    var deckId: UUID?
    var cardId: UUID?
    var eventTypeRaw: String = ""
    var xpDelta: Int = 0

    init(
        id: UUID = UUID(),
        date: Date,
        deckId: UUID? = nil,
        cardId: UUID? = nil,
        eventTypeRaw: String,
        xpDelta: Int
    ) {
        self.id = id
        self.date = date
        self.deckId = deckId
        self.cardId = cardId
        self.eventTypeRaw = eventTypeRaw
        self.xpDelta = xpDelta
    }
}
