import Foundation

enum CardLearningState: String, Sendable {
    case new
    case learning
    case review
    case relearning
}

enum CardLearningMode: String, Sendable {
    case none
    case learning
    case relearning
}
