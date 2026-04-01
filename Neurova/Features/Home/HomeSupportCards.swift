import SwiftUI

struct HomeCompactStatCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let stat: QuickStat
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: stat.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(stat.iconColor)

            Text(stat.value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(NColors.Text.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? NColors.Surface.base.opacity(0.86) : Color.white.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : NColors.Stroke.standard.opacity(0.46), lineWidth: 1)
        )
    }
}

struct HomeTipCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let locale: Locale
    let title: String
    let message: String

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : NColors.Stroke.standard.opacity(0.50), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 136)
            .overlay(alignment: .leading) {
                HStack(alignment: .center, spacing: 14) {
                    NImages.Mascot.neruHappy
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text(message)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(NColors.Text.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            tipChip(AppCopy.text(locale, en: "PRODUCTIVITY", es: "PRODUCTIVIDAD"))
                            tipChip("POMODORO")
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 17)
            }
    }

    private var cardBackground: some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        NColors.Surface.base.opacity(0.88),
                        NColors.Brand.neuroBlue.opacity(0.06),
                        NColors.Brand.neuroBlueDeep.opacity(0.08)
                    ]
                    : [
                        Color.white.opacity(0.82),
                        NColors.Surface.base.opacity(0.94),
                        NColors.Brand.neuroBlueDeep.opacity(0.05)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func tipChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(NColors.Brand.accentBlue)
            .padding(.horizontal, 10)
            .frame(height: 20)
            .background(
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? NColors.Surface.accentSoft.opacity(0.34) : NColors.Surface.accentSoft.opacity(0.78))
            )
    }
}

extension Animation {
    static func homeExpo(duration: Double, delay: Double = 0) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration).delay(delay)
    }

    static func homeSpring(delay: Double = 0, stiffness: Double = 300, damping: Double = 22) -> Animation {
        .interpolatingSpring(stiffness: stiffness, damping: damping).delay(delay)
    }
}
