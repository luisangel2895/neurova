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
    @State private var didAutoDowngradeToHard = false
    @State private var frontTimerToken = UUID()
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
        .padding(.bottom, NSpacing.lg)
        .background(studyBackground.ignoresSafeArea())
        .task {
            loadSessionIfNeeded()
        }
        .task(id: frontTimerToken) {
            await armFrontHardFallbackTimer()
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
        HStack {
            Button {
                onBack()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Text.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: NSpacing.xs) {
                Text(deckTitle)
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(progressText)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
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
                .onTapGesture(count: 2) {
                    guard allowsInteraction else { return }
                    flipCard()
                }
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .onEnded { value in
                            guard allowsInteraction, value.translation.width < -56 else { return }
                            handlePrimaryAdvanceAction()
                        }
                )
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
            Text(cardSideLabel(for: showsBack))
                .font(NTypography.caption)
                .foregroundStyle(secondaryTextColor)

            Spacer(minLength: 0)

            ZStack {
                cardFace(text: frontText(card), rotation: showsBack ? -180 : 0, opacity: showsBack ? 0 : 1)
                cardFace(text: backText(card), rotation: showsBack ? 0 : 180, opacity: showsBack ? 1 : 0)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
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
            HStack(spacing: NSpacing.sm) {
                NSecondaryButton(flipButtonTitle) {
                    flipCard()
                }
                .frame(maxWidth: .infinity)
                .disabled(hasStudyCard == false || isTransitioning)

                NSecondaryButton(primaryAdvanceButtonTitle) {
                    handlePrimaryAdvanceAction()
                }
                .frame(maxWidth: .infinity)
                .disabled(hasStudyCard == false || isTransitioning)
            }

            HStack(spacing: NSpacing.sm) {
                reviewButton(title: AppCopy.text(locale, en: "Hard", es: "Dificil"), quality: .hard)
                reviewButton(title: AppCopy.text(locale, en: "Good", es: "Bien"), quality: .good)
                reviewButton(title: AppCopy.text(locale, en: "Easy", es: "Facil"), quality: .easy)
            }
        }
        .opacity((hasStudyCard || (queue.isEmpty && hasLoadedSession && initialCount == 0)) ? 1 : 0.5)
    }

    private func reviewButton(title: String, quality: ReviewQuality) -> some View {
        let isSelected = selectedQuality == quality

        return NSecondaryButton(title) {
            selectedQuality = quality
            frontTimerToken = UUID()
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(buttonScale(for: quality))
        .opacity(buttonOpacity(for: quality))
        .background(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(isSelected ? NColors.Home.surfaceL1 : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isSelected ? NColors.Brand.neuroBlue : .clear, lineWidth: isSelected ? 1.5 : 0)
        )
        .shadow(
            color: isSelected ? NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.12 : 0.18) : .clear,
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

    private var progressText: String {
        guard initialCount > 0 else {
            return "0 / 0"
        }

        let currentIndex = min(totalReviewed + (hasStudyCard ? 1 : 0), initialCount)
        return "\(currentIndex) / \(initialCount)"
    }

    private func cardSideLabel(for showsBack: Bool) -> String {
        showsBack
            ? AppCopy.text(locale, en: "Back", es: "Reverso")
            : AppCopy.text(locale, en: "Front", es: "Frente")
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var studyCardShadowColor: Color {
        colorScheme == .light
            ? NColors.Home.cardShadowLight
            : NColors.Home.cardInnerBorder
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.225) {
            isShowingBack.toggle()
            frontTimerToken = UUID()
            cardRotation = -90

            withAnimation(.easeInOut(duration: 0.225)) {
                cardRotation = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.225) {
                isTransitioning = false
            }
        }
    }

    private var flipButtonTitle: String {
        isShowingBack
            ? AppCopy.text(locale, en: "Show Front", es: "Mostrar Frente")
            : AppCopy.text(locale, en: "Show Back", es: "Mostrar Reverso")
    }

    private var primaryAdvanceButtonTitle: String {
        isShowingBack
            ? AppCopy.text(locale, en: "Next", es: "Siguiente")
            : AppCopy.text(locale, en: "Skip", es: "Saltar")
    }

    private func handlePrimaryAdvanceAction() {
        if isShowingBack {
            submitReview(selectedQuality)
        } else {
            submitReview(.hard)
        }
    }

    private func submitReview(_ quality: ReviewQuality) {
        guard let card = currentCard, isTransitioning == false else { return }
        pressedQuality = nil
        let eventType = xpEventType(for: quality)

        do {
            try reviewService.review(
                card: card,
                quality: quality,
                eventType: eventType,
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

            advanceToNextCard(removingCurrent: true)
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

        isShowingBack = false
        selectedQuality = .good
        didAutoDowngradeToHard = false
        frontTimerToken = UUID()
        cardRotation = 0

        if queue.isEmpty {
            isClosingSession = true
            withAnimation(.easeInOut(duration: 0.36)) {
                outgoingCardOffset = -cardTravelDistance
                outgoingCardOpacity = 0.2
                currentCardOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
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
        didAutoDowngradeToHard = false
        frontTimerToken = UUID()
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

    private func armFrontHardFallbackTimer() async {
        guard hasStudyCard, isShowingBack == false, selectedQuality == .good else { return }

        do {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        } catch {
            return
        }

        guard Task.isCancelled == false else { return }
        guard hasStudyCard, isShowingBack == false, selectedQuality == .good else { return }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedQuality = .hard
                didAutoDowngradeToHard = true
            }
        }
    }

    private func xpEventType(for quality: ReviewQuality) -> XPEventType? {
        if isShowingBack == false {
            return .skipHard
        }

        if quality == .hard, didAutoDowngradeToHard {
            return .autoHardTimeout
        }

        return nil
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
