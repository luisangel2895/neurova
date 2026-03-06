import Foundation
import SwiftData

@Model
final class ScanEntity {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    @Attribute(.externalStorage) var imageData: Data?
    var rawText: String = ""
    var cleanedText: String = ""
    var languageCode: String = "es"

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        imageData: Data? = nil,
        rawText: String,
        cleanedText: String,
        languageCode: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.imageData = imageData
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.languageCode = languageCode
    }
}
