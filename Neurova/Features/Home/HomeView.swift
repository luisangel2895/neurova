import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: HomeViewModel
    private let onSettingsTap: () -> Void
    private let onOpenBootstrap: () -> Void
    private let onOpenLibrary: () -> Void

    @State private var selectedDeckForStudy: Deck?
    @State private var studyOptionCounts: [StudyCardFilter: Int] = [:]
    @State private var selectedStudyCards: [Card] = []
    @State private var isPresentingStudyOptions = false
    @State private var isPresentingStudyCoach = false
    @State private var shouldPresentStudyAfterOptionsDismiss = false
    @State private var isPresentingStudy = false
    @State private var selectedDeckForDetail: Deck?
    @State private var noCardsAlertMessage: String?

    init(
        viewModel: HomeViewModel = HomeViewModel(),
        onSettingsTap: @escaping () -> Void = {},
        onOpenBootstrap: @escaping () -> Void = {},
        onOpenLibrary: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSettingsTap = onSettingsTap
        self.onOpenBootstrap = onOpenBootstrap
        self.onOpenLibrary = onOpenLibrary
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                headerSection
                studyCardSection
                statsGridSection
                recommendationSection
                recentDecksSection
                dailyGoalSummarySection
                tipSection
            }
            .padding(.horizontal, NSpacing.md + NSpacing.xs)
            .padding(.top, NSpacing.md)
            .padding(.bottom, NSpacing.xxl)
        }
        .background(homeBackground.ignoresSafeArea())
        .task {
            viewModel.load(using: modelContext)
        }
        .onChange(of: locale.identifier) { _, _ in
            viewModel.load(using: modelContext, forceRefresh: true)
        }
        .sheet(isPresented: $isPresentingStudyCoach) {
            StudyCoachView(
                recommendations: state.studyRecommendations,
                onSelectDeck: { deck in
                    beginReadyStudyFlow(with: deck)
                }
            )
        }
        .sheet(isPresented: $isPresentingStudyOptions) {
            if let selectedDeckForStudy {
                StudyOptionsSheetView(
                    counts: studyOptionCounts,
                    onSelect: { filter in
                        let cards = viewModel.studyCards(
                            for: selectedDeckForStudy,
                            filter: filter,
                            using: modelContext
                        )

                        guard cards.isEmpty == false else {
                            noCardsAlertMessage = AppCopy.text(
                                locale,
                                en: "No cards available for this mode.",
                                es: "No hay tarjetas disponibles para este modo."
                            )
                            isPresentingStudyOptions = false
                            return
                        }

                        selectedStudyCards = cards
                        shouldPresentStudyAfterOptionsDismiss = true
                        isPresentingStudyOptions = false
                    }
                )
                .presentationDetents([.fraction(0.48), .medium])
            }
        }
        .onChange(of: isPresentingStudyOptions) { _, isPresented in
            guard isPresented == false, shouldPresentStudyAfterOptionsDismiss else { return }
            shouldPresentStudyAfterOptionsDismiss = false
            isPresentingStudy = true
        }
        .sheet(isPresented: $isPresentingStudy) {
            if let deck = selectedDeckForStudy {
                NavigationStack {
                    StudyView(
                        deckTitle: deck.title,
                        cards: selectedStudyCards,
                        frontText: { $0.frontText },
                        backText: { $0.backText }
                    )
                }
            }
        }
        .onChange(of: isPresentingStudy) { _, isPresented in
            if isPresented == false {
                viewModel.load(using: modelContext, forceRefresh: true)
            }
        }
        .sheet(item: $selectedDeckForDetail) { deck in
            NavigationStack {
                DeckDetailView(deck: deck)
            }
        }
        .onChange(of: selectedDeckForDetail?.id) { _, selectedID in
            if selectedID == nil {
                viewModel.load(using: modelContext, forceRefresh: true)
            }
        }
        .alert(
            AppCopy.text(locale, en: "Study Unavailable", es: "Estudio no disponible"),
            isPresented: Binding(
                get: { noCardsAlertMessage != nil },
                set: { isPresented in
                    if isPresented == false {
                        noCardsAlertMessage = nil
                    }
                }
            )
        ) {
            Button(AppCopy.text(locale, en: "OK", es: "OK"), role: .cancel) {}
        } message: {
            Text(noCardsAlertMessage ?? "")
        }
    }

    private var state: HomeState {
        viewModel.state
    }

    private var homeBackground: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                Text("\(AppCopy.text(locale, en: "Hi", es: "Hola")), \(state.greetingName)\(state.greetingEmoji)")
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(state.subtitle)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.bottom, NSpacing.sm + 2)

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: state.settingsSymbolName)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(secondaryTextColor)
                    .frame(width: 36, height: 36)
                    .background(NColors.Neutrals.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(NColors.Neutrals.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0.7, perform: onOpenBootstrap)
        }
    }

    private var studyCardSection: some View {
        NHighlightCard(
            sectionLabel: state.studySectionTitle,
            title: state.studyTitle,
            recommendationText: nil,
            subtitle: state.progressDetailText,
            primaryActionTitle: state.primaryActionTitle,
            secondaryActionTitle: state.secondaryActionTitle,
            onPrimaryAction: handlePrimaryAction,
            onSecondaryAction: onOpenLibrary
        ) {
            ZStack {
                NProgressRing(
                    progress: state.progress,
                    lineWidth: NSpacing.xs + 3,
                    centerText: nil
                )
                .frame(width: 68, height: 68)

                Text(state.progressPercentText)
                    .font(NTypography.headline.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
            }
            .padding(.top, NSpacing.md - 1)
            .padding(.leading, NSpacing.md - 1)
            .padding(.trailing, NSpacing.md - 1)
            .padding(.bottom, 0)
        }
    }

    private var statsGridSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs), GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs)],
            spacing: NSpacing.sm + NSpacing.xs
        ) {
            ForEach(state.quickStats) { stat in
                NStatCard(
                    systemImage: stat.systemImage,
                    iconColor: stat.iconColor,
                    value: stat.value,
                    label: stat.label
                )
            }
        }
    }

    private var recommendationSection: some View {
        NInfoCard(
            sectionLabel: state.recommendationSectionTitle,
            chips: state.recommendation.tags,
            title: state.recommendation.title,
            description: state.recommendation.message,
            actionTitle: state.recommendation.actionTitle,
            onAction: handleRecommendationAction
        )
    }

    private var recentDecksSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            Text(state.recentsSectionTitle)
                .font(NTypography.micro.weight(.bold))
                .tracking(0.6)
                .foregroundStyle(NColors.Text.textTertiary)

            if state.recentDecks.isEmpty {
                NEmptyState(
                    systemImage: "rectangle.stack",
                    title: AppCopy.text(locale, en: "No decks yet", es: "Aún no hay decks"),
                    message: AppCopy.text(locale, en: "Create your first deck from Library to start studying.", es: "Crea tu primer deck en Biblioteca para comenzar a estudiar."),
                    ctaTitle: AppCopy.text(locale, en: "Open Library", es: "Abrir Biblioteca")
                ) {
                    onOpenLibrary()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NSpacing.sm) {
                        ForEach(state.recentDecks) { deck in
                            Button {
                                selectedDeckForDetail = deck.deck
                            } label: {
                                NDeckCard(
                                    accentColor: deck.accentColor,
                                    contextText: deck.subjectPathText,
                                    title: deck.title,
                                    cardCountText: "\(deck.cardCountText) • \(deck.readyCountText)"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, NSpacing.xs)
                }
            }
        }
    }

    private var dailyGoalSummarySection: some View {
        NCard {
            HStack(spacing: NSpacing.sm + NSpacing.xs) {
                Image(systemName: state.dailyGoalSummarySymbolName)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Brand.neuroBlue)
                    .frame(width: 32, height: 32)
                    .background(NColors.Neutrals.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))

                VStack(alignment: .leading, spacing: NSpacing.sm) {
                    HStack {
                        Text(state.dailyGoalSummaryTitle)
                            .font(NTypography.caption.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Spacer()

                        Text(state.dailyGoalSummaryTrailingText)
                            .font(NTypography.caption.weight(.bold))
                            .foregroundStyle(secondaryTextColor)
                    }

                    NProgressBar(progress: state.dailyGoalSummaryProgress)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var tipSection: some View {
        NTipCard(title: state.tipTitle, bodyText: state.tipMessage) {
            NImages.Brand.logoMark
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        }
        .frame(maxWidth: .infinity)
    }

    private func handlePrimaryAction() {
        guard state.studyRecommendations.isEmpty == false else {
            guard let highlightedDeck = state.highlightedDeck else {
                onOpenLibrary()
                return
            }
            beginStudyFlow(with: highlightedDeck)
            return
        }

        isPresentingStudyCoach = true
    }

    private func beginStudyFlow(with deck: Deck) {
        let counts = viewModel.studyCounts(for: deck, using: modelContext)
        let hasCards = counts.values.contains { $0 > 0 }
        guard hasCards else {
            noCardsAlertMessage = AppCopy.text(
                locale,
                en: "No cards available for this deck.",
                es: "No hay tarjetas disponibles para este deck."
            )
            return
        }

        selectedDeckForStudy = deck
        studyOptionCounts = counts
        isPresentingStudyOptions = true
    }

    private func beginReadyStudyFlow(with deck: Deck) {
        let readyCards = viewModel.studyCards(for: deck, filter: .due, using: modelContext)
        guard readyCards.isEmpty == false else {
            noCardsAlertMessage = AppCopy.text(
                locale,
                en: "No ready cards available for this deck right now.",
                es: "No hay tarjetas listas para este deck en este momento."
            )
            return
        }

        selectedDeckForStudy = deck
        selectedStudyCards = readyCards
        shouldPresentStudyAfterOptionsDismiss = false
        isPresentingStudyOptions = false
        isPresentingStudy = true
    }

    private func handleRecommendationAction() {
        guard let highlightedDeck = state.highlightedDeck else {
            onOpenLibrary()
            return
        }
        beginStudyFlow(with: highlightedDeck)
    }
}

#Preview("Light") {
    HomeView()
        .preferredColorScheme(.light)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}
