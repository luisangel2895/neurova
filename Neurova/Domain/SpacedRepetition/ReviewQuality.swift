import Foundation

enum ReviewQuality: CaseIterable, Sendable {
    case again
    case hard
    case good
    case easy

    var sm2Score: Int {
        switch self {
        case .again:
            return 0
        case .hard:
            return 3
        case .good:
            return 4
        case .easy:
            return 5
        }
    }
}
