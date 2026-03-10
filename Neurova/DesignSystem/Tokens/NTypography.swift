import SwiftUI

enum NTypography {
    static let display = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodyEmphasis = Font.system(size: 16, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let micro = Font.system(size: 11, weight: .regular, design: .rounded)
}

// Ejemplo: Text("Neurova").font(NTypography.display)
