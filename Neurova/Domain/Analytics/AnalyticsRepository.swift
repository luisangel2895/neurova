import Foundation

protocol AnalyticsRepository {
    func eventCountsByType(in range: Range<Date>) throws -> [XPEventType: Int]
    func eventCountsByDeck(in range: Range<Date>) throws -> [UUID: [XPEventType: Int]]
}
