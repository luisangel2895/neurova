import Foundation

protocol XPEventRepository {
    func record(_ event: XPEvent) throws
    func events(in range: Range<Date>) throws -> [XPEvent]
    func totalXP() throws -> Int
    func totalEventCount() throws -> Int
    func todayXP(on date: Date, calendar: Calendar) throws -> Int
    func activityDays(inLast numberOfDays: Int, endingOn date: Date, calendar: Calendar) throws -> [Date]
    func todayReviewCount(on date: Date, calendar: Calendar) throws -> Int
}
