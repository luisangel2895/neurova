import Foundation
import SwiftData

@Model
final class Card {
    var frontText: String
    var backText: String
    var createdAt: Date
    var deck: Deck?
    var repetition: Int
    var interval: Int
    var easinessFactor: Double
    var nextReviewDate: Date
    var lastReviewDate: Date
    var lapses: Int
    var lastReviewQualityRaw: String?

    init(
        frontText: String = "",
        backText: String = "",
        deck: Deck? = nil,
        createdAt: Date = .now
    ) {
        self.frontText = frontText
        self.backText = backText
        self.createdAt = createdAt
        self.deck = deck
        self.repetition = 0
        self.interval = 0
        self.easinessFactor = 2.5
        self.nextReviewDate = createdAt
        self.lastReviewDate = createdAt
        self.lapses = 0
        self.lastReviewQualityRaw = nil
    }

    var isDue: Bool {
        Date.now >= nextReviewDate
    }

    var isNew: Bool {
        lastReviewQuality == nil
    }

    var isLearning: Bool {
        repetition > 0 && repetition < 3
    }

    var isMature: Bool {
        repetition >= 3
    }

    var lastReviewQuality: ReviewQuality? {
        get {
            guard let lastReviewQualityRaw else { return nil }

            switch lastReviewQualityRaw {
            case "again":
                return .again
            case "hard":
                return .hard
            case "good":
                return .good
            case "easy":
                return .easy
            default:
                return nil
            }
        }
        set {
            switch newValue {
            case .again:
                lastReviewQualityRaw = "again"
            case .hard:
                lastReviewQualityRaw = "hard"
            case .good:
                lastReviewQualityRaw = "good"
            case .easy:
                lastReviewQualityRaw = "easy"
            case nil:
                lastReviewQualityRaw = nil
            }
        }
    }
}
