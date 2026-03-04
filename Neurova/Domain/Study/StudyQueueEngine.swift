import Foundation

enum StudyQueueFilter: Sendable {
    case all
    case ready
    case new
    case markedHard
}

struct StudySessionPolicy: Sendable {
    let newCardsPerDay: Int
    let maxReviewsPerDay: Int
    let sessionTimeCapSeconds: Int?
    let avoidNewWhenDueBacklogHigh: Bool
    let dueBacklogThreshold: Int

    static let `default` = StudySessionPolicy(
        newCardsPerDay: 20,
        maxReviewsPerDay: 200,
        sessionTimeCapSeconds: nil,
        avoidNewWhenDueBacklogHigh: false,
        dueBacklogThreshold: 50
    )
}

struct StudyQueueEngine {
    func buildQueue(
        cards: [Card],
        filter: StudyQueueFilter,
        policy: StudySessionPolicy,
        now: Date = .now
    ) -> [Card] {
        let filtered = apply(filter: filter, to: cards, now: now)

        let urgentLearning = filtered
            .filter { ($0.learningState == .learning || $0.learningState == .relearning) && $0.isDue }
            .sorted { lhs, rhs in
                if lhs.nextReviewDate == rhs.nextReviewDate {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.nextReviewDate < rhs.nextReviewDate
            }

        let dueReviews = filtered
            .filter { $0.learningState == .review && $0.isDue }
            .sorted { lhs, rhs in
                let lhsOverdue = now.timeIntervalSince(lhs.nextReviewDate)
                let rhsOverdue = now.timeIntervalSince(rhs.nextReviewDate)
                if lhsOverdue == rhsOverdue {
                    if lhs.nextReviewDate == rhs.nextReviewDate {
                        return lhs.createdAt < rhs.createdAt
                    }
                    return lhs.nextReviewDate < rhs.nextReviewDate
                }
                return lhsOverdue > rhsOverdue
            }

        let newCards = filtered
            .filter { $0.learningState == .new }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.frontText < rhs.frontText
                }
                return lhs.createdAt < rhs.createdAt
            }

        let dueBacklog = urgentLearning.count + dueReviews.count
        let includeNew = policy.avoidNewWhenDueBacklogHigh == false || dueBacklog < policy.dueBacklogThreshold
        let cappedNewCards = includeNew ? Array(newCards.prefix(max(policy.newCardsPerDay, 0))) : []

        var queue = urgentLearning + dueReviews + cappedNewCards
        if policy.maxReviewsPerDay > 0 {
            queue = Array(queue.prefix(policy.maxReviewsPerDay))
        }

        return queue
    }

    private func apply(filter: StudyQueueFilter, to cards: [Card], now: Date) -> [Card] {
        switch filter {
        case .all:
            return cards
        case .ready:
            return cards.filter { $0.isDue || $0.learningState == .learning || $0.learningState == .relearning }
        case .new:
            return cards.filter { $0.learningState == .new }
        case .markedHard:
            return cards.filter { $0.lastReviewQuality == .hard }
        }
    }
}
