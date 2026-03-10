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
    @State private var visibleDeckCardCount = 0

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
        .onChange(of: locale.identifier) { _, _ in
            viewModel.load(using: modelContext, forceRefresh: true)
        }
        .onChange(of: dailyGoalCardsStorage) { _, _ in
            viewModel.load(using: modelContext, forceRefresh: true)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            viewModel.load(using: modelContext, forceRefresh: true)
        }
        .onChange(of: state.progress) { _, newValue in
            if hasStartedEntryAnimation {
                withAnimation(.homeExpo(duration: 1.0)) {
                    animatedHeroProgress = newValue
                }
            }
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

    private var visibleRecentDecks: [RecentDeck] {
        Array(state.recentDecks.prefix(3))
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
                .offset(y: hasAnimatedIn ? 0 : 8)
                .opacity(hasAnimatedIn ? 1 : 0)
                .animation(.homeExpo(duration: 0.4, delay: 0.2 + (Double(index) * 0.05)), value: hasAnimatedIn)
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

        withAnimation(.homeExpo(duration: 0.6)) {
            hasAnimatedIn = true
        }

        withAnimation(.homeExpo(duration: 1.4, delay: 0.6)) {
            animatedHeroProgress = state.progress
        }

        withAnimation(.homeSpring(delay: 1.0, stiffness: 300, damping: 22)) {
            showHeroPercent = true
        }

        Task {
            for index in visibleRecentDecks.indices {
                let delay = index == 0 ? 280_000_000 : 250_000_000
                try? await Task.sleep(nanoseconds: UInt64(delay))
                await MainActor.run {
                    withAnimation(.homeExpo(duration: 0.52)) {
                        visibleDeckCardCount = index + 1
                    }
                }
            }
        }
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

private struct HomeHeroCard: View {
    let locale: Locale
    let colorScheme: ColorScheme
    let completedCards: Int
    let goalCards: Int
    let progress: Double
    let showProgressNumber: Bool
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(heroTrackColor, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(
                        color: progressGlowColor,
                        radius: colorScheme == .dark ? 8 : 4,
                        x: 0,
                        y: 0
                    )

                VStack(spacing: 1) {
                    percentageText
                        .scaleEffect(showProgressNumber ? 1 : 0.5)
                        .opacity(showProgressNumber ? 1 : 0)

                    Text(AppCopy.text(locale, en: "GOAL", es: "META"))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(NColors.Text.textTertiary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .semibold))
                    Text(AppCopy.text(locale, en: "TODAY'S SESSION", es: "SESIÓN DE HOY"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.0)
                }
                .foregroundStyle(NColors.Text.textTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(completedCards)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text("/\(goalCards)")
                            .font(.system(size: 20, weight: .regular, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                    }

                    Text(AppCopy.text(locale, en: "cards completed", es: "tarjetas completadas"))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(NColors.Text.textSecondary)
                }

                NGradientButton(
                    actionTitle,
                    leadingSymbolName: "sparkles",
                    showsChevron: false,
                    animateEffects: true,
                    font: .system(size: 16, weight: .bold, design: .rounded),
                    height: 44,
                    cornerRadius: 14,
                    gradientColors: colorScheme == .dark
                        ? [NColors.Brand.accentBlueStrong, NColors.Brand.neuroBlueDeep]
                        : [
                            Color(red: 0.24, green: 0.50, blue: 0.90),
                            Color(red: 0.30, green: 0.46, blue: 0.87),
                            Color(red: 0.39, green: 0.27, blue: 0.82)
                        ]
                ) {
                    onAction()
                }
                .frame(width: 196, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 128)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(
            color: colorScheme == .dark
                ? NColors.Brand.neuroBlue.opacity(0.14)
                : NColors.Brand.neuroBlue.opacity(0.10),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    NColors.Surface.raised.opacity(0.94),
                    NColors.Brand.neuroBlue.opacity(0.16),
                    NColors.Brand.neuroBlueDeep.opacity(0.18)
                ]
                : [
                    Color(red: 0.90, green: 0.93, blue: 0.99).opacity(0.92),
                    Color(red: 0.82, green: 0.88, blue: 0.99).opacity(0.86),
                    Color(red: 0.79, green: 0.82, blue: 0.98).opacity(0.88),
                    Color(red: 0.82, green: 0.76, blue: 0.98).opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : NColors.Stroke.standard.opacity(0.48),
                lineWidth: 1
            )
    }

    private var heroTrackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.09)
            : NColors.Surface.subdued.opacity(0.82)
    }

    private var percentageText: some View {
        let percentage = Int((min(max(progress, 0), 1) * 100).rounded())
        let number = "\(percentage)"
        let suffix = "%"

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(number)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(suffix)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.30, green: 0.63, blue: 0.95),
                    Color(red: 0.40, green: 0.49, blue: 0.96),
                    Color(red: 0.50, green: 0.34, blue: 0.95),
                    Color(red: 0.30, green: 0.63, blue: 0.95)
                ]
                : [
                    Color(red: 0.24, green: 0.50, blue: 0.90),
                    Color(red: 0.30, green: 0.46, blue: 0.87),
                    Color(red: 0.39, green: 0.27, blue: 0.82),
                    Color(red: 0.24, green: 0.50, blue: 0.90)
                ],
            center: .center
        )
    }

    private var progressGlowColor: Color {
        colorScheme == .dark
            ? NColors.Brand.neuroBlue.opacity(0.30)
            : NColors.Brand.neuroBlue.opacity(0.16)
    }
}

private struct HomeCompactStatCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let stat: QuickStat
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: stat.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(stat.iconColor)

            Text(stat.value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(NColors.Text.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? NColors.Surface.base.opacity(0.86) : Color.white.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : NColors.Stroke.standard.opacity(0.46), lineWidth: 1)
        )
    }
}

private struct HomeRecentDeckCard: View {
    let locale: Locale
    let deck: RecentDeck
    let isFeatured: Bool
    let colorScheme: ColorScheme
    let showFeaturedBadge: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: isFeatured ? 1.2 : 1)
                )
                .overlay(alignment: .leading) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: deck.subjectIconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(deck.accentColor)
                            .frame(width: 26, height: 26)
                            .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(deck.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textPrimary)

                                Text(deck.subjectPathText)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textSecondary)
                                    .lineLimit(1)
                            }

                            HStack(alignment: .center, spacing: 12) {
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule(style: .continuous)
                                            .fill(progressTrackColor)
                                            .frame(height: 3)

                                        Capsule(style: .continuous)
                                            .fill(deck.accentColor)
                                            .frame(
                                                width: showFeaturedBadge
                                                    ? max(proxy.size.width * deck.completionProgress, deck.completionProgress > 0 ? 18 : 0)
                                                    : 0,
                                                height: 3
                                            )
                                            .animation(.homeExpo(duration: 1.0, delay: 0.6), value: showFeaturedBadge)
                                    }
                                }
                                .frame(height: 3)

                                Text(deck.completionPercentText)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textSecondary.opacity(0.95))
                            }
                        }

                        VStack(spacing: 3) {
                            Text("\(deck.readyCount)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.96))
                                .frame(width: 33, height: 33)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(deck.accentColor)
                                )

                            Text(AppCopy.text(locale, en: "PEND.", es: "PEND."))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(NColors.Text.textTertiary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 17)
                }
                .frame(minHeight: 106)

            if isFeatured {
                HomeFeaturedBadge(locale: locale)
                    .padding(.top, -8)
                    .padding(.trailing, 20)
                    .offset(y: showFeaturedBadge ? 0 : -5)
                    .scaleEffect(showFeaturedBadge ? 1 : 0.8)
                    .opacity(showFeaturedBadge ? 1 : 0)
                    .animation(.homeSpring(delay: 0.6, stiffness: 300, damping: 24), value: showFeaturedBadge)
            }
        }
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [NColors.Surface.base.opacity(0.89), NColors.Surface.raised.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if isFeatured {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.90), NColors.Surface.accentSoft.opacity(0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.white.opacity(0.72))
    }

    private var cardBorderColor: Color {
        if isFeatured {
            return deck.accentColor.opacity(colorScheme == .dark ? 0.46 : 0.58)
        }
        return colorScheme == .dark ? Color.white.opacity(0.045) : NColors.Stroke.standard.opacity(0.42)
    }

    private var progressTrackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.06)
    }
}

private struct HomeFeaturedBadge: View {
    let locale: Locale

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .bold))
            Text(AppCopy.text(locale, en: "FOR YOU", es: "PARA TI"))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
        }
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, 11)
        .frame(height: 20)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [NColors.Brand.accentBlueStrong, NColors.Brand.neuroBlueDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
        )
        .shadow(color: NColors.Brand.neuroBlue.opacity(0.24), radius: 10, x: 0, y: 4)
    }
}

private struct HomeTipCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let locale: Locale
    let title: String
    let message: String

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : NColors.Stroke.standard.opacity(0.50), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 136)
            .overlay(alignment: .leading) {
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "lightbulb")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(NColors.Brand.accentBlue)
                        )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text(message)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(NColors.Text.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            tipChip(AppCopy.text(locale, en: "PRODUCTIVITY", es: "PRODUCTIVIDAD"))
                            tipChip("POMODORO")
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 17)
            }
    }

    private var cardBackground: some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        NColors.Surface.base.opacity(0.88),
                        NColors.Brand.neuroBlue.opacity(0.06),
                        NColors.Brand.neuroBlueDeep.opacity(0.08)
                    ]
                    : [
                        Color.white.opacity(0.82),
                        NColors.Surface.base.opacity(0.94),
                        NColors.Brand.neuroBlueDeep.opacity(0.05)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var iconBackground: Color {
        colorScheme == .dark ? NColors.Surface.accentSoft.opacity(0.34) : NColors.Surface.accentSoft.opacity(0.78)
    }

    private func tipChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(NColors.Brand.accentBlue)
            .padding(.horizontal, 10)
            .frame(height: 20)
            .background(
                Capsule(style: .continuous)
                    .fill(iconBackground)
            )
    }
}

private extension Animation {
    static func homeExpo(duration: Double, delay: Double = 0) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration).delay(delay)
    }

    static func homeSpring(delay: Double = 0, stiffness: Double = 300, damping: Double = 22) -> Animation {
        .interpolatingSpring(stiffness: stiffness, damping: damping).delay(delay)
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
