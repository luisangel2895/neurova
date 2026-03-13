import SwiftUI

struct StudyCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    let recommendations: [StudyDeckRecommendation]
    let onSelectDeck: (Deck) -> Void
    let onOpenLibrary: () -> Void

    @State private var displayedMessage = ""
    @State private var typewriterTask: Task<Void, Never>?
    @State private var mascotFloatY: CGFloat = 0
    @State private var showHero = false
    @State private var visibleRecommendationCount = 0
    @State private var recommendationAnimationTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    contentSection
                }
                .padding(.horizontal, NSpacing.md + 2)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppCopy.text(locale, en: "Study Coach", es: "Coach de estudio"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(NColors.Text.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(colorScheme == .light ? Color.white.opacity(0.92) : NColors.Neutrals.surfaceAlt)
                            )
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .onAppear {
                startTypewriter()
                startEntryAnimation()
            }
            .onDisappear {
                typewriterTask?.cancel()
                recommendationAnimationTask?.cancel()
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(heroGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(heroBorder, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 16) {
                    coachMascot
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                        .offset(y: mascotFloatY)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppCopy.text(locale, en: "NERU RECOMMENDS", es: "NERU RECOMIENDA"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(NColors.Text.textTertiary)

                        Text(recommendations.isEmpty ? AppCopy.text(locale, en: "You're all caught up", es: "Estás al día") : AppCopy.text(locale, en: "Your best study move right now", es: "Tu mejor siguiente jugada"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }
                }

                Text(displayedMessage)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 52, alignment: .topLeading)
                    .padding(.top, -2)

                HStack(spacing: 10) {
                    coachPill(
                        icon: "bolt.fill",
                        value: "\(totalReadyCount)",
                        label: AppCopy.text(locale, en: "ready now", es: "listas ahora"),
                        tint: NColors.Feedback.warning
                    )

                    coachPill(
                        icon: "square.stack.3d.up.fill",
                        value: "\(recommendations.count)",
                        label: AppCopy.text(locale, en: "decks", es: "decks"),
                        tint: NColors.Brand.neuroBlue
                    )
                }
            }
            .padding(22)
        }
        .shadow(
            color: colorScheme == .light ? Color.black.opacity(0.06) : Color.black.opacity(0.28),
            radius: colorScheme == .light ? 22 : 28,
            x: 0,
            y: 14
        )
        .opacity(showHero ? 1 : 0)
        .offset(y: showHero ? 0 : 24)
        .scaleEffect(showHero ? 1 : 0.98)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62), value: showHero)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(
                recommendations.isEmpty
                    ? AppCopy.text(locale, en: "What do you want to do next?", es: "¿Qué quieres hacer ahora?")
                    : AppCopy.text(locale, en: "Choose a deck to jump in", es: "Elige un deck para empezar")
            )
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(NColors.Text.textPrimary)

            if recommendations.isEmpty {
                emptyStateCard
            } else {
                ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, recommendation in
                    if index < visibleRecommendationCount {
                        recommendationRow(recommendation, index: index)
                    }
                }
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(
                AppCopy.text(
                    locale,
                    en: "You can create more material or take a break. Neru will be here when new cards are ready.",
                    es: "Puedes crear más material o descansar. Neru estará aquí cuando haya tarjetas nuevas listas."
                )
            )
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)

            NSecondaryButton(AppCopy.text(locale, en: "Go to Library", es: "Ir a Biblioteca")) {
                dismiss()
                onOpenLibrary()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func recommendationRow(_ recommendation: StudyDeckRecommendation, index: Int) -> some View {
        let accent = NColors.SubjectIcon.color(for: recommendation.deck.subject?.colorTokenReference)
        let subjectSymbol = recommendation.deck.subject?.systemImageName ?? "book.closed"
        let subtitle = AppCopy.text(
            locale,
            en: "\(recommendation.readyCount) ready now out of \(recommendation.totalCards) total cards.",
            es: "\(recommendation.readyCount) listas ahora de \(recommendation.totalCards) tarjetas totales."
        )
        let cardBackground = colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt
        let cardBorder = colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08)
        let shadowColor = colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.22)
        let secondaryTextColor = colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark

        return Button {
            onSelectDeck(recommendation.deck)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(colorScheme == .light ? 0.14 : 0.18))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: subjectSymbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(accent)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.subjectPathText)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                            .lineLimit(1)

                        Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NColors.Text.textTertiary)
                }

                HStack(spacing: 10) {
                    deckMetricChip(
                        icon: "bolt.fill",
                        value: "\(recommendation.readyCount)",
                        label: AppCopy.text(locale, en: "ready", es: "listas"),
                        tint: NColors.Feedback.warning
                    )

                    deckMetricChip(
                        icon: "square.on.square",
                        value: "\(recommendation.totalCards)",
                        label: AppCopy.text(locale, en: "total", es: "total"),
                        tint: accent
                    )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: colorScheme == .light ? 16 : 20,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
    }

    private func coachPill(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NColors.Text.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(colorScheme == .light ? Color.white.opacity(0.65) : Color.white.opacity(0.05))
        )
        .overlay(
            Capsule()
                .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func deckMetricChip(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NColors.Text.textTertiary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(NColors.Neutrals.surfaceAlt)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(colorScheme == .light ? 0.16 : 0.24), lineWidth: 1)
        )
    }

    private var totalReadyCount: Int {
        recommendations.reduce(0) { $0 + $1.readyCount }
    }

    private var fullMessage: String {
        if recommendations.isEmpty {
            return AppCopy.text(
                locale,
                en: "Everything looks clean. You can explore the library or wait for the next review window.",
                es: "Todo se ve limpio. Puedes explorar la biblioteca o esperar la próxima ventana de repaso."
            )
        }

        return AppCopy.text(
            locale,
            en: "I picked the strongest review opportunities for today. Start with the top deck and keep your momentum.",
            es: "Elegí las mejores oportunidades de repaso para hoy. Empieza por el deck superior y mantén el impulso."
        )
    }

    private var coachMascot: Image {
        recommendations.isEmpty ? NImages.Mascot.neruHappy : NImages.Mascot.neruThinking
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color.white.opacity(0.92), NColors.Brand.neuroBlue.opacity(0.08), NColors.Brand.neuralMint.opacity(0.08)]
                : [NColors.Neutrals.surfaceAlt, NColors.Brand.neuroBlue.opacity(0.16), NColors.Brand.neuralMint.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroBorder: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
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

    private func startEntryAnimation() {
        showHero = false
        visibleRecommendationCount = 0
        recommendationAnimationTask?.cancel()

        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            mascotFloatY = -5
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(40))
            showHero = true
        }

        recommendationAnimationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            for count in 1...recommendations.count {
                if Task.isCancelled { return }
                visibleRecommendationCount = count
                try? await Task.sleep(for: .milliseconds(110))
            }
        }
    }

    private func startTypewriter() {
        typewriterTask?.cancel()
        displayedMessage = ""

        let message = fullMessage
        typewriterTask = Task { @MainActor in
            for character in message {
                if Task.isCancelled { return }
                displayedMessage.append(character)
                try? await Task.sleep(nanoseconds: 22_000_000)
            }
        }
    }
}
