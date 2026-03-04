import Foundation

protocol SpacedRepetitionEngine: Sendable {
    func review(
        previous: SM2Result?,
        quality: ReviewQuality,
        reviewDate: Date
    ) -> SM2Result
}
