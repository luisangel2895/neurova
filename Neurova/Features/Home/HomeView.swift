import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("daily_goal_cards") private var dailyGoalCardsStorage: Int = 20

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

    @State private var hasStartedEntryAnimation = false
    @State private var hasAnimatedIn = false
    @State private var showHeroPercent = false
    @State private var animatedHeroProgress: Double = 0
    @State private var heroProgressTask: Task<Void, Never>?
    @State private var visibleFeaturedDeckTitle = false
    @State private var visibleFeaturedDeck = false
    @State private var visibleStatCardCount = 0
    @State private var visibleDeckCardCount = 0
    @State private var featuredDeckTitleAnimationTask: Task<Void, Never>?
    @State private var featuredDeckAnimationTask: Task<Void, Never>?
    @State private var statsAnimationTask: Task<Void, Never>?
    @State private var deckAnimationTask: Task<Void, Never>?

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
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                heroSection
                statsSection
                featuredDeckSection
                recentDecksSection
                tipSection
            }
            .padding(.horizontal, NSpacing.md + NSpacing.xs)
            .padding(.top, 10)
            .padding(.bottom, 140)
        }
        .background(homeBackground.ignoresSafeArea())
        .task {
            viewModel.load(using: modelContext)
            startEntryAnimationIfNeeded()
        }
        .onAppear {
            startEntryAnimationIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appSplashWillExit)) { _ in
            restartEntryAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .homeShouldForceRefresh)) { _ in
            viewModel.load(using: modelContext, forceRefresh: true)
            animateHeroProgressToCurrentState()
        }
        .onChange(of: locale.identifier) { _, _ in
            viewModel.load(using: modelContext, forceRefresh: true)
        }
        .onChange(of: dailyGoalCardsStorage) { _, _ in
            viewModel.load(using: modelContext, forceRefresh: true)
            animateHeroProgressToCurrentState()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            viewModel.load(using: modelContext, forceRefresh: true)
            animateHeroProgressToCurrentState()
        }
        .sheet(isPresented: $isPresentingStudyCoach) {
            StudyCoachView(
                recommendations: state.studyRecommendations,
                onSelectDeck: { deck in
                    beginReadyStudyFlow(with: deck)
                },
                onOpenLibrary: onOpenLibrary
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
        .fullScreenCover(isPresented: $isPresentingStudy) {
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
        ZStack {
            LinearGradient(
                colors: colorScheme == .light
                    ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                    : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: colorScheme == .light
                    ? [Color.white.opacity(0.28), .clear, NColors.Brand.neuroBlue.opacity(0.04)]
                    : [NColors.Brand.neuroBlue.opacity(0.08), .clear, NColors.Brand.neuralMint.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var resolvedGreetingName: String {
        let appleTrimmed = appleGivenName.trimmingCharacters(in: .whitespacesAndNewlines)
        if appleTrimmed.isEmpty == false { return appleTrimmed }

        let profileTrimmed = profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if profileTrimmed.isEmpty == false { return profileTrimmed }

        return state.greetingName
    }

    private var displayName: String {
        let trimmed = resolvedGreetingName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Neurova" : trimmed
    }

    private var avatarLetter: String {
        String(displayName.prefix(1)).uppercased()
    }

    private var featuredDeckID: UUID? {
        state.highlightedDeck?.id
    }

    private var featuredRecentDeck: RecentDeck? {
        guard let featuredDeckID else { return nil }
        return state.recentDecks.first(where: { $0.id == featuredDeckID })
    }

    private var visibleRecentDecks: [RecentDeck] {
        Array(state.recentDecks.filter { $0.id != featuredDeckID }.prefix(3))
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppCopy.text(locale, en: "WELCOME BACK", es: "BIENVENIDO DE NUEVO"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(NColors.Text.textTertiary)
                    .opacity(0.88)

                Text(displayName)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
            }
            .offset(x: hasAnimatedIn ? 0 : -10)
            .opacity(hasAnimatedIn ? 1 : 0)
            .animation(.homeExpo(duration: 0.5, delay: 0), value: hasAnimatedIn)

            Spacer(minLength: 0)

            Button(action: onSettingsTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [NColors.Brand.neuroBlue.opacity(0.92), NColors.Brand.neuralMint.opacity(0.95)]
                                    : [
                                        Color(red: 0.24, green: 0.50, blue: 0.90),
                                        Color(red: 0.30, green: 0.46, blue: 0.87),
                                        Color(red: 0.39, green: 0.27, blue: 0.82)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.38), lineWidth: 1)
                        )
                        .shadow(
                            color: colorScheme == .dark
                                ? NColors.Brand.neuroBlue.opacity(0.52)
                                : NColors.Brand.neuroBlue.opacity(0.16),
                            radius: colorScheme == .dark ? 18 : 8,
                            x: 0,
                            y: colorScheme == .dark ? 6 : 4
                        )

                    Text(avatarLetter)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .frame(width: 54, height: 54)
                        .multilineTextAlignment(.center)

                    Circle()
                        .fill(NColors.Surface.raised)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: state.settingsSymbolName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(NColors.Text.textSecondary)
                        )
                        .offset(x: 21, y: 21)
                }
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0.7, perform: onOpenBootstrap)
            .scaleEffect(hasAnimatedIn ? 1 : 0.01, anchor: .center)
            .animation(.homeSpring(delay: 0.2, stiffness: 300, damping: 22), value: hasAnimatedIn)
        }
    }

    private var heroSection: some View {
        HomeHeroCard(
            locale: locale,
            colorScheme: colorScheme,
            completedCards: state.todayCompletedCards,
            goalCards: state.todayGoalCards,
            progress: animatedHeroProgress,
            showProgressNumber: showHeroPercent,
            actionTitle: state.primaryActionTitle,
            onAction: handlePrimaryAction
        )
        .offset(y: hasAnimatedIn ? 0 : 25)
        .scaleEffect(hasAnimatedIn ? 1 : 0.97)
        .opacity(hasAnimatedIn ? 1 : 0)
        .animation(.homeExpo(duration: 0.6, delay: 0.1), value: hasAnimatedIn)
    }

    private var statsSection: some View {
        HStack(spacing: 11) {
            ForEach(Array(state.quickStats.enumerated()), id: \.element.id) { index, stat in
                HomeCompactStatCard(
                    stat: stat,
                    label: compactLabel(for: stat)
                )
                .offset(y: visibleStatCardCount > index ? 0 : 42)
                .scaleEffect(visibleStatCardCount > index ? 1 : 0.82)
                .rotationEffect(.degrees(visibleStatCardCount > index ? 0 : -6))
                .opacity(visibleStatCardCount > index ? 1 : 0)
                .animation(.homeExpo(duration: 0.7), value: visibleStatCardCount)
            }
        }
    }

    private var recentDecksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(AppCopy.text(locale, en: "Recent decks", es: "Mazos recientes"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)

                Spacer(minLength: 0)

                Button(action: onOpenLibrary) {
                    HStack(spacing: 4) {
                        Text(AppCopy.text(locale, en: "See all", es: "VER TODOS"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(NColors.Brand.accentBlue)
                }
                .buttonStyle(.plain)
            }

            if visibleRecentDecks.isEmpty {
                NEmptyState(
                    systemImage: "rectangle.stack",
                    title: AppCopy.text(locale, en: "No decks yet", es: "Aún no hay decks"),
                    message: AppCopy.text(locale, en: "Create your first deck from Library to start studying.", es: "Crea tu primer deck en Biblioteca para comenzar a estudiar."),
                    ctaTitle: AppCopy.text(locale, en: "Open Library", es: "Abrir Biblioteca")
                ) {
                    onOpenLibrary()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(visibleRecentDecks.enumerated()), id: \.element.id) { index, deck in
                        Button {
                            selectedDeckForDetail = deck.deck
                        } label: {
                            HomeRecentDeckCard(
                                locale: locale,
                                deck: deck,
                                isFeatured: featuredDeckID == deck.id,
                                colorScheme: colorScheme,
                                showFeaturedBadge: hasAnimatedIn
                            )
                        }
                        .buttonStyle(.plain)
                        .offset(x: visibleDeckCardCount > index ? 0 : -150)
                        .opacity(visibleDeckCardCount > index ? 1 : 0)
                        .animation(.homeExpo(duration: 0.5), value: visibleDeckCardCount)
                    }
                }
            }
        }
        .offset(y: hasAnimatedIn ? 0 : 15)
        .opacity(hasAnimatedIn ? 1 : 0)
        .animation(.homeExpo(duration: 0.5, delay: 0.22), value: hasAnimatedIn)
    }

    @ViewBuilder
    private var featuredDeckSection: some View {
        if let featuredRecentDeck {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppCopy.text(locale, en: "For you", es: "Para ti"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .offset(y: visibleFeaturedDeckTitle ? 0 : 15)
                    .opacity(visibleFeaturedDeckTitle ? 1 : 0)
                    .animation(.homeExpo(duration: 0.5), value: visibleFeaturedDeckTitle)

                Button {
                    selectedDeckForDetail = featuredRecentDeck.deck
                } label: {
                    HomeRecentDeckCard(
                        locale: locale,
                        deck: featuredRecentDeck,
                        isFeatured: true,
                        colorScheme: colorScheme,
                        showFeaturedBadge: hasAnimatedIn
                    )
                }
                .buttonStyle(.plain)
                .offset(x: visibleFeaturedDeck ? 0 : -150)
                .opacity(visibleFeaturedDeck ? 1 : 0)
                .animation(.homeExpo(duration: 0.5), value: visibleFeaturedDeck)
            }
            .offset(y: hasAnimatedIn ? 0 : 15)
            .opacity(hasAnimatedIn ? 1 : 0)
            .animation(.homeExpo(duration: 0.5, delay: 0.2), value: hasAnimatedIn)
        }
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppCopy.text(locale, en: "Neurova Tips", es: "Neurova Tips"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            HomeTipCard(
                locale: locale,
                title: AppCopy.text(locale, en: "Study tip", es: "Consejo de estudio"),
                message: state.tipMessage
            )
        }
        .offset(y: hasAnimatedIn ? 0 : 15)
        .opacity(hasAnimatedIn ? 1 : 0)
        .animation(.homeExpo(duration: 0.5, delay: 0.35), value: hasAnimatedIn)
    }

    private func compactLabel(for stat: QuickStat) -> String {
        switch stat.systemImage {
        case "flame":
            return AppCopy.text(locale, en: "STREAK", es: "RACHA")
        case "bolt":
            return "XP"
        case "square.stack.3d.up":
            return AppCopy.text(locale, en: "READY", es: "LISTAS")
        case "rectangle.stack":
            return AppCopy.text(locale, en: "DECKS", es: "MAZOS")
        default:
            return stat.label.uppercased()
        }
    }

    private func startEntryAnimationIfNeeded() {
        guard hasStartedEntryAnimation == false else { return }
        hasStartedEntryAnimation = true
        animatedHeroProgress = initialHeroProgress
        runEntryAnimation()
    }

    private func restartEntryAnimation() {
        heroProgressTask?.cancel()
        featuredDeckTitleAnimationTask?.cancel()
        featuredDeckAnimationTask?.cancel()
        statsAnimationTask?.cancel()
        deckAnimationTask?.cancel()
        hasStartedEntryAnimation = true
        hasAnimatedIn = false
        showHeroPercent = false
        visibleFeaturedDeckTitle = false
        visibleFeaturedDeck = false
        visibleStatCardCount = 0
        visibleDeckCardCount = 0
        animatedHeroProgress = initialHeroProgress

        DispatchQueue.main.async {
            runEntryAnimation()
        }
    }

    private func runEntryAnimation() {
        withAnimation(.homeExpo(duration: 0.6)) {
            hasAnimatedIn = true
        }

        heroProgressTask?.cancel()
        animatedHeroProgress = 0
        heroProgressTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.homeExpo(duration: 1.4)) {
                    animatedHeroProgress = state.progress
                }
            }
        }

        withAnimation(.homeSpring(delay: 1.0, stiffness: 300, damping: 22)) {
            showHeroPercent = true
        }

        statsAnimationTask?.cancel()
        statsAnimationTask = Task {
            for index in state.quickStats.indices {
                let delay = index == 0 ? 200_000_000 : 100_000_000
                try? await Task.sleep(nanoseconds: UInt64(delay))
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.homeExpo(duration: 0.7)) {
                        visibleStatCardCount = index + 1
                    }
                }
            }
        }

        featuredDeckTitleAnimationTask?.cancel()
        featuredDeckTitleAnimationTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.homeExpo(duration: 0.5)) {
                    visibleFeaturedDeckTitle = featuredRecentDeck != nil
                }
            }
        }

        featuredDeckAnimationTask?.cancel()
        featuredDeckAnimationTask = Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.homeExpo(duration: 0.52)) {
                    visibleFeaturedDeck = featuredRecentDeck != nil
                }
            }
        }

        deckAnimationTask?.cancel()
        deckAnimationTask = Task {
            for index in visibleRecentDecks.indices {
                let delay = index == 0 ? 280_000_000 : 250_000_000
                try? await Task.sleep(nanoseconds: UInt64(delay))
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.homeExpo(duration: 0.52)) {
                        visibleDeckCardCount = index + 1
                    }
                }
            }
        }
    }

    private func animateHeroProgressToCurrentState() {
        heroProgressTask?.cancel()
        heroProgressTask = Task {
            // Animate ring down to zero
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.25)) {
                    animatedHeroProgress = 0
                }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            // Animate ring back up to the new progress value
            await MainActor.run {
                withAnimation(.homeExpo(duration: 1.0)) {
                    animatedHeroProgress = state.progress
                }
            }
        }
    }

    private var initialHeroProgress: Double {
        0
    }

    private func handlePrimaryAction() {
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
