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
        static let secondaryBackgroundPressed = Surface.raised
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
