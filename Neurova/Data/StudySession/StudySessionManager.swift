import Foundation
import SwiftData

struct SessionState: Equatable {
    let currentCard: Card?
    let remainingCount: Int
    let progressPercentage: Double
    let isFinished: Bool
}

final class StudySessionManager {
    private let reviewService: ReviewService
    private let context: ModelContext
    private let queueEngine: StudyQueueEngine

    private var queue: [Card] = []
    private var initialCount: Int = 0

    private(set) var correctCount: Int = 0
    private(set) var wrongCount: Int = 0
    private(set) var totalReviewed: Int = 0
    private(set) var sessionStartTime: Date?
    private(set) var sessionEndTime: Date?
    private(set) var xpEarned: Int = 0

    init(
        context: ModelContext,
        reviewService: ReviewService = ReviewService(),
        queueEngine: StudyQueueEngine = StudyQueueEngine()
    ) {
        self.context = context
        self.reviewService = reviewService
        self.queueEngine = queueEngine
    }

    func loadSession(with cards: [Card], startDate: Date = .now) {
        loadSession(with: cards, filter: .all, startDate: startDate)
    }

    func loadSession(
        with cards: [Card],
        filter: StudyQueueFilter,
        startDate: Date = .now
    ) {
        let policy = loadSessionPolicy()
        queue = queueEngine.buildQueue(
            cards: cards,
            filter: filter,
            policy: policy,
            now: startDate
        )
        initialCount = queue.count

        correctCount = 0
        wrongCount = 0
        totalReviewed = 0
        xpEarned = 0
        sessionStartTime = queue.isEmpty ? nil : startDate
        sessionEndTime = queue.isEmpty ? startDate : nil
    }

    func nextCard() -> Card? {
        queue.first
    }

    func currentState() -> SessionState {
        let remainingCount = queue.count
        let reviewedCount = initialCount - remainingCount
        let progressPercentage = initialCount == 0
            ? 1
            : Double(reviewedCount) / Double(initialCount)

        return SessionState(
            currentCard: queue.first,
            remainingCount: remainingCount,
            progressPercentage: progressPercentage,
            isFinished: queue.isEmpty
        )
    }

    @discardableResult
    func submitReview(
        quality: ReviewQuality,
        reviewDate: Date = .now
    ) throws -> SessionState {
        guard let currentCard = queue.first else {
            sessionEndTime = sessionEndTime ?? reviewDate
            return currentState()
        }

        try reviewService.review(
            card: currentCard,
            quality: quality,
            at: reviewDate,
            in: context
        )

        totalReviewed += 1
        xpEarned += xp(for: quality)

        if quality == .again {
            wrongCount += 1
        } else {
            correctCount += 1
        }

        queue.removeFirst()

        if queue.isEmpty {
            sessionEndTime = reviewDate
        }

        return currentState()
    }

    private func xp(for quality: ReviewQuality) -> Int {
        switch quality {
        case .again:
            return 0
        case .hard:
            return 5
        case .good:
            return 10
        case .easy:
            return 15
        }
    }

    private func loadSessionPolicy() -> StudySessionPolicy {
        .default
    }
}
