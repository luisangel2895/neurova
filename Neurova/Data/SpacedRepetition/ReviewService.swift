import Foundation
import SwiftData

struct ReviewService {
    private let engine: any SpacedRepetitionEngine
    private let xpPolicy: any XPPolicy

    private enum LearningSteps {
        static let learning: [TimeInterval] = [60, 10 * 60]
        static let relearning: [TimeInterval] = [10 * 60]
    }

    private struct SchedulingOutcome {
        let result: SM2Result
        let learningState: CardLearningState
        let learningMode: CardLearningMode
        let learningStepIndex: Int?
    }

    init(
        engine: any SpacedRepetitionEngine = SM2Engine(),
        xpPolicy: any XPPolicy = DefaultXPPolicy()
    ) {
        self.engine = engine
        self.xpPolicy = xpPolicy
    }

    @discardableResult
    func review(
        card: Card,
        quality: ReviewQuality,
        eventType: XPEventType? = nil,
        at reviewDate: Date = .now,
        in context: ModelContext
    ) throws -> SM2Result {
        let outcome = schedule(card: card, quality: quality, reviewDate: reviewDate)
        let result = outcome.result

        card.repetition = result.repetition
        card.interval = result.interval
        card.easinessFactor = result.easinessFactor
        card.nextReviewDate = result.nextReviewDate
        card.lastReviewDate = reviewDate
        card.lapses = result.lapses
        card.lastReviewQuality = quality
        card.learningState = outcome.learningState
        card.learningMode = outcome.learningMode
        card.learningStepIndex = outcome.learningStepIndex
        card.totalReviews = card.resolvedTotalReviews + 1

        let resolvedEventType = eventType ?? defaultXPEventType(for: quality)
        let xpEvent = XPEvent(
            id: UUID(),
            date: reviewDate,
            deckId: card.deck?.id,
            cardId: nil,
            eventType: resolvedEventType,
            xpDelta: xpPolicy.xpDelta(for: resolvedEventType)
        )

        let xpRepository = SwiftDataXPEventRepository(context: context)
        try xpRepository.record(
            xpEvent,
            integrityContext: XPEventIntegrityContext(
                source: "ReviewService.review",
                expectedDeckId: card.deck != nil,
                expectedCardId: false,
                cardIdDescription: "n/a",
                deckTitle: card.deck?.title
            )
        )

        return result
    }

    private func schedule(card: Card, quality: ReviewQuality, reviewDate: Date) -> SchedulingOutcome {
        switch card.learningState {
        case .new:
            return scheduleNew(card: card, quality: quality, reviewDate: reviewDate)
        case .learning:
            return scheduleLearning(
                card: card,
                quality: quality,
                reviewDate: reviewDate,
                mode: .learning,
                steps: LearningSteps.learning
            )
        case .relearning:
            return scheduleLearning(
                card: card,
                quality: quality,
                reviewDate: reviewDate,
                mode: .relearning,
                steps: LearningSteps.relearning
            )
        case .review:
            return scheduleReview(card: card, quality: quality, reviewDate: reviewDate)
        }
    }

    private func scheduleNew(card: Card, quality: ReviewQuality, reviewDate: Date) -> SchedulingOutcome {
        switch quality {
        case .again:
            return startStep(
                card: card,
                reviewDate: reviewDate,
                mode: .learning,
                steps: LearningSteps.learning,
                stepIndex: 0,
                addLapse: false
            )
        case .hard:
            // Keep the existing product policy: first hard review returns in 10 minutes.
            return startStep(
                card: card,
                reviewDate: reviewDate,
                mode: .learning,
                steps: LearningSteps.learning,
                stepIndex: 1,
                addLapse: false
            )
        case .good:
            return graduateToReview(card: card, reviewDate: reviewDate, intervalDays: 1, repetition: max(card.repetition, 1))
        case .easy:
            return graduateToReview(card: card, reviewDate: reviewDate, intervalDays: 3, repetition: max(card.repetition, 2))
        }
    }

    private func scheduleLearning(
        card: Card,
        quality: ReviewQuality,
        reviewDate: Date,
        mode: CardLearningMode,
        steps: [TimeInterval]
    ) -> SchedulingOutcome {
        let currentIndex = min(max(card.learningStepIndex ?? 0, 0), max(steps.count - 1, 0))

        switch quality {
        case .again:
            return startStep(
                card: card,
                reviewDate: reviewDate,
                mode: mode,
                steps: steps,
                stepIndex: 0,
                addLapse: true
            )
        case .hard:
            return startStep(
                card: card,
                reviewDate: reviewDate,
                mode: mode,
                steps: steps,
                stepIndex: currentIndex,
                addLapse: false
            )
        case .good, .easy:
            let nextIndex = currentIndex + 1
            if nextIndex < steps.count {
                return startStep(
                    card: card,
                    reviewDate: reviewDate,
                    mode: mode,
                    steps: steps,
                    stepIndex: nextIndex,
                    addLapse: false
                )
            }

            return graduateToReview(
                card: card,
                reviewDate: reviewDate,
                intervalDays: quality == .easy ? 3 : 1,
                repetition: quality == .easy ? max(card.repetition, 2) : max(card.repetition, 1)
            )
        }
    }

    private func scheduleReview(card: Card, quality: ReviewQuality, reviewDate: Date) -> SchedulingOutcome {
        if quality == .again {
            return startStep(
                card: card,
                reviewDate: reviewDate,
                mode: .relearning,
                steps: LearningSteps.relearning,
                stepIndex: 0,
                addLapse: true,
                forceRepetition: 0
            )
        }

        let previousState = SM2Result(
            repetition: card.repetition,
            interval: card.interval,
            easinessFactor: card.easinessFactor,
            nextReviewDate: card.nextReviewDate,
            lapses: card.lapses
        )

        let result = engine.review(
            previous: previousState,
            quality: quality,
            reviewDate: reviewDate
        )

        return SchedulingOutcome(
            result: result,
            learningState: .review,
            learningMode: .none,
            learningStepIndex: nil
        )
    }

    private func startStep(
        card: Card,
        reviewDate: Date,
        mode: CardLearningMode,
        steps: [TimeInterval],
        stepIndex: Int,
        addLapse: Bool,
        forceRepetition: Int? = nil
    ) -> SchedulingOutcome {
        let safeIndex = min(max(stepIndex, 0), max(steps.count - 1, 0))
        let seconds = steps[safeIndex]
        let nextDate = reviewDate.addingTimeInterval(seconds)
        let lapses = addLapse ? card.lapses + 1 : card.lapses
        let repetition = forceRepetition ?? card.repetition

        return SchedulingOutcome(
            result: SM2Result(
                repetition: repetition,
                interval: 0,
                easinessFactor: card.easinessFactor,
                nextReviewDate: nextDate,
                lapses: lapses
            ),
            learningState: mode == .relearning ? .relearning : .learning,
            learningMode: mode,
            learningStepIndex: safeIndex
        )
    }

    private func graduateToReview(
        card: Card,
        reviewDate: Date,
        intervalDays: Int,
        repetition: Int
    ) -> SchedulingOutcome {
        let nextReviewDate = reviewDate.addingTimeInterval(TimeInterval(intervalDays) * 24 * 60 * 60)
        return SchedulingOutcome(
            result: SM2Result(
                repetition: repetition,
                interval: intervalDays,
                easinessFactor: card.easinessFactor,
                nextReviewDate: nextReviewDate,
                lapses: card.lapses
            ),
            learningState: .review,
            learningMode: .none,
            learningStepIndex: nil
        )
    }

    private func defaultXPEventType(for quality: ReviewQuality) -> XPEventType {
        switch quality {
        case .again:
            return .reviewAgain
        case .hard:
            return .reviewHard
        case .good:
            return .reviewGood
        case .easy:
            return .reviewEasy
        }
    }
}
