import Foundation

enum XPEventType: String, Sendable, CaseIterable {
    case reviewAgain
    case reviewHard
    case reviewGood
    case reviewEasy
    case skipHard
    case autoHardTimeout
}
