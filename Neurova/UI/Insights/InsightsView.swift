import SwiftData
import SwiftUI

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @State private var viewModel = InsightsViewModel()
    @State private var showHeaderSubtitle = false
    @State private var showTopCards = false
    @State private var showStatsContainer = false
    @State private var visibleStatCards: [Bool] = Array(repeating: false, count: 3)
    @State private var visibleStatNumbers: [Bool] = Array(repeating: false, count: 3)
    @State private var showDifficulty = false
    @State private var visibleDifficultyCells: [Bool] = Array(repeating: false, count: 4)
    @State private var showDeckHealth = false
    @State private var visibleDeckRows: [Bool] = []
    @State private var visibleDeckScores: [Bool] = []
    @State private var showActivity = false
    @State private var visibleActivityBars: [Bool] = Array(repeating: false, count: 7)

    @State private var animatedXPProgress: Double = 0
    @State private var animatedGoalProgress: Double = 0
    @State private var animatedDeckProgress: [Double] = []
    @State private var animatedActivityHeights: [CGFloat] = Array(repeating: 0, count: 7)

    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    topCardsGrid
                    statsRow
                    difficultyCard
                    deckHealthCard
                    activityCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle(AppCopy.text(locale, en: "Insights", es: "Insights"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.load(using: modelContext)
            await restartAnimations()
        }
    }

    private var header: some View {
        Text(AppCopy.text(locale, en: "This week", es: "Esta semana"))
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(secondaryText)
            .opacity(showHeaderSubtitle ? 1 : 0)
    }

    private var topCardsGrid: some View {
        HStack(spacing: 14) {
            levelCard
            goalCard
        }
        .opacity(showTopCards ? 1 : 0)
        .scaleEffect(showTopCards ? 1 : 0.97)
        .offset(y: showTopCards ? 0 : 20)
    }

    private var levelCard: some View {
        insightCard(
            background: topLeftCardFill,
            minHeight: 124
        ) {
            VStack(alignment: .leading, spacing: 14) {
                labelRow(
                    icon: "bolt",
                    color: NColors.Brand.neuroBlue,
                    title: "\(AppCopy.text(locale, en: "Level", es: "Nivel")) \(viewModel.currentLevel)"
                )

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(viewModel.totalXP)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)

                    Text("XP")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryText)
                }

                progressTrack(progress: animatedXPProgress, fill: splashGradient)

                Text("\(viewModel.xpToNextLevel) \(AppCopy.text(locale, en: "XP to level up", es: "XP para subir"))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var goalCard: some View {
        insightCard(
            background: topRightCardFill,
            minHeight: 124
        ) {
            VStack(alignment: .leading, spacing: 14) {
                labelRow(
                    icon: "target",
                    color: Color(red: 0.67, green: 0.37, blue: 0.95),
                    title: AppCopy.text(locale, en: "Goal", es: "Meta")
                )

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(viewModel.todayProgress)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)

                    Text("/\(viewModel.dailyGoal)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryText)
                }

                progressTrack(progress: animatedGoalProgress, fill: splashGradient)

                Text(AppCopy.text(locale, en: "cards today", es: "tarjetas hoy"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(statsItems.enumerated()), id: \.offset) { index, item in
                statCard(item: item, index: index)
            }
        }
        .opacity(showStatsContainer ? 1 : 0)
        .offset(y: showStatsContainer ? 0 : 15)
    }

    private func statCard(item: StatItem, index: Int) -> some View {
        insightCard(background: baseCardFill, minHeight: 102) {
            VStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.color)

                Text(item.value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .opacity(numberVisible(at: index) ? 1 : 0)
                    .scaleEffect(numberVisible(at: index) ? 1 : 0.5)

                Text(item.label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .kerning(0.3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(cardVisible(at: index) ? 1 : 0)
        .scaleEffect(cardVisible(at: index) ? 1 : 0.95)
        .offset(y: cardVisible(at: index) ? 0 : 12)
    }

    private var difficultyCard: some View {
        insightCard(background: baseCardFill, minHeight: 180) {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(
                    AppCopy.text(locale, en: "Difficulty", es: "Dificultad"),
                    subtitle: AppCopy.text(locale, en: "Last 7 days", es: "Ultimos 7 dias")
                )

                HStack(spacing: 10) {
                    ForEach(Array(difficultyItems.enumerated()), id: \.offset) { index, item in
                        difficultyCell(item: item, index: index)
                    }
                }
            }
        }
        .opacity(showDifficulty ? 1 : 0)
        .offset(y: showDifficulty ? 0 : 18)
    }

    private func difficultyCell(item: DifficultyItem, index: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(item.color)

            Text(item.value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)

            Text(item.label)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(secondaryText)
                .kerning(0.2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cellFill)
        )
        .opacity(difficultyVisible(at: index) ? 1 : 0)
        .scaleEffect(difficultyVisible(at: index) ? 1 : 0.85)
    }

    private var deckHealthCard: some View {
        insightCard(background: baseCardFill, minHeight: 220) {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(
                    AppCopy.text(locale, en: "Deck Health", es: "Salud de Mazos"),
                    subtitle: AppCopy.text(locale, en: "Performance by deck", es: "Rendimiento por mazo")
                )

                VStack(spacing: 18) {
                    ForEach(Array(deckHealthRows.enumerated()), id: \.offset) { index, row in
                        deckHealthRow(row: row, index: index)
                    }
                }
            }
        }
        .opacity(showDeckHealth ? 1 : 0)
        .offset(y: showDeckHealth ? 0 : 18)
    }

    private func deckHealthRow(row: DeckHealthRow, index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text(row.shortTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)

                    Text(row.label)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(row.color)
                        .kerning(0.2)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(progressTrackColor)

                        Capsule(style: .continuous)
                            .fill(row.color)
                            .frame(width: geometry.size.width * clamped(progressValue(at: index)))
                    }
                }
                .frame(height: 4)
            }

            Spacer(minLength: 8)

            Text("\(row.score)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(row.color)
                .scaleEffect(scoreVisible(at: index) ? 1 : 0)
        }
        .opacity(deckRowVisible(at: index) ? 1 : 0)
        .offset(x: deckRowVisible(at: index) ? 0 : -10)
    }

    private var activityCard: some View {
        insightCard(background: baseCardFill, minHeight: 190) {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(
                    AppCopy.text(locale, en: "Last 7 Days", es: "Ultimos 7 Dias"),
                    subtitle: AppCopy.text(locale, en: "Review activity", es: "Actividad de repaso")
                )

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(activityItems.enumerated()), id: \.offset) { index, bar in
                        activityBar(bar: bar, index: index)
                    }
                }
                .frame(height: 96, alignment: .bottom)
            }
        }
        .opacity(showActivity ? 1 : 0)
        .offset(y: showActivity ? 0 : 18)
    }

    private func activityBar(bar: ActivityItem, index: Int) -> some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(bar.isToday ? AnyShapeStyle(splashGradient) : AnyShapeStyle(progressTrackColor.opacity(0.7)))
                .frame(width: 30, height: animatedBarHeight(at: index, maxHeight: 72))

            Text(bar.label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(bar.isToday ? NColors.Brand.neuroBlue : secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func insightCard<Content: View>(
        background: LinearGradient,
        minHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: cardShadowPrimary, radius: 22, x: 0, y: 14)
            .shadow(color: cardShadowSecondary, radius: 8, x: 0, y: 2)
    }

    private func labelRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)

            Text(title.uppercased())
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(secondaryText)
                .kerning(0.35)
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)

            Text(subtitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(secondaryText)
        }
    }

    private func progressTrack(progress: Double, fill: LinearGradient) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(progressTrackColor)

                Capsule(style: .continuous)
                    .fill(fill)
                    .frame(width: geometry.size.width * clamped(progress))
            }
        }
        .frame(height: 4)
    }

    private var statsItems: [StatItem] {
        [
            .init(
                icon: "flame",
                color: Color(red: 0.98, green: 0.56, blue: 0.23),
                value: "\(viewModel.currentStreak)",
                label: AppCopy.text(locale, en: "STREAK", es: "RACHA")
            ),
            .init(
                icon: "timer",
                color: NColors.Brand.neuroBlue,
                value: "\(viewModel.totalDueCards)",
                label: AppCopy.text(locale, en: "READY", es: "LISTO")
            ),
            .init(
                icon: "cube.transparent",
                color: Color(red: 0.49, green: 0.35, blue: 0.96),
                value: "\(viewModel.totalNewCards)",
                label: AppCopy.text(locale, en: "NEW", es: "NUEVO")
            )
        ]
    }

    private var difficultyItems: [DifficultyItem] {
        [
            .init(icon: "tortoise", color: NColors.Feedback.warning, value: percentageText(viewModel.hardRate), label: AppCopy.text(locale, en: "HARD", es: "DIFICIL")),
            .init(icon: "checkmark.circle", color: NColors.Brand.neuroBlue, value: percentageText(viewModel.goodRate), label: AppCopy.text(locale, en: "GOOD", es: "BIEN")),
            .init(icon: "star", color: NColors.Feedback.success, value: percentageText(viewModel.easyRate), label: AppCopy.text(locale, en: "EASY", es: "FACIL")),
            .init(icon: "forward", color: secondaryText, value: percentageText(viewModel.skipRate), label: AppCopy.text(locale, en: "SKIP", es: "SALTAR"))
        ]
    }

    private var deckHealthRows: [DeckHealthRow] {
        let rows = viewModel.topDeckHealth.prefix(3).map { deck in
            DeckHealthRow(
                id: deck.id,
                shortTitle: shortDeckTitle(deck.deckTitle),
                fullTitle: deck.deckTitle,
                score: deck.score,
                label: healthLabel(for: deck.score).uppercased(),
                color: healthScoreColor(for: deck.score)
            )
        }

        if rows.isEmpty {
            return [
                .init(id: UUID(), shortTitle: "D", fullTitle: "Deck", score: 0, label: AppCopy.text(locale, en: "No Data", es: "Sin Datos").uppercased(), color: secondaryText)
            ]
        }

        return rows
    }

    private var activityItems: [ActivityItem] {
        if viewModel.activityBars.isEmpty {
            let labels = ["L", "M", "X", "J", "V", "S", "D"]
            return labels.enumerated().map { index, label in
                ActivityItem(label: label, normalizedHeight: 0.08, isToday: index == 6)
            }
        }

        return viewModel.activityBars.map { bar in
            ActivityItem(label: bar.label, normalizedHeight: max(bar.normalizedHeight, 0.08), isToday: bar.isToday)
        }
    }

    private func restartAnimations() async {
        resetAnimations()

        schedule(after: 0.08) {
            withAnimation(expoAnimation(duration: 0.6)) {
                showTopCards = true
            }
        }

        schedule(after: 0.10) {
            withAnimation(.easeOut(duration: 0.3)) {
                showHeaderSubtitle = true
            }
        }

        schedule(after: 0.16) {
            withAnimation(expoAnimation(duration: 0.5)) {
                showStatsContainer = true
            }
        }

        schedule(after: 0.20) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setCardVisible(true, at: 0)
            }
        }

        schedule(after: 0.26) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setCardVisible(true, at: 1)
            }
        }

        schedule(after: 0.28) {
            withAnimation(expoAnimation(duration: 0.5)) {
                showDifficulty = true
            }
        }

        schedule(after: 0.32) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setCardVisible(true, at: 2)
            }
        }

        schedule(after: 0.36) {
            withAnimation(expoAnimation(duration: 0.4)) {
                setDifficultyVisible(true, at: 0)
            }
        }

        schedule(after: 0.38) {
            withAnimation(expoAnimation(duration: 0.5)) {
                showDeckHealth = true
            }
        }

        schedule(after: 0.40) {
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 22)) {
                setNumberVisible(true, at: 0)
            }
        }

        schedule(after: 0.42) {
            withAnimation(expoAnimation(duration: 0.4)) {
                setDifficultyVisible(true, at: 1)
            }
        }

        schedule(after: 0.45) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setDeckRowVisible(true, at: 0)
            }
        }

        schedule(after: 0.48) {
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 22)) {
                setNumberVisible(true, at: 1)
            }
            withAnimation(expoAnimation(duration: 0.4)) {
                setDifficultyVisible(true, at: 2)
                showActivity = true
            }
        }

        schedule(after: 0.50) {
            withAnimation(expoAnimation(duration: 1.2)) {
                animatedXPProgress = clamped(viewModel.levelProgress)
            }
        }

        schedule(after: 0.52) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setDeckRowVisible(true, at: 1)
            }
        }

        schedule(after: 0.54) {
            withAnimation(expoAnimation(duration: 0.4)) {
                setDifficultyVisible(true, at: 3)
            }
        }

        schedule(after: 0.55) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                setDeckScoreVisible(true, at: 0)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 0)
            }
        }

        schedule(after: 0.56) {
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 22)) {
                setNumberVisible(true, at: 2)
            }
        }

        schedule(after: 0.59) {
            withAnimation(expoAnimation(duration: 0.5)) {
                setDeckRowVisible(true, at: 2)
            }
        }

        schedule(after: 0.60) {
            withAnimation(expoAnimation(duration: 1.2)) {
                animatedGoalProgress = clamped(goalProgress)
            }
            withAnimation(expoAnimation(duration: 1.0)) {
                setDeckProgress(clamped(deckProgressTarget(at: 0)), at: 0)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 1)
            }
        }

        schedule(after: 0.65) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                setDeckScoreVisible(true, at: 1)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 2)
            }
        }

        schedule(after: 0.70) {
            withAnimation(expoAnimation(duration: 1.0)) {
                setDeckProgress(clamped(deckProgressTarget(at: 1)), at: 1)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 3)
            }
        }

        schedule(after: 0.75) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                setDeckScoreVisible(true, at: 2)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 4)
            }
        }

        schedule(after: 0.80) {
            withAnimation(expoAnimation(duration: 1.0)) {
                setDeckProgress(clamped(deckProgressTarget(at: 2)), at: 2)
            }
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 5)
            }
        }

        schedule(after: 0.85) {
            withAnimation(expoAnimation(duration: 0.8)) {
                setActivityBarVisible(true, at: 6)
            }
        }
    }

    private func resetAnimations() {
        showHeaderSubtitle = false
        showTopCards = false
        showStatsContainer = false
        visibleStatCards = Array(repeating: false, count: 3)
        visibleStatNumbers = Array(repeating: false, count: 3)
        showDifficulty = false
        visibleDifficultyCells = Array(repeating: false, count: 4)
        showDeckHealth = false
        visibleDeckRows = Array(repeating: false, count: deckHealthRows.count)
        visibleDeckScores = Array(repeating: false, count: deckHealthRows.count)
        showActivity = false
        visibleActivityBars = Array(repeating: false, count: max(activityItems.count, 7))
        animatedXPProgress = 0
        animatedGoalProgress = 0
        animatedDeckProgress = Array(repeating: 0, count: deckHealthRows.count)
        animatedActivityHeights = Array(repeating: 0, count: max(activityItems.count, 7))
    }

    private func schedule(after delay: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }

    private func expoAnimation(duration: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }

    private var goalProgress: Double {
        guard viewModel.dailyGoal > 0 else { return 0 }
        return Double(viewModel.todayProgress) / Double(viewModel.dailyGoal)
    }

    private func percentageText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func shortDeckTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "D" }
        return String(first).uppercased()
    }

    private func healthScoreColor(for score: Int) -> Color {
        switch score {
        case ..<45:
            return NColors.Feedback.warning
        case ..<85:
            return NColors.Feedback.success
        default:
            return NColors.Feedback.success
        }
    }

    private func healthLabel(for score: Int) -> String {
        switch score {
        case ..<45:
            return AppCopy.text(locale, en: "Watch", es: "Vigilar")
        case ..<85:
            return AppCopy.text(locale, en: "Healthy", es: "Saludable")
        default:
            return AppCopy.text(locale, en: "Strong", es: "Fuerte")
        }
    }

    private func cardVisible(at index: Int) -> Bool {
        visibleStatCards.indices.contains(index) ? visibleStatCards[index] : false
    }

    private func numberVisible(at index: Int) -> Bool {
        visibleStatNumbers.indices.contains(index) ? visibleStatNumbers[index] : false
    }

    private func difficultyVisible(at index: Int) -> Bool {
        visibleDifficultyCells.indices.contains(index) ? visibleDifficultyCells[index] : false
    }

    private func deckRowVisible(at index: Int) -> Bool {
        visibleDeckRows.indices.contains(index) ? visibleDeckRows[index] : false
    }

    private func scoreVisible(at index: Int) -> Bool {
        visibleDeckScores.indices.contains(index) ? visibleDeckScores[index] : false
    }

    private func progressValue(at index: Int) -> Double {
        animatedDeckProgress.indices.contains(index) ? animatedDeckProgress[index] : 0
    }

    private func animatedBarHeight(at index: Int, maxHeight: CGFloat) -> CGFloat {
        let normalized = animatedActivityHeights.indices.contains(index) ? animatedActivityHeights[index] : 0
        return max(6, maxHeight * normalized)
    }

    private func deckProgressTarget(at index: Int) -> Double {
        guard deckHealthRows.indices.contains(index) else { return 0 }
        return Double(deckHealthRows[index].score) / 100
    }

    private func setCardVisible(_ value: Bool, at index: Int) {
        guard visibleStatCards.indices.contains(index) else { return }
        visibleStatCards[index] = value
    }

    private func setNumberVisible(_ value: Bool, at index: Int) {
        guard visibleStatNumbers.indices.contains(index) else { return }
        visibleStatNumbers[index] = value
    }

    private func setDifficultyVisible(_ value: Bool, at index: Int) {
        guard visibleDifficultyCells.indices.contains(index) else { return }
        visibleDifficultyCells[index] = value
    }

    private func setDeckRowVisible(_ value: Bool, at index: Int) {
        guard visibleDeckRows.indices.contains(index) else { return }
        visibleDeckRows[index] = value
    }

    private func setDeckScoreVisible(_ value: Bool, at index: Int) {
        guard visibleDeckScores.indices.contains(index) else { return }
        visibleDeckScores[index] = value
    }

    private func setDeckProgress(_ value: Double, at index: Int) {
        guard animatedDeckProgress.indices.contains(index) else { return }
        animatedDeckProgress[index] = value
    }

    private func setActivityBarVisible(_ value: Bool, at index: Int) {
        guard visibleActivityBars.indices.contains(index), animatedActivityHeights.indices.contains(index), activityItems.indices.contains(index) else { return }
        visibleActivityBars[index] = value
        animatedActivityHeights[index] = value ? activityItems[index].normalizedHeight : 0
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private var primaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.96) : Color.white.opacity(0.96)
    }

    private var secondaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.42) : Color.white.opacity(0.44)
    }

    private var baseCardFill: LinearGradient {
        if colorScheme == .light {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.58),
                    Color.white.opacity(0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.10, blue: 0.15),
                Color(red: 0.07, green: 0.08, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topLeftCardFill: LinearGradient {
        if colorScheme == .light {
            return LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.97, blue: 0.99),
                    Color(red: 0.92, green: 0.93, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.11, blue: 0.17),
                Color(red: 0.09, green: 0.10, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topRightCardFill: LinearGradient {
        if colorScheme == .light {
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.98),
                    Color(red: 0.93, green: 0.92, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.11, blue: 0.18),
                Color(red: 0.09, green: 0.09, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorder: Color {
        colorScheme == .light
            ? Color.black.opacity(0.07)
            : Color.white.opacity(0.08)
    }

    private var cardShadowPrimary: Color {
        colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.28)
    }

    private var cardShadowSecondary: Color {
        colorScheme == .light ? Color.white.opacity(0.55) : Color.white.opacity(0.02)
    }

    private var cellFill: Color {
        colorScheme == .light ? Color.white.opacity(0.34) : Color.white.opacity(0.025)
    }

    private var progressTrackColor: Color {
        colorScheme == .light ? Color.black.opacity(0.07) : Color.white.opacity(0.05)
    }

    private var splashGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.31, green: 0.58, blue: 0.99),
                Color(red: 0.54, green: 0.30, blue: 0.95)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var backgroundView: LinearGradient {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(red: 0.96, green: 0.96, blue: 0.97),
                    Color(red: 0.93, green: 0.93, blue: 0.95)
                ]
                : [
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    Color(red: 0.02, green: 0.03, blue: 0.07)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct StatItem {
    let icon: String
    let color: Color
    let value: String
    let label: String
}

private struct DifficultyItem {
    let icon: String
    let color: Color
    let value: String
    let label: String
}

private struct DeckHealthRow: Identifiable {
    let id: UUID
    let shortTitle: String
    let fullTitle: String
    let score: Int
    let label: String
    let color: Color
}

private struct ActivityItem {
    let label: String
    let normalizedHeight: CGFloat
    let isToday: Bool
}

#Preview("Insights Light") {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
    .preferredColorScheme(.light)
}

#Preview("Insights Dark") {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
    .preferredColorScheme(.dark)
}
