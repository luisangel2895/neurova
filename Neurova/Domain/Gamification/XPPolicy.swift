import Foundation

protocol XPPolicy {
    func xpDelta(for eventType: XPEventType) -> Int
}

struct DefaultXPPolicy: XPPolicy {
    func xpDelta(for eventType: XPEventType) -> Int {
        switch eventType {
        case .reviewAgain:
            return 0
        case .reviewHard, .skipHard, .autoHardTimeout:
            return 5
        case .reviewGood:
            return 10
        case .reviewEasy:
            return 15
        }
    }
}
