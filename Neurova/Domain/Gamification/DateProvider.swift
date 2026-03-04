import Foundation

protocol DateProvider {
    var now: Date { get }
    var calendar: Calendar { get }
}

struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
    var calendar: Calendar { Calendar.current }
}

struct FixedDateProvider: DateProvider {
    let now: Date
    let calendar: Calendar
}
