import SwiftUI

enum NColors {
    struct SubjectIconOption: Identifiable, Hashable {
        let token: String
        let color: Color
        var id: String { token }
    }

    enum Home {
        static let backgroundLightTop = Neutrals.surface.opacity(0.96)
        static let backgroundLightBottom = Neutrals.background
        static let backgroundDarkTop = Brand.neuroBlueDeep.opacity(0.28)
        static let backgroundDarkBottom = Neutrals.background
        static let surfaceL0 = Neutrals.background
        static let surfaceL1 = Neutrals.surface
        static let surfaceL2 = Neutrals.surfaceAlt
        static let secondaryTextLight = Text.textPrimary.opacity(0.58)
        static let secondaryTextDark = Text.textPrimary.opacity(0.72)
        static let cardBorder = Neutrals.border.opacity(0.74)
        static let layeredStroke = Neutrals.border.opacity(0.66)
        static let cardInnerBorder = Text.textPrimary.opacity(0.08)
        static let cardTopHighlight = Text.textPrimary.opacity(0.06)
        static let cardShadowLight = Text.textTertiary.opacity(0.1)
        static let progressTrack = surfaceL2.opacity(0.96)
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

    enum SubjectIcon {
        static let palette: [SubjectIconOption] = [
            .init(token: "NeuroBlue", color: Brand.neuroBlue),
            .init(token: "NeuroBlueDeep", color: Brand.neuroBlueDeep),
            .init(token: "NeuralMint", color: Brand.neuralMint),
            .init(token: "Success", color: Feedback.success),
            .init(token: "Warning", color: Feedback.warning),
            .init(token: "Danger", color: Feedback.danger),
            .init(token: "TextPrimary", color: Text.textPrimary),
            .init(token: "TextSecondary", color: Text.textSecondary)
        ]

        static func color(for tokenReference: String?) -> Color {
            guard
                let tokenReference,
                let option = palette.first(where: { $0.token.caseInsensitiveCompare(tokenReference) == .orderedSame })
            else {
                return Brand.neuroBlue
            }
            return option.color
        }
    }

    static let neuroGradient = LinearGradient(
        colors: [Brand.neuroBlue, Brand.neuralMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// Ejemplo: Text("CTA").foregroundStyle(NColors.Text.textPrimary)
