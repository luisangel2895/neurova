import Foundation
import SwiftData

@Model
final class StudyGuideEntity {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var title: String = ""
    var summary: String = ""
    var serializedSections: String = ""
    var sourceScanID: UUID?
    var deckID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        title: String,
        summary: String,
        serializedSections: String,
        sourceScanID: UUID? = nil,
        deckID: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.summary = summary
        self.serializedSections = serializedSections
        self.sourceScanID = sourceScanID
        self.deckID = deckID
    }
}
