import SwiftUI

struct SummaryView: View {
    @Environment(\.colorScheme) private var colorScheme

    let summary: SessionSummary
    let onBackToDeck: () -> Void
    let onStudyAgain: () -> Void

    var body: some View {
        VStack(spacing: NSpacing.lg) {
            Spacer(minLength: 0)

            VStack(spacing: NSpacing.sm) {
                Text("Session Complete")
                    .font(NTypography.title.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text("Great work today.")
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

                Text("earned this session")
                    .font(NTypography.body)
                    .foregroundStyle(secondaryTextColor)
            }

            NCard {
                VStack(spacing: NSpacing.md) {
                    statsRow(title: "Cards reviewed", value: "\(summary.totalReviewed)")
                    statsRow(title: "Correct", value: "\(summary.correctCount)")
                    statsRow(title: "Incorrect", value: "\(summary.wrongCount)")
                    statsRow(title: "Duration", value: durationText)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: NSpacing.sm) {
                NPrimaryButton("Back to Deck") {
                    onBackToDeck()
                }

                NSecondaryButton("Study Again") {
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
