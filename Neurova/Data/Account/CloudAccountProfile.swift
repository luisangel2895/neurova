import Foundation
import SwiftData

@Model
final class CloudAccountProfile {
    var key: String = "primary"
    var appleUserID: String?
    var displayName: String?
    var email: String?
    var updatedAt: Date = Date()

    init(
        key: String = "primary",
        appleUserID: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.key = key
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.email = email
        self.updatedAt = updatedAt
    }
}
