import Foundation
@testable import Neurova

final class MockAnalyticsRepository: AnalyticsRepository {
    var eventCountsByTypeResult: [XPEventType: Int] = [:]
    var eventCountsByDeckResult: [UUID: [XPEventType: Int]] = [:]
    var shouldThrow = false

    func eventCountsByType(in range: Range<Date>) throws -> [XPEventType: Int] {
        if shouldThrow { throw MockError.forced }
        return eventCountsByTypeResult
    }

    func eventCountsByDeck(in range: Range<Date>) throws -> [UUID: [XPEventType: Int]] {
        if shouldThrow { throw MockError.forced }
        return eventCountsByDeckResult
    }
}
