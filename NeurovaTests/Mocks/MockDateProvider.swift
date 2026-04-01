import Foundation
@testable import Neurova

struct MockDateProvider: DateProvider {
    let now: Date
    let calendar: Calendar

    init(
        now: Date = Date(timeIntervalSinceReferenceDate: 0),
        calendar: Calendar = Calendar.current
    ) {
        self.now = now
        self.calendar = calendar
    }
}
