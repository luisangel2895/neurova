import SwiftUI
import UIKit

enum NColors {
    private struct RGBA {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    struct SubjectIconOption: Identifiable, Hashable {
        let token: String
        let color: Color
        var id: String { token }
    }

    private static func dynamicColor(
        light: RGBA,
        dark: RGBA
    ) -> Color {
        Color(
            UIColor { trait in
                let values = trait.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: values.red,
                    green: values.green,
                    blue: values.blue,
                    alpha: values.alpha
                )
            }
        )
    }

    enum App {
        static let backgroundTop = NColors.dynamicColor(
            light: RGBA(0.93, 0.93, 0.95),
            dark: RGBA(0.04, 0.05, 0.11)
        )
        static let backgroundBottom = NColors.dynamicColor(
            light: RGBA(0.92, 0.92, 0.94),
            dark: RGBA(0.03, 0.04, 0.09)
        )
    }

    enum Surface {
        static let base = NColors.dynamicColor(
            light: RGBA(0.88, 0.89, 0.92),
            dark: RGBA(0.08, 0.10, 0.18)
        )
        static let raised = NColors.dynamicColor(
            light: RGBA(0.84, 0.86, 0.91),
            dark: RGBA(0.10, 0.12, 0.20)
        )
        static let subdued = NColors.dynamicColor(
            light: RGBA(0.86, 0.87, 0.90),
            dark: RGBA(0.10, 0.12, 0.20)
        )
        static let emphasized = NColors.dynamicColor(
            light: RGBA(0.80, 0.83, 0.90),
            dark: RGBA(0.11, 0.16, 0.28)
        )
        static let accentSoft = NColors.dynamicColor(
            light: RGBA(0.84, 0.87, 0.93),
            dark: RGBA(0.07, 0.13, 0.24)
        )
        static let accentBadge = NColors.dynamicColor(
            light: RGBA(0.80, 0.86, 0.97),
            dark: RGBA(0.11, 0.17, 0.31)
        )
    }

    enum Stroke {
        static let subtle = NColors.dynamicColor(
            light: RGBA(0.79, 0.80, 0.85, 0.90),
            dark: RGBA(1.00, 1.00, 1.00, 0.06)
        )
        static let standard = NColors.dynamicColor(
            light: RGBA(0.79, 0.80, 0.85, 0.90),
            dark: RGBA(1.00, 1.00, 1.00, 0.08)
        )
        static let strong = NColors.dynamicColor(
            light: RGBA(0.75, 0.79, 0.89),
            dark: RGBA(0.16, 0.27, 0.46)
        )
        static let selection = NColors.dynamicColor(
            light: RGBA(0.26, 0.50, 0.91),
            dark: RGBA(0.25, 0.55, 0.98)
        )
        static let inputActive = NColors.dynamicColor(
            light: RGBA(0.30, 0.51, 0.92),
            dark: RGBA(0.25, 0.55, 0.98)
        )
    }

    enum Text {
        static let textPrimary = NColors.dynamicColor(
            light: RGBA(0.06, 0.08, 0.15),
            dark: RGBA(0.93, 0.95, 0.99)
        )
        static let textSecondary = NColors.dynamicColor(
            light: RGBA(0.39, 0.43, 0.52),
            dark: RGBA(0.34, 0.40, 0.53)
        )
        static let textTertiary = NColors.dynamicColor(
            light: RGBA(0.40, 0.44, 0.53),
            dark: RGBA(0.53, 0.58, 0.70)
        )
        static let onAccent = NColors.dynamicColor(
            light: RGBA(1.00, 1.00, 1.00),
            dark: RGBA(0.05, 0.08, 0.16)
        )
    }

    enum Brand {
        static let neuroBlue = Color(red: 0.30, green: 0.53, blue: 0.94)
        static let neuroBlueDeep = Color(red: 0.45, green: 0.34, blue: 0.90)
        static let neuralMint = Color(red: 0.39, green: 0.27, blue: 0.82)
        static let accentBlue = NColors.dynamicColor(
            light: RGBA(0.36, 0.55, 0.92),
            dark: RGBA(0.31, 0.59, 0.98)
        )
        static let accentBlueStrong = NColors.dynamicColor(
            light: RGBA(0.41, 0.61, 0.94),
            dark: RGBA(0.37, 0.64, 0.97)
        )
        static let primaryButtonLight = [
            Color(red: 0.24, green: 0.50, blue: 0.90),
            Color(red: 0.30, green: 0.46, blue: 0.87),
            Color(red: 0.39, green: 0.27, blue: 0.82)
        ]
        static let primaryButtonDark = [
            Color(red: 0.30, green: 0.63, blue: 0.95),
            Color(red: 0.40, green: 0.49, blue: 0.96),
            Color(red: 0.50, green: 0.34, blue: 0.95)
        ]

        static func primaryButtonColors(for colorScheme: ColorScheme) -> [Color] {
            colorScheme == .dark ? primaryButtonDark : primaryButtonLight
        }
    }

    enum Button {
        static let primaryText = Text.onAccent
        static let secondaryText = Brand.neuroBlue
        static let secondaryBackground = Surface.base
        static let secondaryBorder = Stroke.subtle
        static let chipBackground = Surface.subdued
        static let chipSelectedBackground = Surface.emphasized
        static let chipSelectedBorder = Stroke.selection
    }

    enum Field {
        static let background = Surface.base
        static let border = Stroke.subtle
        static let activeBorder = Stroke.inputActive
    }

    enum Study {
        static let headerIconBackground = dynamicColor(
            light: RGBA(0.89, 0.91, 0.97),
            dark: RGBA(0.10, 0.16, 0.28)
        )
        static let counterBackground = dynamicColor(
            light: RGBA(0.94, 0.94, 0.96),
            dark: RGBA(0.12, 0.14, 0.22)
        )
        static let closeButtonBackground = dynamicColor(
            light: RGBA(0.92, 0.92, 0.95),
            dark: RGBA(0.12, 0.14, 0.22)
        )
        static let closeButtonForeground = dynamicColor(
            light: RGBA(0.45, 0.49, 0.57),
            dark: RGBA(0.58, 0.62, 0.72)
        )
        static let progressTrack = dynamicColor(
            light: RGBA(0.82, 0.83, 0.86),
            dark: RGBA(0.17, 0.19, 0.28)
        )
        static let progressFill = LinearGradient(
            colors: [Brand.neuroBlue, Brand.neuroBlueDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let cardSideText = dynamicColor(
            light: RGBA(0.30, 0.54, 0.94),
            dark: RGBA(0.33, 0.62, 0.98)
        )
        static let cardSideBackground = dynamicColor(
            light: RGBA(0.90, 0.93, 0.98),
            dark: RGBA(0.16, 0.18, 0.27)
        )
        static let reviewHard = Color(red: 0.86, green: 0.35, blue: 0.35)
        static let reviewGood = Color(red: 0.26, green: 0.49, blue: 0.89)
        static let reviewEasy = Color(red: 0.30, green: 0.69, blue: 0.37)
        static let selectedShadow = dynamicColor(
            light: RGBA(0.30, 0.53, 0.94, 0.12),
            dark: RGBA(0.30, 0.53, 0.94, 0.18)
        )
        static let cardShadowDark = Color.white.opacity(0.04)
    }

    enum Summary {
        static let highlightedBackground = dynamicColor(
            light: RGBA(0.87, 0.90, 0.97),
            dark: RGBA(0.11, 0.14, 0.24)
        )
        static let defaultBackground = dynamicColor(
            light: RGBA(0.89, 0.90, 0.93),
            dark: RGBA(0.10, 0.12, 0.19)
        )
        static let highlightedBorder = dynamicColor(
            light: RGBA(0.67, 0.76, 0.95),
            dark: RGBA(0.18, 0.35, 0.70)
        )
        static let defaultBorder = dynamicColor(
            light: RGBA(0.80, 0.84, 0.93),
            dark: RGBA(1.00, 1.00, 1.00, 0.10)
        )
    }

    enum Splash {
        static let lightBackground = [
            Color(red: 0.97, green: 0.98, blue: 1.00),
            Color(red: 0.95, green: 0.96, blue: 0.99),
            Color(red: 0.97, green: 0.98, blue: 1.00)
        ]
        static let lightGlow = [
            Color.white.opacity(0.88),
            Color(red: 0.90, green: 0.94, blue: 1.0).opacity(0.36),
            Color.clear
        ]
        static let lightParticleGradient = [
            Color(red: 0.29, green: 0.86, blue: 0.75),
            Color(red: 0.22, green: 0.50, blue: 0.92)
        ]
        static let lightTrack = Color(red: 0.85, green: 0.87, blue: 0.91).opacity(0.78)
        static let lightLabel = Color(red: 0.35, green: 0.39, blue: 0.48).opacity(0.88)
        static let lightLogoShadow = Color(red: 0.17, green: 0.33, blue: 0.72).opacity(0.22)
        static let lightProgressShadow = Color(red: 0.22, green: 0.50, blue: 0.92).opacity(0.24)

        static let darkBase = Color(red: 0.02, green: 0.03, blue: 0.09)
        static let darkOverlay = [
            Color(red: 0.07, green: 0.10, blue: 0.22).opacity(0.26),
            Color(red: 0.03, green: 0.04, blue: 0.10).opacity(0.0)
        ]
        static let darkPrimaryGlow = [
            Color(red: 0.20, green: 0.39, blue: 0.96).opacity(0.17),
            Color(red: 0.15, green: 0.30, blue: 0.74).opacity(0.09),
            Color(red: 0.09, green: 0.18, blue: 0.44).opacity(0.03),
            Color.clear
        ]
        static let darkSecondaryGlow = [
            Color(red: 0.28, green: 0.44, blue: 0.98).opacity(0.07),
            Color.clear
        ]
        static let darkParticleGradient = [
            Color(red: 0.19, green: 0.86, blue: 0.96),
            Color(red: 0.45, green: 0.30, blue: 0.95)
        ]
        static let darkTrack = Color.white.opacity(0.12)
        static let darkLabel = Color.white.opacity(0.62)
        static let darkLogoShadow = Color(red: 0.22, green: 0.40, blue: 0.95).opacity(0.20)
        static let darkProgressShadow = Color(red: 0.29, green: 0.53, blue: 0.98).opacity(0.34)
    }

    enum Recovery {
        static let backgroundLight = [
            Color(red: 0.96, green: 0.96, blue: 0.98),
            Color(red: 0.94, green: 0.95, blue: 0.98),
            Color(red: 0.93, green: 0.94, blue: 0.97)
        ]
        static let backgroundDark = [
            Color(red: 0.04, green: 0.07, blue: 0.15),
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.03, green: 0.05, blue: 0.12)
        ]
        static let iconTint = dynamicColor(
            light: RGBA(0.38, 0.58, 0.96),
            dark: RGBA(0.47, 0.70, 1.0)
        )
        static let iconBackground = dynamicColor(
            light: RGBA(0.85, 0.90, 0.99),
            dark: RGBA(1.00, 1.00, 1.00, 0.07)
        )
        static let title = dynamicColor(
            light: RGBA(0.08, 0.10, 0.16),
            dark: RGBA(1.00, 1.00, 1.00, 0.98)
        )
        static let body = dynamicColor(
            light: RGBA(0.36, 0.40, 0.49),
            dark: RGBA(0.66, 0.72, 0.84)
        )
        static let eyebrow = dynamicColor(
            light: RGBA(0.41, 0.45, 0.54),
            dark: RGBA(1.00, 1.00, 1.00, 0.56)
        )
        static let cardBackgroundTop = dynamicColor(
            light: RGBA(0.90, 0.91, 0.95),
            dark: RGBA(1.00, 1.00, 1.00, 0.08)
        )
        static let cardBackgroundBottom = dynamicColor(
            light: RGBA(0.84, 0.86, 0.92),
            dark: RGBA(0.15, 0.24, 0.43, 0.28)
        )
        static let cardBorder = dynamicColor(
            light: RGBA(1.00, 1.00, 1.00, 0.42),
            dark: RGBA(1.00, 1.00, 1.00, 0.07)
        )
        static let pillBackground = dynamicColor(
            light: RGBA(1.00, 1.00, 1.00, 0.50),
            dark: RGBA(0.00, 0.00, 0.00, 0.28)
        )
        static let pillBorder = dynamicColor(
            light: RGBA(1.00, 1.00, 1.00, 0.56),
            dark: RGBA(1.00, 1.00, 1.00, 0.06)
        )
        static let name = dynamicColor(
            light: RGBA(0.12, 0.14, 0.20),
            dark: RGBA(1.00, 1.00, 1.00, 0.96)
        )
        static let email = dynamicColor(
            light: RGBA(0.46, 0.49, 0.58),
            dark: RGBA(1.00, 1.00, 1.00, 0.52)
        )
        static let footnote = dynamicColor(
            light: RGBA(0.56, 0.59, 0.67),
            dark: RGBA(1.00, 1.00, 1.00, 0.28)
        )
        static let lightButton = [
            Color(red: 0.17, green: 0.52, blue: 0.90),
            Color(red: 0.43, green: 0.24, blue: 0.86)
        ]
        static let darkButton = [
            Color(red: 0.19, green: 0.72, blue: 0.97),
            Color(red: 0.50, green: 0.27, blue: 0.95)
        ]
        static let buttonText = dynamicColor(
            light: RGBA(1.00, 1.00, 1.00),
            dark: RGBA(0.08, 0.12, 0.22)
        )
        static let logoShadow = dynamicColor(
            light: RGBA(0.36, 0.47, 0.76, 0.22),
            dark: RGBA(0.22, 0.52, 0.96, 0.34)
        )
        static let avatarGradient = [
            Color(red: 0.29, green: 0.57, blue: 0.97),
            Color(red: 0.43, green: 0.33, blue: 0.95)
        ]
        static let avatarText = Color(red: 0.90, green: 0.93, blue: 1.0)
        static let buttonShadow = Color(red: 0.31, green: 0.43, blue: 0.96).opacity(0.30)

        static func buttonGradient(for colorScheme: ColorScheme) -> [Color] {
            colorScheme == .dark ? darkButton : lightButton
        }
    }

    enum Home {
        static let backgroundLightTop = App.backgroundTop
        static let backgroundLightBottom = App.backgroundBottom
        static let backgroundDarkTop = App.backgroundTop
        static let backgroundDarkBottom = App.backgroundBottom
        static let surfaceL0 = App.backgroundTop
        static let surfaceL1 = Surface.base
        static let surfaceL2 = Surface.raised
        static let secondaryTextLight = Text.textSecondary
        static let secondaryTextDark = Text.textSecondary
        static let cardBorder = Stroke.standard
        static let layeredStroke = Stroke.subtle
        static let cardInnerBorder = Color.white.opacity(0.04)
        static let cardTopHighlight = Color.white.opacity(0.06)
        static let cardShadowLight = Text.textSecondary.opacity(0.12)
        static let progressTrack = Surface.raised.opacity(0.96)
    }

    enum Neutrals {
        static let background = App.backgroundTop
        static let surface = Surface.base
        static let surfaceAlt = Surface.raised
        static let border = Stroke.standard
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
