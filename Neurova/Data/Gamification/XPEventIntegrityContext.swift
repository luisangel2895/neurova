import Foundation

struct XPEventIntegrityContext {
    let source: String
    let expectedDeckId: Bool
    let expectedCardId: Bool
    let cardIdDescription: String
    let deckTitle: String?
}
