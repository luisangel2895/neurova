import SwiftUI

struct HomeHeroCard: View {
    let locale: Locale
    let colorScheme: ColorScheme
    let completedCards: Int
    let goalCards: Int
    let progress: Double
    let showProgressNumber: Bool
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(heroTrackColor, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(
                        color: progressGlowColor,
                        radius: colorScheme == .dark ? 8 : 4,
                        x: 0,
                        y: 0
                    )

                VStack(spacing: 1) {
                    percentageText
                        .scaleEffect(showProgressNumber ? 1 : 0.5)
                        .opacity(showProgressNumber ? 1 : 0)

                    Text(AppCopy.text(locale, en: "GOAL", es: "META"))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(NColors.Text.textTertiary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .semibold))
                    Text(AppCopy.text(locale, en: "TODAY'S SESSION", es: "SESIÓN DE HOY"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.0)
                }
                .foregroundStyle(NColors.Text.textTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(completedCards)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text("/\(goalCards)")
                            .font(.system(size: 20, weight: .regular, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                    }

                    Text(AppCopy.text(locale, en: "cards completed", es: "tarjetas completadas"))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(NColors.Text.textSecondary)
                }

                NGradientButton(
                    actionTitle,
                    leadingSymbolName: "sparkles",
                    showsChevron: false,
                    animateEffects: true,
                    font: .system(size: 16, weight: .bold, design: .rounded),
                    height: 44,
                    cornerRadius: 14,
                    gradientColors: colorScheme == .dark
                        ? [NColors.Brand.accentBlueStrong, NColors.Brand.neuroBlueDeep]
                        : [
                            Color(red: 0.24, green: 0.50, blue: 0.90),
                            Color(red: 0.30, green: 0.46, blue: 0.87),
                            Color(red: 0.39, green: 0.27, blue: 0.82)
                        ]
                ) {
                    onAction()
                }
                .frame(width: 196, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 128)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(
            color: colorScheme == .dark
                ? NColors.Brand.neuroBlue.opacity(0.14)
                : NColors.Brand.neuroBlue.opacity(0.10),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    NColors.Surface.raised.opacity(0.94),
                    NColors.Brand.neuroBlue.opacity(0.16),
                    NColors.Brand.neuroBlueDeep.opacity(0.18)
                ]
                : [
                    Color(red: 0.90, green: 0.93, blue: 0.99).opacity(0.92),
                    Color(red: 0.82, green: 0.88, blue: 0.99).opacity(0.86),
                    Color(red: 0.79, green: 0.82, blue: 0.98).opacity(0.88),
                    Color(red: 0.82, green: 0.76, blue: 0.98).opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : NColors.Stroke.standard.opacity(0.48),
                lineWidth: 1
            )
    }

    private var heroTrackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.09)
            : NColors.Surface.subdued.opacity(0.82)
    }

    private var percentageText: some View {
        let percentage = Int((min(max(progress, 0), 1) * 100).rounded())
        let number = "\(percentage)"
        let suffix = "%"

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(number)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(suffix)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.30, green: 0.63, blue: 0.95),
                    Color(red: 0.40, green: 0.49, blue: 0.96),
                    Color(red: 0.50, green: 0.34, blue: 0.95),
                    Color(red: 0.30, green: 0.63, blue: 0.95)
                ]
                : [
                    Color(red: 0.24, green: 0.50, blue: 0.90),
                    Color(red: 0.30, green: 0.46, blue: 0.87),
                    Color(red: 0.39, green: 0.27, blue: 0.82),
                    Color(red: 0.24, green: 0.50, blue: 0.90)
                ],
            center: .center
        )
    }

    private var progressGlowColor: Color {
        colorScheme == .dark
            ? NColors.Brand.neuroBlue.opacity(0.30)
            : NColors.Brand.neuroBlue.opacity(0.16)
    }
}
