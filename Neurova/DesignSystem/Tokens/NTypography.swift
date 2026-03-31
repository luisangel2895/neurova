import SwiftUI

enum NTypography {
    // All fonts use semantic text styles for automatic Dynamic Type scaling.
    static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title, design: .rounded, weight: .semibold)
    static let headline = Font.system(.title3, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyEmphasis = Font.system(.body, design: .rounded, weight: .medium)
    static let caption = Font.system(.footnote, design: .rounded)
    static let micro = Font.system(.caption2, design: .rounded)
}
