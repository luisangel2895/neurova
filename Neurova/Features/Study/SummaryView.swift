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
                    .frame(width: UIScreen.main.bounds.width * 0.8)

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

            SummaryGradientButton(
                title: AppCopy.text(locale, en: "Continue", es: "Continuar")
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
                    ? (colorScheme == .light ? Color(red: 0.87, green: 0.90, blue: 0.97) : Color(red: 0.11, green: 0.14, blue: 0.24))
                    : (colorScheme == .light ? Color(red: 0.89, green: 0.90, blue: 0.93) : Color(red: 0.10, green: 0.12, blue: 0.19))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isHighlighted
                            ? (colorScheme == .light ? Color(red: 0.67, green: 0.76, blue: 0.95) : Color(red: 0.18, green: 0.35, blue: 0.70))
                            : (colorScheme == .light ? Color(red: 0.80, green: 0.84, blue: 0.93) : Color.white.opacity(0.10)),
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
        colorScheme == .light
            ? Color(red: 0.42, green: 0.46, blue: 0.54)
            : Color(red: 0.45, green: 0.49, blue: 0.60)
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

private struct SummaryGradientButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color(red: 0.05, green: 0.08, blue: 0.16) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.30, green: 0.63, blue: 0.95), Color(red: 0.50, green: 0.34, blue: 0.95)]
                            : [Color(red: 0.24, green: 0.50, blue: 0.90), Color(red: 0.30, green: 0.46, blue: 0.87), Color(red: 0.39, green: 0.27, blue: 0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                TimelineView(.animation) { timeline in
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let tickTime = timeline.date.timeIntervalSinceReferenceDate
                        let phase = (tickTime / 2.15).truncatingRemainder(dividingBy: 1.0)
                        let shinePhase = -1.45 + (2.9 * phase)
                        let xOffset = width * shinePhase

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.clear)
                            .overlay(
                                Ellipse()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .clear,
                                                Color.white.opacity(0.10),
                                                Color.white.opacity(0.30),
                                                Color.white.opacity(0.10),
                                                .clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 188, height: 126)
                                    .rotationEffect(.degrees(20))
                                    .blur(radius: 9)
                                    .offset(x: xOffset)
                            )
                            .blendMode(.screen)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
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
