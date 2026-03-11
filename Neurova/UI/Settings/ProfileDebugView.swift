import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \CloudAccountProfile.updatedAt, order: .reverse) private var profiles: [CloudAccountProfile]
    @Query(sort: \Subject.createdAt, order: .forward) private var subjects: [Subject]
    @Query(sort: \Deck.createdAt, order: .forward) private var decks: [Deck]
    @Query(sort: \Card.createdAt, order: .forward) private var cards: [Card]
    @Query(sort: \XPEventEntity.date, order: .forward) private var xpEvents: [XPEventEntity]

    @State private var hasAnimatedIn = false
    @State private var showTitle = false
    @State private var showAvatarCard = false
    @State private var showAvatarGlyph = false
    @State private var showName = false
    @State private var showEmail = false
    @State private var showMemberBadge = false
    @State private var showStatsContainer = false
    @State private var visibleStats: Set<Int> = []
    @State private var showAchievementsContainer = false
    @State private var visibleAchievements: Set<Int> = []
    @State private var visibleBadges: Set<Int> = []
    @State private var showDeleteButton = false
    @State private var showVersion = false
    @State private var shimmerActive = false

    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    avatarCard
                        .padding(.top, 18)
                        .padding(.horizontal, 22)

                    statsGrid
                        .padding(.top, 18)
                        .padding(.horizontal, 22)

                    achievementsSection
                        .padding(.top, 20)
                        .padding(.horizontal, 22)

                    deleteAccountButton
                        .padding(.top, 24)
                        .padding(.horizontal, 22)

                    versionLabel
                        .padding(.top, 28)
                        .padding(.bottom, 136)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await runEntryAnimationsIfNeeded()
        }
    }

    private var profileSnapshot: ProfileSnapshot {
        ProfileSnapshot(
            profile: profiles.first(where: { $0.key == "primary" }) ?? profiles.first,
            subjects: subjects,
            decks: decks.filter { !$0.isArchived },
            cards: cards,
            xpEvents: xpEvents
        )
    }

    private var avatarCard: some View {
        let snapshot = profileSnapshot

        return HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: avatarGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(snapshot.avatarLetter)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(showAvatarGlyph ? 1 : 0.01)
                    .rotationEffect(.degrees(showAvatarGlyph ? 0 : -20))
                    .animation(
                        .interpolatingSpring(stiffness: 250, damping: 18),
                        value: showAvatarGlyph
                    )
            }
            .frame(width: 68, height: 68)
            .shadow(color: avatarGlowColor, radius: colorScheme == .dark ? 18 : 10, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 7) {
                Text(snapshot.displayName)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
                    .opacity(showName ? 1 : 0)
                    .offset(x: showName ? 0 : 10)
                    .animation(Self.easeOutExpo(duration: 0.45), value: showName)

                HStack(spacing: 7) {
                    Image(systemName: "envelope")
                        .font(.system(size: 12, weight: .semibold))
                    Text(snapshot.email)
                        .lineLimit(1)
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(secondaryTextColor)
                .opacity(showEmail ? 1 : 0)
                .offset(x: showEmail ? 0 : 10)
                .animation(Self.easeOutExpo(duration: 0.45), value: showEmail)

                Text(snapshot.memberSinceText)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(memberBadgeTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(memberBadgeBackground)
                    )
                    .opacity(showMemberBadge ? 1 : 0)
                    .animation(Self.easeOutExpo(duration: 0.35), value: showMemberBadge)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(avatarCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(avatarCardStroke, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: avatarCardShadow, radius: colorScheme == .dark ? 18 : 10, x: 0, y: 10)
        .opacity(showAvatarCard ? 1 : 0)
        .scaleEffect(showAvatarCard ? 1 : 0.97)
        .offset(y: showAvatarCard ? 0 : 20)
        .animation(Self.easeOutExpo(duration: 0.6), value: showAvatarCard)
    }

    private var statsGrid: some View {
        let stats = profileSnapshot.stats

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
            spacing: 10
        ) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                statCard(stat, index: index)
            }
        }
        .opacity(showStatsContainer ? 1 : 0)
        .offset(y: showStatsContainer ? 0 : 12)
        .animation(.easeOut(duration: 0.25), value: showStatsContainer)
    }

    private func statCard(_ stat: ProfileStat, index: Int) -> some View {
        let isVisible = visibleStats.contains(index)

        return VStack(spacing: 0) {
            Image(systemName: stat.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(stat.color)
                .padding(.top, 16)

            Spacer(minLength: 0)
                .frame(minHeight: 0, maxHeight: 13)

            Text(stat.value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(titleColor)

            Text(stat.label)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(tertiaryTextColor)
                .padding(.top, 7)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 106)
        .background(smallCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(smallCardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: smallCardShadow, radius: colorScheme == .dark ? 10 : 6, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .offset(y: isVisible ? 0 : 8)
        .animation(.easeOut(duration: 0.25), value: isVisible)
    }

    private var achievementsSection: some View {
        let snapshot = profileSnapshot

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                Text("Logros")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)

                Spacer(minLength: 0)

                Text("\(snapshot.earnedAchievementCount)/\(snapshot.achievements.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tertiaryTextColor)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(Array(snapshot.achievements.enumerated()), id: \.offset) { index, achievement in
                    achievementCard(achievement, index: index)
                }
            }
        }
        .opacity(showAchievementsContainer ? 1 : 0)
        .offset(y: showAchievementsContainer ? 0 : 14)
        .animation(.easeOut(duration: 0.25), value: showAchievementsContainer)
    }

    private func achievementCard(_ achievement: ProfileAchievement, index: Int) -> some View {
        let isVisible = visibleAchievements.contains(index)
        let showBadge = visibleBadges.contains(index) && achievement.isEarned

        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(achievementBackground(for: achievement))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(achievementStroke(for: achievement), lineWidth: achievement.isEarned ? 1.25 : 1)
                )
                .overlay {
                    if achievement.isEarned {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(goldShimmerColor.opacity(shimmerActive ? 0.82 : 0.42), lineWidth: 1.4)
                            .blur(radius: shimmerActive ? 0.2 : 1.8)
                            .animation(
                                .easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double(index) * 0.2),
                                value: shimmerActive
                            )
                    }
                }

            VStack(spacing: 0) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(achievementIconColor(for: achievement))
                    .padding(.top, 18)

                Spacer(minLength: 0)

                Text(achievement.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(achievementTitleColor(for: achievement))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)

            if achievement.isEarned {
                ZStack {
                    Circle()
                        .fill(goldBadgeFill)
                    Circle()
                        .stroke(goldBadgeStroke, lineWidth: 1.2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 18, height: 18)
                .offset(x: -6, y: 6)
                .scaleEffect(showBadge ? 1 : 0.01)
                .animation(.spring(), value: showBadge)
            }
        }
        .opacity(isVisible ? (achievement.isEarned ? 1 : 0.35) : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.interpolatingSpring(stiffness: 250, damping: 20), value: isVisible)
    }

    private var deleteAccountButton: some View {
        Button {
            print("borrando cuenta")
        } label: {
            Text("Eliminar cuenta")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(deleteTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(deleteBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(deleteStroke, lineWidth: 1)
                )
        }
        .buttonStyle(ProfilePressStyle(pressedScale: 0.98))
        .opacity(showDeleteButton ? 1 : 0)
        .offset(y: showDeleteButton ? 0 : 10)
        .animation(Self.easeOutExpo(duration: 0.45), value: showDeleteButton)
    }

    private var versionLabel: some View {
        Text("Neurova v1.0.0")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(tertiaryTextColor)
            .opacity(showVersion ? 0.4 : 0)
            .animation(Self.easeOutExpo(duration: 0.45), value: showVersion)
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.02, green: 0.03, blue: 0.08), Color(red: 0.03, green: 0.05, blue: 0.11)]
                : [Color(red: 0.94, green: 0.94, blue: 0.96), Color(red: 0.92, green: 0.92, blue: 0.94)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.96) : Color(red: 0.04, green: 0.07, blue: 0.14)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.48, green: 0.50, blue: 0.58) : Color(red: 0.47, green: 0.49, blue: 0.56)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.37, green: 0.40, blue: 0.51) : Color(red: 0.48, green: 0.49, blue: 0.56)
    }

    private var avatarGradient: [Color] {
        colorScheme == .dark
            ? [Color(red: 0.29, green: 0.59, blue: 0.97), Color(red: 0.48, green: 0.28, blue: 0.93)]
            : [Color(red: 0.28, green: 0.52, blue: 0.94), Color(red: 0.43, green: 0.29, blue: 0.90)]
    }

    private var avatarCardBackground: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.09, green: 0.12, blue: 0.23),
                    Color(red: 0.11, green: 0.12, blue: 0.21)
                ]
                : [
                    Color(red: 0.86, green: 0.88, blue: 0.93),
                    Color(red: 0.87, green: 0.86, blue: 0.92)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var avatarCardStroke: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.25, blue: 0.43)
            : Color(red: 0.77, green: 0.81, blue: 0.91)
    }

    private var avatarCardShadow: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.38, blue: 0.92).opacity(0.16)
            : Color.black.opacity(0.05)
    }

    private var avatarGlowColor: Color {
        colorScheme == .dark
            ? Color(red: 0.29, green: 0.54, blue: 0.94).opacity(0.22)
            : Color.clear
    }

    private var memberBadgeBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.09, green: 0.16, blue: 0.31)
            : Color(red: 0.80, green: 0.86, blue: 0.97)
    }

    private var memberBadgeTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.28, green: 0.56, blue: 0.98)
            : Color(red: 0.28, green: 0.51, blue: 0.92)
    }

    private var smallCardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.16)
            : Color(red: 0.94, green: 0.94, blue: 0.95)
    }

    private var smallCardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.80, green: 0.81, blue: 0.84)
    }

    private var smallCardShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.03)
    }

    private func achievementBackground(for achievement: ProfileAchievement) -> Color {
        if achievement.isEarned {
            return colorScheme == .dark
                ? Color(red: 0.12, green: 0.10, blue: 0.06)
                : Color(red: 0.97, green: 0.95, blue: 0.89)
        }
        return colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.16)
            : Color(red: 0.95, green: 0.95, blue: 0.96)
    }

    private func achievementStroke(for achievement: ProfileAchievement) -> Color {
        if achievement.isEarned {
            return colorScheme == .dark
                ? Color(red: 0.54, green: 0.39, blue: 0.05)
                : Color(red: 0.89, green: 0.73, blue: 0.33)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(red: 0.90, green: 0.90, blue: 0.92)
    }

    private var goldShimmerColor: Color {
        colorScheme == .dark
            ? Color(red: 0.91, green: 0.72, blue: 0.18)
            : Color(red: 0.90, green: 0.70, blue: 0.22)
    }

    private var goldBadgeFill: Color {
        Color(red: 0.92, green: 0.70, blue: 0.20)
    }

    private var goldBadgeStroke: Color {
        colorScheme == .dark
            ? Color(red: 0.99, green: 0.87, blue: 0.46)
            : Color(red: 0.86, green: 0.63, blue: 0.16)
    }

    private var deleteBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.16)
            : Color(red: 0.94, green: 0.94, blue: 0.95)
    }

    private var deleteStroke: Color {
        colorScheme == .dark
            ? Color(red: 0.35, green: 0.38, blue: 0.46).opacity(0.48)
            : Color(red: 0.78, green: 0.79, blue: 0.83)
    }

    private var deleteTextColor: Color {
        Color(red: 0.90, green: 0.31, blue: 0.25)
    }

    private func achievementIconColor(for achievement: ProfileAchievement) -> Color {
        achievement.isEarned ? darkGoldColor : mutedGoldColor
    }

    private func achievementTitleColor(for achievement: ProfileAchievement) -> Color {
        if achievement.isEarned {
            return darkGoldColor
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.34)
            : Color.black.opacity(0.62)
    }

    private var darkGoldColor: Color {
        Color(red: 0.72, green: 0.52, blue: 0.09)
    }

    private var mutedGoldColor: Color {
        colorScheme == .dark
            ? Color(red: 0.63, green: 0.47, blue: 0.14)
            : Color(red: 0.78, green: 0.58, blue: 0.18)
    }

    private func runEntryAnimationsIfNeeded() async {
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true

        shimmerActive = true

        withAnimation(Self.easeOutExpo(duration: 0.5)) {
            showTitle = true
        }

        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(Self.easeOutExpo(duration: 0.6)) {
            showAvatarCard = true
        }

        try? await Task.sleep(for: .milliseconds(70))
        withAnimation(.easeOut(duration: 0.25)) {
            showStatsContainer = true
        }

        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 18)) {
            showAvatarGlyph = true
        }

        try? await Task.sleep(for: .milliseconds(50))
        _ = withAnimation(.easeOut(duration: 0.25)) {
            visibleStats.insert(0)
        }

        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(Self.easeOutExpo(duration: 0.4)) {
            showName = true
        }
        _ = withAnimation(.easeOut(duration: 0.25)) {
            visibleStats.insert(1)
        }

        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(Self.easeOutExpo(duration: 0.4)) {
            showEmail = true
        }
        _ = withAnimation(.easeOut(duration: 0.25)) {
            visibleStats.insert(2)
        }

        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(Self.easeOutExpo(duration: 0.35)) {
            showMemberBadge = true
        }
        _ = withAnimation(.easeOut(duration: 0.25)) {
            visibleStats.insert(3)
        }

        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(.easeOut(duration: 0.25)) {
            showAchievementsContainer = true
        }

        for index in profileSnapshot.achievements.indices {
            try? await Task.sleep(for: .milliseconds(40))
            _ = withAnimation(.interpolatingSpring(stiffness: 250, damping: 20)) {
                visibleAchievements.insert(index)
            }
        }

        for (index, achievement) in profileSnapshot.achievements.enumerated() where achievement.isEarned {
            try? await Task.sleep(for: .milliseconds(index == 0 ? 180 : 40))
            _ = withAnimation(.spring()) {
                visibleBadges.insert(index)
            }
        }

        try? await Task.sleep(for: .milliseconds(90))
        withAnimation(Self.easeOutExpo(duration: 0.45)) {
            showDeleteButton = true
        }

        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(Self.easeOutExpo(duration: 0.45)) {
            showVersion = true
        }
    }

    private static func easeOutExpo(duration: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}

private struct ProfileSnapshot {
    let displayName: String
    let email: String
    let avatarLetter: String
    let memberSinceText: String
    let stats: [ProfileStat]
    let achievements: [ProfileAchievement]
    let earnedAchievementCount: Int

    init(
        profile: CloudAccountProfile?,
        subjects: [Subject],
        decks: [Deck],
        cards: [Card],
        xpEvents: [XPEventEntity]
    ) {
        let reviewEvents = xpEvents.filter {
            guard let type = XPEventType(rawValue: $0.eventTypeRaw) else { return false }
            return [
                XPEventType.reviewAgain,
                .reviewHard,
                .reviewGood,
                .reviewEasy,
                .skipHard,
                .autoHardTimeout
            ].contains(type)
        }

        let reviewCount = reviewEvents.count
        let activeDayCount = Set(reviewEvents.map { Calendar.current.startOfDay(for: $0.date) }).count
        let longestStreak = Self.longestStreak(from: reviewEvents.map(\.date))

        let successReviews = reviewEvents.filter {
            guard let type = XPEventType(rawValue: $0.eventTypeRaw) else { return false }
            return type == .reviewGood || type == .reviewEasy
        }.count
        let accuracy = reviewCount > 0 ? Int((Double(successReviews) / Double(reviewCount) * 100).rounded()) : 0

        let totalXP = xpEvents.reduce(0) { $0 + $1.xpDelta }
        let distinctSubjects = Set(decks.compactMap { $0.subject?.id }).count
        let dueCount = cards.filter(\.isDue).count
        let hasStrongDeck = Self.hasStrongDeck(decks: decks, events: reviewEvents)

        let earliestDate = Self.earliestMembershipDate(
            profileDate: profile?.updatedAt,
            subjectDates: subjects.map(\.createdAt),
            deckDates: decks.map(\.createdAt),
            cardDates: cards.map(\.createdAt),
            eventDates: xpEvents.map(\.date)
        )

        let rawName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawEmail = profile?.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        displayName = rawName.isEmpty ? "Angel" : rawName
        email = rawEmail.isEmpty ? "sin-email@icloud.com" : rawEmail
        avatarLetter = String(displayName.prefix(1)).uppercased()
        memberSinceText = "MIEMBRO DESDE \(Self.memberSinceLabel(for: earliestDate))"

        stats = [
            ProfileStat(label: "DÍAS ACTIVO", value: "\(activeDayCount)", icon: "calendar", color: Color(red: 0.31, green: 0.53, blue: 0.95)),
            ProfileStat(label: "XP TOTAL", value: totalXP.formatted(), icon: "bolt", color: Color(red: 0.51, green: 0.29, blue: 0.94)),
            ProfileStat(label: "RACHA MÁX", value: "\(longestStreak)", icon: "flame", color: Color(red: 0.95, green: 0.53, blue: 0.20)),
            ProfileStat(label: "PRECISIÓN", value: "\(accuracy)%", icon: "arrow.up.right", color: Color(red: 0.39, green: 0.84, blue: 0.59))
        ]

        achievements = [
            ProfileAchievement(title: "Primera sesión", icon: "star", color: Color(red: 0.88, green: 0.69, blue: 0.19), isEarned: reviewCount > 0),
            ProfileAchievement(title: "Racha de 7", icon: "flame", color: Color(red: 0.90, green: 0.63, blue: 0.11), isEarned: longestStreak >= 7),
            ProfileAchievement(title: "100 tarjetas", icon: "square.stack.3d.down.forward", color: Color(red: 0.84, green: 0.63, blue: 0.16), isEarned: reviewCount >= 100),
            ProfileAchievement(title: "Racha de 30", icon: "crown", color: Color(red: 0.78, green: 0.66, blue: 0.41), isEarned: longestStreak >= 30),
            ProfileAchievement(title: "500 tarjetas", icon: "trophy", color: Color(red: 0.34, green: 0.78, blue: 0.56), isEarned: reviewCount >= 500),
            ProfileAchievement(title: "Explorador", icon: "paperplane", color: Color(red: 0.90, green: 0.68, blue: 0.18), isEarned: distinctSubjects >= 5),
            ProfileAchievement(title: "Guerrero", icon: "shield", color: Color(red: 0.63, green: 0.22, blue: 0.20), isEarned: dueCount >= 50),
            ProfileAchievement(title: "Maestro", icon: "medal", color: Color(red: 0.66, green: 0.49, blue: 0.91), isEarned: hasStrongDeck)
        ]
        earnedAchievementCount = achievements.filter(\.isEarned).count
    }

    private static func earliestMembershipDate(
        profileDate: Date?,
        subjectDates: [Date],
        deckDates: [Date],
        cardDates: [Date],
        eventDates: [Date]
    ) -> Date {
        let dates = ([profileDate].compactMap { $0 } + subjectDates + deckDates + cardDates + eventDates)
        return dates.min() ?? .now
    }

    private static func memberSinceLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }

    private static func longestStreak(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
        guard !uniqueDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for index in 1..<uniqueDays.count {
            let previous = uniqueDays[index - 1]
            let currentDay = uniqueDays[index]
            let diff = calendar.dateComponents([.day], from: previous, to: currentDay).day ?? 0

            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    private static func hasStrongDeck(decks: [Deck], events: [XPEventEntity]) -> Bool {
        var countsByDeck: [UUID: [XPEventType: Int]] = [:]

        for event in events {
            guard
                let deckId = event.deckId,
                let type = XPEventType(rawValue: event.eventTypeRaw)
            else { continue }

            countsByDeck[deckId, default: [:]][type, default: 0] += 1
        }

        let activeDeckIDs = Set(decks.map(\.id))

        return countsByDeck.contains { deckId, counts in
            guard activeDeckIDs.contains(deckId) else { return false }
            return DeckHealthScore(analytics: ReviewAnalytics(counts: counts)).score >= 85
        }
    }
}

private struct ProfileStat {
    let label: String
    let value: String
    let icon: String
    let color: Color
}

private struct ProfileAchievement {
    let title: String
    let icon: String
    let color: Color
    let isEarned: Bool
}

private struct ProfilePressStyle: ButtonStyle {
    let pressedScale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview("Profile Debug Light") {
    NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.light)
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
}

#Preview("Profile Debug Dark") {
    NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(
        for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
        inMemory: true
    )
}
