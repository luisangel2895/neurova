import SwiftUI

enum NColors {
    struct SubjectIconOption: Identifiable, Hashable {
        let token: String
        let color: Color
        var id: String { token }
    }

    enum Home {
        static let backgroundLightTop = Color(red: 0.93, green: 0.93, blue: 0.95)
        static let backgroundLightBottom = Color(red: 0.92, green: 0.92, blue: 0.94)
        static let backgroundDarkTop = Color(red: 0.07, green: 0.08, blue: 0.13)
        static let backgroundDarkBottom = Color(red: 0.06, green: 0.07, blue: 0.12)
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
        static let neuroBlue = Color(red: 0.30, green: 0.53, blue: 0.94)
        static let neuroBlueDeep = Color(red: 0.45, green: 0.34, blue: 0.90)
        static let neuralMint = Color(red: 0.39, green: 0.27, blue: 0.82)
    }

    enum Neutrals {
        static let background = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.07, green: 0.08, blue: 0.13, alpha: 1)
                    : UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1)
            }
        )
        static let surface = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.10, green: 0.11, blue: 0.17, alpha: 1)
                    : UIColor(red: 0.88, green: 0.89, blue: 0.92, alpha: 1)
            }
        )
        static let surfaceAlt = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.13, blue: 0.20, alpha: 1)
                    : UIColor(red: 0.84, green: 0.86, blue: 0.91, alpha: 1)
            }
        )
        static let border = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.17, green: 0.19, blue: 0.30, alpha: 1)
                    : UIColor(red: 0.79, green: 0.80, blue: 0.85, alpha: 1)
            }
        )
    }

    enum Text {
        static let textPrimary = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1)
                    : UIColor(red: 0.06, green: 0.08, blue: 0.15, alpha: 1)
            }
        )
        static let textSecondary = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.63, green: 0.67, blue: 0.77, alpha: 1)
                    : UIColor(red: 0.26, green: 0.30, blue: 0.39, alpha: 1)
            }
        )
        static let textTertiary = Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.48, green: 0.52, blue: 0.63, alpha: 1)
                    : UIColor(red: 0.42, green: 0.46, blue: 0.54, alpha: 1)
            }
        )
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
