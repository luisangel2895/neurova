import Foundation
import SwiftData

@Model
final class XPStatsEntity {
    var key: String
    var totalXP: Int

    init(key: String = "global", totalXP: Int = 0) {
        self.key = key
        self.totalXP = totalXP
    }
}
