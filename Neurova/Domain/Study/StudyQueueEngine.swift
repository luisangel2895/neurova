import Foundation

enum StudyQueueFilter: Sendable {
    case all
    case ready
    case new
    case markedHard
}

struct StudySessionPolicy: Sendable {
    static let `default` = StudySessionPolicy()
}

struct StudyQueueEngine {
    func buildQueue(
        cards: [Card],
        filter: StudyQueueFilter,
        policy: StudySessionPolicy,
        now: Date = .now
    ) -> [Card] {
        let filtered = apply(filter: filter, to: cards, now: now)

        switch filter {
        case .all:
            return sortAllCards(filtered, now: now)
        case .new:
            return filtered
                .sorted { lhs, rhs in
                    if lhs.createdAt == rhs.createdAt {
                        return lhs.frontText < rhs.frontText
                    }
                    return lhs.createdAt < rhs.createdAt
                }
        case .markedHard:
            return filtered
                .sorted { lhs, rhs in
                    let lhsDue = lhs.nextReviewDate <= now
                    let rhsDue = rhs.nextReviewDate <= now
                    if lhsDue != rhsDue {
                        return lhsDue && !rhsDue
                    }
                    if lhs.nextReviewDate == rhs.nextReviewDate {
                        return lhs.createdAt < rhs.createdAt
                    }
                    return lhs.nextReviewDate < rhs.nextReviewDate
                }
        case .ready:
            break
        }

        let urgentLearning = filtered
            .filter { ($0.learningState == .learning || $0.learningState == .relearning) && $0.nextReviewDate <= now }
            .sorted { lhs, rhs in
                if lhs.nextReviewDate == rhs.nextReviewDate {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.nextReviewDate < rhs.nextReviewDate
            }

        let dueReviews = filtered
            .filter { $0.learningState == .review && $0.nextReviewDate <= now }
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

        // No limits mode: include every due and every new card in deterministic priority order.
        return urgentLearning + dueReviews + newCards
    }

    private func apply(filter: StudyQueueFilter, to cards: [Card], now: Date) -> [Card] {
        switch filter {
        case .all:
            return cards
        case .ready:
            return cards.filter { $0.nextReviewDate <= now }
        case .new:
            return cards.filter { $0.learningState == .new }
        case .markedHard:
            return cards.filter { $0.lastReviewQuality == .hard }
        }
    }

    private func sortAllCards(_ cards: [Card], now: Date) -> [Card] {
        cards.sorted { lhs, rhs in
            let lhsPriority = priorityBucket(for: lhs, now: now)
            let rhsPriority = priorityBucket(for: rhs, now: now)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            if lhs.nextReviewDate == rhs.nextReviewDate {
                if lhs.createdAt == rhs.createdAt {
                    return lhs.frontText < rhs.frontText
                }
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.nextReviewDate < rhs.nextReviewDate
        }
    }

    private func priorityBucket(for card: Card, now: Date) -> Int {
        let isDue = card.nextReviewDate <= now
        if (card.learningState == .learning || card.learningState == .relearning), isDue {
            return 0
        }
        if card.learningState == .review, isDue {
            return 1
        }
        if card.learningState == .new {
            return 2
        }
        if card.nextReviewDate > now {
            return 3
        }
        return 4
    }
}
