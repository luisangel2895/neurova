import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let deckTitle: String
    private let cards: [Card]
    private let frontText: (Card) -> String
    private let backText: (Card) -> String
    private let onBack: () -> Void
    private let reviewService = ReviewService()

    @State private var queue: [Card] = []
    @State private var initialCount: Int = 0
    @State private var sessionStartTime: Date?
    @State private var sessionEndTime: Date?
    @State private var totalReviewed: Int = 0
    @State private var correctCount: Int = 0
    @State private var wrongCount: Int = 0
    @State private var xpEarned: Int = 0
    @State private var isShowingBack = false
    @State private var cardRotation: Double = 0
    @State private var currentCardOffset: CGFloat = 0
    @State private var currentCardOpacity = 1.0
    @State private var outgoingCard: Card?
    @State private var outgoingCardOffset: CGFloat = 0
    @State private var outgoingCardOpacity = 1.0
    @State private var outgoingShowsBack = false
    @State private var cardTravelDistance: CGFloat = 0
    @State private var selectedQuality: ReviewQuality = .good
    @State private var pressedQuality: ReviewQuality?
    @State private var isPresentingSummary = false
    @State private var sessionSummary: SessionSummary?
    @State private var hasLoadedSession = false
    @State private var isTransitioning = false
    @State private var isClosingSession = false

    init(
        deckTitle: String,
        cards: [Card],
        frontText: @escaping (Card) -> String,
        backText: @escaping (Card) -> String,
        onBack: @escaping () -> Void = {}
    ) {
        self.deckTitle = deckTitle
        self.cards = cards
        self.frontText = frontText
        self.backText = backText
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: NSpacing.lg) {
            topBar

            Spacer(minLength: 0)

            studyCard

            Spacer(minLength: 0)

            reviewButtons
        }
        .padding(.horizontal, NSpacing.md + NSpacing.xs)
        .padding(.top, NSpacing.md)
        .padding(.bottom, 0)
        .background(studyBackground.ignoresSafeArea())
        .task {
            loadSessionIfNeeded()
        }
        .fullScreenCover(isPresented: $isPresentingSummary) {
            if let sessionSummary {
                SummaryView(
                    summary: sessionSummary,
                    onBackToDeck: {
                        onBack()
                        dismiss()
                    },
                    onStudyAgain: {
                        isPresentingSummary = false
                        restartSession()
                    }
                )
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(NColors.Study.headerIconBackground)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "book")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(NColors.Brand.neuroBlue)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(subjectTitle)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                        Text(deckSubtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(secondaryTextColor)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.orange)
                        Text(sessionCounterText)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(NColors.Study.counterBackground)
                    )

                    Button {
                        onBack()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(NColors.Study.closeButtonForeground)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(NColors.Study.closeButtonBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            animatedProgressBar(progress: sessionProgress)
        }
    }

    private func animatedProgressBar(progress: Double) -> some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let clamped = min(max(progress, 0), 1)
                let activeWidth = max(26, proxy.size.width * clamped)
                let tickTime = timeline.date.timeIntervalSinceReferenceDate
                let phase = (tickTime / 2.0).truncatingRemainder(dividingBy: 1.0)
                let xOffset = (activeWidth * 1.8 * phase) - (activeWidth * 0.9)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NColors.Study.progressTrack)
                        .frame(height: 4)

                    Capsule()
                        .fill(NColors.Study.progressFill)
                        .frame(width: activeWidth, height: 4)
                        .overlay {
                            Capsule()
                                .fill(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, Color.white.opacity(0.35), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 30, height: 7)
                                        .offset(x: xOffset)
                                )
                                .clipShape(Capsule())
                        }
                }
            }
            .frame(height: 4)
        }
    }

    private var studyCard: some View {
        GeometryReader { proxy in
            ZStack {
                if let outgoingCard {
                    studyCardContainer(
                        content: {
                            studyCardContent(for: outgoingCard, showsBack: outgoingShowsBack)
                        },
                        rotation: 0,
                        offset: outgoingCardOffset,
                        opacity: outgoingCardOpacity,
                        allowsInteraction: false
                    )
                    .zIndex(1)
                }

                if isClosingSession == false || currentCard != nil {
                    studyCardContainer(
                        content: {
                            Group {
                                if queue.isEmpty && hasLoadedSession && initialCount == 0 {
                                    emptyStudyContent
                                } else if let currentCard {
                                    studyCardContent(for: currentCard, showsBack: isShowingBack)
                                } else {
                                    Color.clear
                                }
                            }
                        },
                        rotation: cardRotation,
                        offset: currentCardOffset,
                        opacity: currentCardOpacity,
                        allowsInteraction: true
                    )
                    .zIndex(2)
                }
            }
            .onAppear {
                updateCardTravelDistance(for: proxy.size.width)
            }
            .onChange(of: proxy.size.width) { _, newWidth in
                updateCardTravelDistance(for: newWidth)
            }
        }
        .frame(minHeight: 320)
    }

    private func studyCardContainer<Content: View>(
        @ViewBuilder content: () -> Content,
        rotation: Double,
        offset: CGFloat,
        opacity: Double,
        allowsInteraction: Bool
    ) -> some View {
        NCard(surfaceLevel: .l1, paddingStyle: .content) {
            content()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 320)
                .contentShape(Rectangle())
                .allowsHitTesting(allowsInteraction)
                .onTapGesture {
                    guard allowsInteraction else { return }
                    flipCard()
                }
        }
        .opacity(opacity)
        .offset(x: offset)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
        .shadow(
            color: studyCardShadowColor,
            radius: studyCardShadowRadius,
            x: 0,
            y: studyCardShadowYOffset
        )
    }

    private func studyCardContent(for card: Card, showsBack: Bool) -> some View {
        VStack {
            HStack {
                Text(cardPositionText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryTextColor)

                Spacer(minLength: 0)

                Text(cardSideLabel(for: showsBack))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(NColors.Study.cardSideText)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(NColors.Study.cardSideBackground)
                    )
            }

            Spacer(minLength: 0)

            ZStack {
                cardFace(text: frontText(card), rotation: showsBack ? -180 : 0, opacity: showsBack ? 0 : 1)
                cardFace(text: backText(card), rotation: showsBack ? 0 : 180, opacity: showsBack ? 1 : 0)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            if showsBack == false {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .medium))
                    Text(AppCopy.text(locale, en: "Tap to see answer", es: "Toca para ver la respuesta"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(secondaryTextColor.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardFace(text: String, rotation: Double, opacity: Double) -> some View {
        Text(text)
            .font(NTypography.headline)
            .foregroundStyle(NColors.Text.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
    }

    private var emptyStudyContent: some View {
        VStack(spacing: NSpacing.md) {
            Spacer(minLength: 0)

            Text(AppCopy.text(locale, en: "No cards available", es: "No hay tarjetas disponibles"))
                .font(NTypography.headline)
                .foregroundStyle(NColors.Text.textPrimary)

            Text(AppCopy.text(locale, en: "There are no cards available for the selected study mode.", es: "No hay tarjetas disponibles para el modo de estudio seleccionado."))
                .font(NTypography.body)
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)

            NSecondaryButton(AppCopy.text(locale, en: "Back to Deck", es: "Volver al Mazo")) {
                onBack()
                dismiss()
            }
            .frame(maxWidth: 220)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewButtons: some View {
        VStack(spacing: NSpacing.sm) {
            if isShowingBack {
                Text(AppCopy.text(locale, en: "How well did you know it?", es: "¿Qué tan bien la sabías?"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .padding(.bottom, 2)

                HStack(spacing: 10) {
                    reviewButton(
                        title: AppCopy.text(locale, en: "Again", es: "Otra vez"),
                        subtitle: AppCopy.text(locale, en: "~1 min", es: "~1 min"),
                        quality: .again,
                        titleColor: NColors.Study.reviewAgain
                    )
                    reviewButton(
                        title: AppCopy.text(locale, en: "Hard", es: "Difícil"),
                        subtitle: AppCopy.text(locale, en: "<1 min", es: "<1 min"),
                        quality: .hard,
                        titleColor: NColors.Study.reviewHard
                    )
                    reviewButton(
                        title: AppCopy.text(locale, en: "Good", es: "Bien"),
                        subtitle: AppCopy.text(locale, en: "~10 min", es: "~10 min"),
                        quality: .good,
                        titleColor: NColors.Study.reviewGood
                    )
                    reviewButton(
                        title: AppCopy.text(locale, en: "Easy", es: "Fácil"),
                        subtitle: AppCopy.text(locale, en: "~4 days", es: "~4 días"),
                        quality: .easy,
                        titleColor: NColors.Study.reviewEasy
                    )
                }
            } else {
                HStack(spacing: 10) {
                    NImages.Mascot.neruDefault
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    Text(AppCopy.text(locale, en: "Take your time to think...", es: "Tómate tu tiempo para pensar..."))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)

                NGradientButton(
                    AppCopy.text(locale, en: "Show answer", es: "Mostrar respuesta"),
                    leadingSymbolName: "arrow.uturn.backward",
                    animateEffects: true
                ) {
                    flipCard()
                }
            }
        }
        .opacity((hasStudyCard || (queue.isEmpty && hasLoadedSession && initialCount == 0)) ? 1 : 0.5)
    }

    private func reviewButton(title: String, subtitle: String, quality: ReviewQuality, titleColor: Color) -> some View {
        let isSelected = selectedQuality == quality

        return Button {
            selectedQuality = quality
            submitReview(quality)
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .fill(isSelected ? NColors.Home.surfaceL1 : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(isSelected ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .scaleEffect(buttonScale(for: quality))
        .opacity(buttonOpacity(for: quality))
        .shadow(
            color: isSelected ? NColors.Study.selectedShadow : .clear,
            radius: isSelected ? NSpacing.xs : 0,
            x: 0,
            y: isSelected ? 1 : 0
        )
        .animation(.easeOut(duration: 0.12), value: pressedQuality)
        .animation(.easeInOut(duration: 0.18), value: selectedQuality)
        .disabled(hasStudyCard == false || isTransitioning)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    pressedQuality = quality
                }
                .onEnded { _ in
                    pressedQuality = nil
                }
        )
    }

    private func cardSideLabel(for showsBack: Bool) -> String {
        showsBack
            ? AppCopy.text(locale, en: "Back", es: "Respuesta")
            : AppCopy.text(locale, en: "Front", es: "Pregunta")
    }

    private var secondaryTextColor: Color {
        NColors.Text.textSecondary
    }

    private var studyCardShadowColor: Color {
        colorScheme == .light ? NColors.Home.cardShadowLight : NColors.Study.cardShadowDark
    }

    private var studyCardShadowRadius: CGFloat {
        colorScheme == .light ? NSpacing.lg : NSpacing.md
    }

    private var studyCardShadowYOffset: CGFloat {
        colorScheme == .light ? NSpacing.sm : NSpacing.xs
    }

    private var studyBackground: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var currentCard: Card? {
        queue.first
    }

    private var hasStudyCard: Bool {
        currentCard != nil
    }

    private var subjectTitle: String {
        currentCard?.deck?.subject?.name ?? deckTitle
    }

    private var deckSubtitle: String {
        currentCard?.deck?.title ?? AppCopy.text(locale, en: "Flashcards", es: "Flashcards")
    }

    private var sessionCounterText: String {
        guard initialCount > 0 else { return "0/0" }
        return "\(min(totalReviewed, initialCount))/\(initialCount)"
    }

    private var sessionProgress: Double {
        guard initialCount > 0 else { return 0 }
        return min(1, Double(totalReviewed) / Double(initialCount))
    }

    private var cardPositionText: String {
        guard initialCount > 0 else { return AppCopy.text(locale, en: "Card 0 of 0", es: "Tarjeta 0 de 0") }
        let index = min(totalReviewed + 1, initialCount)
        return AppCopy.text(locale, en: "Card \(index) of \(initialCount)", es: "Tarjeta \(index) de \(initialCount)")
    }

    private func loadSessionIfNeeded() {
        guard hasLoadedSession == false else { return }
        resetSessionState()
        hasLoadedSession = true
    }

    private func flipCard() {
        guard hasStudyCard, isTransitioning == false else { return }
        isTransitioning = true

        withAnimation(.easeInOut(duration: 0.225)) {
            cardRotation = 90
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(225))
            isShowingBack.toggle()
            cardRotation = -90

            withAnimation(.easeInOut(duration: 0.225)) {
                cardRotation = 0
            }

            try? await Task.sleep(for: .milliseconds(225))
            isTransitioning = false
        }
    }

    private func submitReview(_ quality: ReviewQuality) {
        guard let card = currentCard, isTransitioning == false else { return }
        pressedQuality = nil

        do {
            try reviewService.review(
                card: card,
                quality: quality,
                eventType: nil,
                at: .now,
                in: modelContext
            )

            totalReviewed += 1
            xpEarned += xp(for: quality)
            if quality == .again {
                wrongCount += 1
            } else {
                correctCount += 1
            }

            advanceToNextCard(removingCurrent: quality != .again)
        } catch {
            // Keep v1 silent; error handling can be surfaced later if needed.
        }
    }

    private func advanceToNextCard(removingCurrent: Bool) {
        guard let card = currentCard, isTransitioning == false else { return }
        isTransitioning = true
        outgoingCard = card
        outgoingShowsBack = isShowingBack
        outgoingCardOffset = 0
        outgoingCardOpacity = 1

        if removingCurrent {
            queue.removeFirst()
        } else if queue.count > 1 {
            queue.removeFirst()
            queue.append(card)
        }
        // When queue.count == 1 and "Again": card stays as queue[0], animation replays it

        isShowingBack = false
        selectedQuality = .good
        cardRotation = 0

        if queue.isEmpty {
            isClosingSession = true
            withAnimation(.easeInOut(duration: 0.36)) {
                outgoingCardOffset = -cardTravelDistance
                outgoingCardOpacity = 0.2
                currentCardOpacity = 0
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(360))
                sessionEndTime = .now
                outgoingCard = nil
                outgoingCardOffset = 0
                outgoingCardOpacity = 1
                currentCardOffset = 0
                currentCardOpacity = 1
                isTransitioning = false
                presentSummary()
            }
            return
        }

        currentCardOffset = incomingCardStartOffset
        currentCardOpacity = 1

        withAnimation(.easeInOut(duration: 0.38)) {
            outgoingCardOffset = -incomingCardStartOffset
            outgoingCardOpacity = 0.94
            currentCardOffset = 0
            currentCardOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(380))
            outgoingCard = nil
            outgoingCardOffset = 0
            outgoingCardOpacity = 1
            currentCardOffset = 0
            currentCardOpacity = 1
            isTransitioning = false
        }
    }

    private func restartSession() {
        isClosingSession = false
        resetSessionState()
        sessionSummary = nil
    }

    private func resetSessionState() {
        queue = cards
        initialCount = cards.count
        sessionStartTime = cards.isEmpty ? nil : .now
        sessionEndTime = nil
        totalReviewed = 0
        correctCount = 0
        wrongCount = 0
        xpEarned = 0
        selectedQuality = .good
        isShowingBack = false
        cardRotation = 0
        currentCardOffset = 0
        currentCardOpacity = 1
        outgoingCard = nil
        outgoingCardOffset = 0
        outgoingCardOpacity = 1
        outgoingShowsBack = false
        isTransitioning = false
        isClosingSession = false
    }

    private func updateCardTravelDistance(for width: CGFloat) {
        cardTravelDistance = max(width + NSpacing.md, 220)
    }

    private var incomingCardStartOffset: CGFloat {
        cardTravelDistance
    }

    private func presentSummary() {
        let start = sessionStartTime ?? .now
        let end = sessionEndTime ?? .now
        let duration = max(0, Int(end.timeIntervalSince(start)))

        sessionSummary = SessionSummary(
            xpEarned: xpEarned,
            totalReviewed: totalReviewed,
            correctCount: correctCount,
            wrongCount: wrongCount,
            durationSeconds: duration
        )
        isPresentingSummary = true
    }

    private func xp(for quality: ReviewQuality) -> Int {
        switch quality {
        case .again:
            return 0
        case .hard:
            return 5
        case .good:
            return 10
        case .easy:
            return 15
        }
    }

    private func buttonScale(for quality: ReviewQuality) -> CGFloat {
        if pressedQuality == quality {
            return 0.98
        }
        return selectedQuality == quality ? 1.03 : 1
    }

    private func buttonOpacity(for quality: ReviewQuality) -> Double {
        selectedQuality == quality ? 1 : 0.72
    }
}

#Preview("StudyView Light") {
    StudyView(
        deckTitle: "Biología",
        cards: [],
        frontText: { _ in "Front" },
        backText: { _ in "Back" }
    )
    .preferredColorScheme(.light)
}

#Preview("StudyView Dark") {
    StudyView(
        deckTitle: "Biología",
        cards: [],
        frontText: { _ in "Front" },
        backText: { _ in "Back" }
    )
    .preferredColorScheme(.dark)
}
