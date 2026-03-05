import SwiftUI

struct StudyCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    let recommendations: [StudyDeckRecommendation]
    let onSelectDeck: (Deck) -> Void

    @State private var displayedMessage = ""
    @State private var typewriterTask: Task<Void, Never>?
    @State private var mascotOffsetX: CGFloat = -2

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    mascotHeader
                    recommendationsCard
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.vertical, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(AppCopy.text(locale, en: "Study Coach", es: "Coach de estudio"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppCopy.text(locale, en: "Close", es: "Cerrar")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                startTypewriter()
            }
            .onDisappear {
                typewriterTask?.cancel()
            }
        }
    }

    private var mascotHeader: some View {
        NCard {
            HStack(alignment: .top, spacing: NSpacing.sm) {
                NImages.Mascot.neruHappy
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .offset(x: mascotOffsetX)
                    .padding(.top, NSpacing.xs)

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Neru says", es: "Neru dice"))
                        .font(NTypography.micro.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(NColors.Text.textTertiary)

                    Text(displayedMessage)
                        .font(NTypography.bodyEmphasis)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 58, alignment: .topLeading)
                }
                .padding(.horizontal, NSpacing.sm)
                .padding(.vertical, NSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                        .fill(NColors.Neutrals.surfaceAlt)
                )
                .overlay(alignment: .leading) {
                    SpeechBubbleTail()
                        .fill(NColors.Neutrals.surfaceAlt)
                        .frame(width: 16, height: 20)
                        .offset(x: -12, y: 22)
                }
                .overlay(alignment: .leading) {
                    SpeechBubbleTail()
                        .stroke(NColors.Neutrals.border, lineWidth: 1)
                        .frame(width: 16, height: 20)
                        .offset(x: -12, y: 22)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                        .stroke(NColors.Neutrals.border, lineWidth: 1)
                )
            }
        }
    }

    private var recommendationsCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(AppCopy.text(locale, en: "Decks to review today", es: "Decks para repasar hoy"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                if recommendations.isEmpty {
                    Text(
                        AppCopy.text(
                            locale,
                            en: "You have no ready cards right now.",
                            es: "No tienes tarjetas listas ahora mismo."
                        )
                    )
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(recommendations) { recommendation in
                        Button {
                            onSelectDeck(recommendation.deck)
                            dismiss()
                        } label: {
                            HStack(spacing: NSpacing.sm) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(recommendation.accentColor)
                                    .frame(width: 16, height: 16)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recommendation.subjectPathText)
                                        .font(NTypography.caption.weight(.semibold))
                                        .foregroundStyle(NColors.Text.textPrimary)
                                        .lineLimit(1)

                                    Text(
                                        AppCopy.text(
                                            locale,
                                            en: "\(recommendation.readyCount) ready • \(recommendation.totalCards) total",
                                            es: "\(recommendation.readyCount) listas • \(recommendation.totalCards) total"
                                        )
                                    )
                                    .font(NTypography.micro)
                                    .foregroundStyle(NColors.Text.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(NColors.Text.textTertiary)
                            }
                            .padding(.horizontal, NSpacing.sm)
                            .padding(.vertical, NSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                    .fill(NColors.Neutrals.surfaceAlt)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var fullMessage: String {
        AppCopy.text(
            locale,
            en: "Today you have these decks ready to review. Let's keep your streak alive.",
            es: "Hoy tienes estos decks para repasar. Vamos a mantener tu racha."
        )
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func startTypewriter() {
        typewriterTask?.cancel()
        displayedMessage = ""
        mascotOffsetX = -2

        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            mascotOffsetX = 2
        }

        let message = fullMessage
        typewriterTask = Task { @MainActor in
            for character in message {
                if Task.isCancelled { return }
                displayedMessage.append(character)
                try? await Task.sleep(nanoseconds: 24_000_000)
            }
        }
    }
}

private struct SpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
