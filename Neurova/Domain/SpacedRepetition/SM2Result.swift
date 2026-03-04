import Foundation

struct SM2Result: Equatable, Sendable {
    let repetition: Int
    let interval: Int
    let easinessFactor: Double
    let nextReviewDate: Date
    let lapses: Int
}
