import Foundation
@testable import Neurova

final class MockXPEventRepository: XPEventRepository {
    var recordedEvents: [XPEvent] = []
    var storedTotalXP: Int = 0
    var storedTodayXP: Int = 0
    var storedEventCount: Int = 0
    var storedActivityDays: [Date] = []
    var storedTodayReviewCount: Int = 0
    var eventsInRangeResult: [XPEvent] = []
    var shouldThrow = false

    func record(_ event: XPEvent) throws {
        if shouldThrow { throw MockError.forced }
        recordedEvents.append(event)
    }

    func events(in range: Range<Date>) throws -> [XPEvent] {
        if shouldThrow { throw MockError.forced }
        return eventsInRangeResult
    }

    func totalXP() throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedTotalXP
    }

    func totalEventCount() throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedEventCount
    }

    func todayXP(on date: Date, calendar: Calendar) throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedTodayXP
    }

    func activityDays(inLast numberOfDays: Int, endingOn date: Date, calendar: Calendar) throws -> [Date] {
        if shouldThrow { throw MockError.forced }
        return storedActivityDays
    }

    func todayReviewCount(on date: Date, calendar: Calendar) throws -> Int {
        if shouldThrow { throw MockError.forced }
        return storedTodayReviewCount
    }
}

enum MockError: Error {
    case forced
}
