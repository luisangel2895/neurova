import SwiftUI

enum NColors {
    enum Brand {
        static let neuroBlue = dynamicColor(light: .systemBlue, dark: .systemCyan)
        static let neuroBlueDeep = dynamicColor(
            light: UIColor(red: 0.07, green: 0.20, blue: 0.52, alpha: 1.0),
            dark: UIColor(red: 0.16, green: 0.31, blue: 0.72, alpha: 1.0)
        )
        static let neuralMint = dynamicColor(
            light: UIColor(red: 0.20, green: 0.78, blue: 0.67, alpha: 1.0),
            dark: UIColor(red: 0.33, green: 0.90, blue: 0.78, alpha: 1.0)
        )
    }

    enum Neutrals {
        static let background = dynamicColor(light: .white, dark: .black)
        static let surface = dynamicColor(light: .systemGray6, dark: .systemGray5)
        static let surfaceAlt = dynamicColor(light: .systemGray5, dark: .systemGray4)
        static let border = dynamicColor(light: .systemGray4, dark: .systemGray3)
    }

    enum Text {
        static let textPrimary = dynamicColor(light: .label, dark: .label)
        static let textSecondary = dynamicColor(light: .secondaryLabel, dark: .secondaryLabel)
        static let textTertiary = dynamicColor(light: .tertiaryLabel, dark: .tertiaryLabel)
    }

    enum Feedback {
        static let success = dynamicColor(light: .systemGreen, dark: .systemGreen)
        static let warning = dynamicColor(light: .systemOrange, dark: .systemOrange)
        static let danger = dynamicColor(light: .systemRed, dark: .systemRed)
    }

    static let neuroGradient = LinearGradient(
        colors: [Brand.neuroBlue, Brand.neuralMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// Ejemplo: Text("CTA").foregroundStyle(NColors.Text.textPrimary)
