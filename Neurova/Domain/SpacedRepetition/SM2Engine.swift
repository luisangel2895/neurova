import Foundation

final class SM2Engine: SpacedRepetitionEngine {
    private enum Constants {
        static let minimumEasinessFactor = 1.3
        static let firstInterval = 1
        static let secondInterval = 6
    }

    func review(
        previous: SM2Result?,
        quality: ReviewQuality,
        reviewDate: Date
    ) -> SM2Result {
        let previousRepetition = previous?.repetition ?? 0
        let previousInterval = previous?.interval ?? 0
        let previousEasinessFactor = previous?.easinessFactor ?? 2.5
        let previousLapses = previous?.lapses ?? 0
        let score = quality.sm2Score

        let repetition: Int
        let interval: Int
        let lapses: Int
        let updatedEasinessFactor: Double

        if score < 3 {
            // On lapse, preserve the previous easiness factor per SM-2 spec
            updatedEasinessFactor = previousEasinessFactor
            repetition = 0
            interval = Constants.firstInterval
            lapses = previousLapses + 1
        } else {
            updatedEasinessFactor = max(
                Constants.minimumEasinessFactor,
                previousEasinessFactor + sm2Delta(for: score)
            )
            repetition = previousRepetition + 1
            lapses = previousLapses

            switch repetition {
            case 1:
                interval = Constants.firstInterval
            case 2:
                interval = Constants.secondInterval
            default:
                interval = max(
                    Constants.secondInterval,
                    Int((Double(previousInterval) * updatedEasinessFactor).rounded())
                )
            }
        }

        return SM2Result(
            repetition: repetition,
            interval: interval,
            easinessFactor: updatedEasinessFactor,
            nextReviewDate: nextReviewDate(from: reviewDate, interval: interval),
            lapses: lapses
        )
    }

    private func sm2Delta(for score: Int) -> Double {
        let quality = Double(score)
        return 0.1 - (5.0 - quality) * (0.08 + (5.0 - quality) * 0.02)
    }

    private func nextReviewDate(from reviewDate: Date, interval: Int) -> Date {
        guard let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: reviewDate) else {
            return reviewDate
        }

        return nextDate
    }
}
