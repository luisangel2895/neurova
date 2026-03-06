import Foundation
import SwiftData

@Model
final class MindMapEntity {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var title: String = ""
    var serializedTree: String = ""
    var sourceScanID: UUID?
    var deckID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        title: String,
        serializedTree: String,
        sourceScanID: UUID? = nil,
        deckID: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.serializedTree = serializedTree
        self.sourceScanID = sourceScanID
        self.deckID = deckID
    }
}
