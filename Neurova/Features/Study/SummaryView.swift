import SwiftUI

struct SummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let summary: SessionSummary
    let onBackToDeck: () -> Void
    let onStudyAgain: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            NImages.Mascot.neruCelebrate
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)

            VStack(spacing: 6) {
                Text(AppCopy.text(locale, en: "Session complete!", es: "¡Sesión completada!"))
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(maxWidth: 320)

                Text(
                    AppCopy.text(
                        locale,
                        en: "You reviewed \(summary.totalReviewed) cards. Great job!",
                        es: "Revisaste \(summary.totalReviewed) tarjetas. ¡Excelente trabajo!"
                    )
                )
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(secondaryTextColor)
            }

            HStack(spacing: 12) {
                statCard(
                    icon: "bolt",
                    title: "+\(summary.xpEarned) XP",
                    subtitle: AppCopy.text(locale, en: "XP earned", es: "Experiencia ganada"),
                    tint: Color.orange
                )
                statCard(
                    icon: "clock",
                    title: durationTextLong,
                    subtitle: AppCopy.text(locale, en: "Study time", es: "Tiempo de estudio"),
                    tint: NColors.Brand.neuroBlue,
                    isHighlighted: true
                )
            }
            .padding(.top, 4)

            Spacer(minLength: 0)

            NGradientButton(
                AppCopy.text(locale, en: "Continue", es: "Continuar"),
                animateEffects: true
            ) {
                onBackToDeck()
            }
        }
        .padding(.horizontal, NSpacing.md + NSpacing.xs)
        .padding(.top, 22)
        .padding(.bottom, 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView.ignoresSafeArea())
    }

    private func statCard(icon: String, title: String, subtitle: String, tint: Color, isHighlighted: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                isHighlighted
                    ? NColors.Summary.highlightedBackground
                    : NColors.Summary.defaultBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isHighlighted
                            ? NColors.Summary.highlightedBorder
                            : NColors.Summary.defaultBorder,
                        lineWidth: 1
                    )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 104)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)

                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 8)
            }
    }

    private var durationTextLong: String {
        let totalSeconds = max(0, summary.durationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    private var secondaryTextColor: Color {
        NColors.Text.textSecondary
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Summary Light") {
    SummaryView(
        summary: SessionSummary(
            xpEarned: 30,
            totalReviewed: 3,
            correctCount: 3,
            wrongCount: 0,
            durationSeconds: 83
        ),
        onBackToDeck: {},
        onStudyAgain: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Summary Dark") {
    SummaryView(
        summary: SessionSummary(
            xpEarned: 30,
            totalReviewed: 3,
            correctCount: 3,
            wrongCount: 0,
            durationSeconds: 83
        ),
        onBackToDeck: {},
        onStudyAgain: {}
    )
    .preferredColorScheme(.dark)
}
