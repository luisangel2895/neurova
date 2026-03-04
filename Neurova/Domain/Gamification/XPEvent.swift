import Foundation

struct XPEvent: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let deckId: UUID?
    let cardId: UUID?
    let eventType: XPEventType
    let xpDelta: Int
}
