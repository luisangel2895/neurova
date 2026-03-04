import SwiftUI

struct SummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let summary: SessionSummary
    let onBackToDeck: () -> Void
    let onStudyAgain: () -> Void

    var body: some View {
        VStack(spacing: NSpacing.lg) {
            Spacer(minLength: 0)

            VStack(spacing: NSpacing.sm) {
                Text(AppCopy.text(locale, en: "Session Complete", es: "Sesion Completada"))
                    .font(NTypography.title.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(AppCopy.text(locale, en: "Great work today.", es: "Gran trabajo hoy."))
                    .font(NTypography.body)
                    .foregroundStyle(secondaryTextColor)
            }

            NImages.Mascot.neruMinimal
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            VStack(spacing: NSpacing.xs) {
                Text("\(summary.xpEarned) XP")
                    .font(NTypography.display)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(AppCopy.text(locale, en: "earned this session", es: "ganado en esta sesion"))
                    .font(NTypography.body)
                    .foregroundStyle(secondaryTextColor)
            }

            NCard {
                VStack(spacing: NSpacing.md) {
                    statsRow(title: AppCopy.text(locale, en: "Cards reviewed", es: "Tarjetas revisadas"), value: "\(summary.totalReviewed)")
                    statsRow(title: AppCopy.text(locale, en: "Correct", es: "Correctas"), value: "\(summary.correctCount)")
                    statsRow(title: AppCopy.text(locale, en: "Incorrect", es: "Incorrectas"), value: "\(summary.wrongCount)")
                    statsRow(title: AppCopy.text(locale, en: "Duration", es: "Duracion"), value: durationText)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: NSpacing.sm) {
                NPrimaryButton(AppCopy.text(locale, en: "Back to Deck", es: "Volver al Mazo")) {
                    onBackToDeck()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Study Again", es: "Estudiar de Nuevo")) {
                    onStudyAgain()
                }
            }
        }
        .padding(.horizontal, NSpacing.md + NSpacing.xs)
        .padding(.top, NSpacing.xl)
        .padding(.bottom, NSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView.ignoresSafeArea())
    }

    private func statsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(NTypography.body)
                .foregroundStyle(secondaryTextColor)

            Spacer(minLength: 0)

            Text(value)
                .font(NTypography.bodyEmphasis.weight(.semibold))
                .foregroundStyle(NColors.Text.textPrimary)
        }
    }

    private var durationText: String {
        let minutes = max(1, Int(round(Double(summary.durationSeconds) / 60.0)))
        if AppCopy.language(for: locale) == .spanish {
            return "\(minutes) min"
        }
        return "\(minutes) min"
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
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
            xpEarned: 45,
            totalReviewed: 5,
            correctCount: 4,
            wrongCount: 1,
            durationSeconds: 420
        ),
        onBackToDeck: {},
        onStudyAgain: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Summary Dark") {
    SummaryView(
        summary: SessionSummary(
            xpEarned: 45,
            totalReviewed: 5,
            correctCount: 4,
            wrongCount: 1,
            durationSeconds: 420
        ),
        onBackToDeck: {},
        onStudyAgain: {}
    )
    .preferredColorScheme(.dark)
}
