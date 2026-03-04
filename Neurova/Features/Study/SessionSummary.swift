import Foundation

struct SessionSummary: Equatable {
    let xpEarned: Int
    let totalReviewed: Int
    let correctCount: Int
    let wrongCount: Int
    let durationSeconds: Int
}
