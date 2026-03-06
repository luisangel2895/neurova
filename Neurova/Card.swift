import Foundation
import SwiftData

@Model
final class Card {
    var frontText: String = ""
    var backText: String = ""
    var createdAt: Date = Date()
    var deck: Deck?
    var repetition: Int = 0
    var interval: Int = 0
    var easinessFactor: Double = 2.5
    var nextReviewDate: Date = Date()
    var lastReviewDate: Date = Date()
    var lapses: Int = 0
    var lastReviewQualityRaw: String?
    var learningStateRaw: String?
    var learningModeRaw: String?
    var learningStepIndex: Int?
    var totalReviews: Int?

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
        self.learningStateRaw = nil
        self.learningModeRaw = nil
        self.learningStepIndex = nil
        self.totalReviews = 0
    }

    var isDue: Bool {
        Date.now >= nextReviewDate
    }

    var isNew: Bool {
        learningState == .new
    }

    var isLearning: Bool {
        learningState == .learning || learningState == .relearning
    }

    var isMature: Bool {
        learningState == .review && repetition >= 3
    }

    var learningState: CardLearningState {
        get {
            if let learningStateRaw, let parsed = CardLearningState(rawValue: learningStateRaw) {
                return parsed
            }

            if repetition == 0 && resolvedTotalReviews == 0 {
                return .new
            }

            if learningMode == .relearning {
                return .relearning
            }

            if interval >= 1 {
                return .review
            }

            if resolvedTotalReviews > 0 && interval == 0 {
                return .learning
            }

            return .new
        }
        set {
            learningStateRaw = newValue.rawValue
        }
    }

    var learningMode: CardLearningMode {
        get {
            if let learningModeRaw, let parsed = CardLearningMode(rawValue: learningModeRaw) {
                return parsed
            }
            return .none
        }
        set {
            learningModeRaw = newValue.rawValue
        }
    }

    var resolvedTotalReviews: Int {
        if let totalReviews {
            return totalReviews
        }
        return lastReviewQuality == nil ? 0 : 1
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
