import Foundation
import SwiftData

@Model
final class XPStatsEntity {
    @Attribute(.unique) var key: String = "global"
    var totalXP: Int = 0

    init(key: String = "global", totalXP: Int = 0) {
        self.key = key
        self.totalXP = totalXP
    }
}
