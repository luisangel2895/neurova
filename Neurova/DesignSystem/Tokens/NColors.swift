import SwiftUI

enum NColors {
    enum Home {
        static let backgroundLightTop = Neutrals.surface.opacity(0.92)
        static let backgroundLightBottom = Neutrals.background
        static let backgroundDarkTop = Brand.neuroBlueDeep.opacity(0.24)
        static let backgroundDarkBottom = Neutrals.background
        static let secondaryTextLight = Text.textSecondary.opacity(0.96)
        static let secondaryTextDark = Text.textSecondary
        static let cardBorder = Neutrals.border.opacity(0.78)
        static let cardInnerBorder = Text.textPrimary.opacity(0.08)
        static let cardTopHighlight = Text.textPrimary.opacity(0.06)
        static let progressTrack = Neutrals.surfaceAlt.opacity(0.96)
    }

    enum Brand {
        static let neuroBlue = Color("NeuroBlue")
        static let neuroBlueDeep = Color("NeuroBlueDeep")
        static let neuralMint = Color("NeuralMint")
    }

    enum Neutrals {
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let surfaceAlt = Color("SurfaceAlt")
        static let border = Color("Border")
    }

    enum Text {
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
    }

    enum Feedback {
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let danger = Color("Danger")
    }

    static let neuroGradient = LinearGradient(
        colors: [Brand.neuroBlue, Brand.neuralMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// Ejemplo: Text("CTA").foregroundStyle(NColors.Text.textPrimary)
