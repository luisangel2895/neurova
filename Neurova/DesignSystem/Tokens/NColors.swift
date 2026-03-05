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
            .init(token: "IconAzure", color: Color("IconAzure")),
            .init(token: "IconCobalt", color: Color("IconCobalt")),
            .init(token: "IconIndigo", color: Color("IconIndigo")),
            .init(token: "IconViolet", color: Color("IconViolet")),
            .init(token: "IconMagenta", color: Color("IconMagenta")),
            .init(token: "IconRose", color: Color("IconRose")),
            .init(token: "IconCoral", color: Color("IconCoral")),
            .init(token: "IconTangerine", color: Color("IconTangerine")),
            .init(token: "IconAmber", color: Color("IconAmber")),
            .init(token: "IconGold", color: Color("IconGold")),
            .init(token: "IconLime", color: Color("IconLime")),
            .init(token: "IconEmerald", color: Color("IconEmerald")),
            .init(token: "IconMint", color: Color("IconMint")),
            .init(token: "IconTeal", color: Color("IconTeal")),
            .init(token: "IconCyan", color: Color("IconCyan")),
            .init(token: "IconSky", color: Color("IconSky")),
            .init(token: "IconSteel", color: Color("IconSteel")),
            .init(token: "IconLavender", color: Color("IconLavender")),
            .init(token: "IconPlum", color: Color("IconPlum")),
            .init(token: "IconBerry", color: Color("IconBerry")),
            .init(token: "IconCrimson", color: Color("IconCrimson")),
            .init(token: "IconSalmon", color: Color("IconSalmon")),
            .init(token: "IconPeach", color: Color("IconPeach")),
            .init(token: "IconSand", color: Color("IconSand")),
            .init(token: "IconOlive", color: Color("IconOlive")),
            .init(token: "IconForest", color: Color("IconForest")),
            .init(token: "IconTurquoise", color: Color("IconTurquoise")),
            .init(token: "IconOcean", color: Color("IconOcean")),
            .init(token: "IconSlate", color: Color("IconSlate")),
            .init(token: "IconGraphite", color: Color("IconGraphite"))
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
