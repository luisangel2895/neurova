import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue
    @AppStorage("daily_goal_cards") private var dailyGoalCardsStorage: Int = 20
    @AppStorage("settings_sounds_enabled") private var soundsEnabled: Bool = true
    @AppStorage("settings_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings_notifications_enabled") private var notificationsEnabled: Bool = true

    @State private var selectedDailyGoalCards: Int = 20
    @State private var hasAnimatedIn = false
    @State private var showHeader = false
    @State private var showGoalSection = false
    @State private var showThemeSection = false
    @State private var showLanguageSection = false
    @State private var showPreferencesSection = false
    @State private var showPrivacySection = false
    @State private var showFooter = false

    private let dailyGoalOptions = [10, 20, 30, 50, 70, 100]
    private let languageRows: [SettingsLanguageOption] = [
        .init(id: "es", labelES: "Español", labelEN: "Spanish", flag: "🇪🇸"),
        .init(id: "en", labelES: "English", labelEN: "English", flag: "🇺🇸"),
        .init(id: "pt", labelES: "Português", labelEN: "Portuguese", flag: "🇧🇷")
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    dailyGoalSection
                    themeSection
                    languageSection
                    preferencesSection
                    privacySection
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(closeButtonFill)
                            Circle()
                                .stroke(closeButtonStroke, lineWidth: colorScheme == .dark ? 0 : 1)

                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(closeButtonForeground)
                        }
                        .frame(width: 40, height: 40)
                    }
                    .buttonStyle(PressScaleStyle(pressedScale: 0.92))
                }
            }
        }
        .onAppear {
            loadPreferencesFromCloud()
        }
        .onChange(of: appThemeRawValue) { _, _ in
            syncPreferencesToCloud()
        }
        .onChange(of: appLanguageRawValue) { _, _ in
            syncPreferencesToCloud()
        }
        .onChange(of: selectedDailyGoalCards) { _, _ in
            syncPreferencesToCloud()
        }
        .task {
            await runEntryAnimationsIfNeeded()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(subtitleText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(subtitleColor)
            }

            Spacer(minLength: 0)
        }
        .opacity(showHeader ? 1 : 0)
        .offset(x: showHeader ? 0 : -10, y: showHeader ? 0 : 8)
        .animation(Self.easeOutExpo(duration: 0.55), value: showHeader)
    }

    private var dailyGoalSection: some View {
        settingsBlock(
            title: dailyGoalTitle,
            icon: "scope",
            iconColor: Color(red: 0.35, green: 0.59, blue: 0.97),
            isVisible: showGoalSection
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(dailyGoalSubtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)

                HStack(spacing: 10) {
                    ForEach(dailyGoalOptions, id: \.self) { goal in
                        Button {
                            selectedDailyGoalCards = goal
                        } label: {
                            Text("\(goal)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(goalChipTextColor(goal))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(goalChipBackground(goal))
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: goal == selectedDailyGoalCards ? 8 : 14,
                                        style: .continuous
                                    )
                                        .stroke(goalChipStroke(goal), lineWidth: goal == selectedDailyGoalCards ? 1.1 : 1)
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: goal == selectedDailyGoalCards ? 8 : 14,
                                        style: .continuous
                                    )
                                )
                                .shadow(
                                    color: goal == selectedDailyGoalCards ? selectedGlowColor : .clear,
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                        }
                        .buttonStyle(PressScaleStyle(pressedScale: 0.95))
                    }
                }
            }
        }
    }

    private var themeSection: some View {
        settingsBlock(
            title: appearanceTitle,
            icon: "paintpalette",
            iconColor: Color(red: 0.56, green: 0.35, blue: 0.96),
            isVisible: showThemeSection
        ) {
            VStack(spacing: 10) {
                themeRow(.system, icon: "desktopcomputer")
                themeRow(.light, icon: "sun.max")
                themeRow(.dark, icon: "moon.stars")
            }
        }
    }

    private var languageSection: some View {
        settingsBlock(
            title: languageTitle,
            icon: "globe",
            iconColor: Color(red: 0.33, green: 0.79, blue: 0.57),
            isVisible: showLanguageSection
        ) {
            VStack(spacing: 10) {
                ForEach(languageRows) { option in
                    languageRow(option)
                }
            }
        }
    }

    private var preferencesSection: some View {
        settingsBlock(
            title: preferencesTitle,
            icon: "sparkles",
            iconColor: Color(red: 0.92, green: 0.73, blue: 0.20),
            isVisible: showPreferencesSection
        ) {
            VStack(spacing: 6) {
                preferenceToggleRow(
                    title: soundsTitle,
                    icon: "speaker.wave.2",
                    iconColor: Color(red: 0.30, green: 0.53, blue: 0.96),
                    isOn: $soundsEnabled
                )
                preferenceToggleRow(
                    title: hapticsTitle,
                    icon: "iphone.radiowaves.left.and.right",
                    iconColor: Color(red: 0.57, green: 0.36, blue: 0.95),
                    isOn: $hapticsEnabled
                )
                preferenceToggleRow(
                    title: notificationsTitle,
                    icon: "bell",
                    iconColor: Color(red: 0.95, green: 0.58, blue: 0.23),
                    isOn: $notificationsEnabled
                )
            }
        }
    }

    private var privacySection: some View {
        NavigationLink {
            PrivacyView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(iconContainerFill)
                    Image(systemName: "shield")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.46, green: 0.49, blue: 0.59))
                }
                .frame(width: 42, height: 42)

                Text(privacyTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(privacyTitleColor)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(privacyChevronColor)
            }
            .padding(.horizontal, 20)
            .frame(height: 88)
            .frame(maxWidth: .infinity)
            .background(sectionCardFill)
            .overlay(sectionCardStrokeShape)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: sectionShadow, radius: colorScheme == .dark ? 14 : 8, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .buttonStyle(PressScaleStyle(pressedScale: 0.985))
        .opacity(showPrivacySection ? 1 : 0)
        .offset(y: showPrivacySection ? 0 : 18)
        .animation(Self.easeOutExpo(duration: 0.55), value: showPrivacySection)
    }

    private var footer: some View {
        Text("Neurova v1.0.0")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(footerColor)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .opacity(showFooter ? 0.4 : 0)
            .animation(Self.easeOutExpo(duration: 0.45), value: showFooter)
    }

    private func settingsBlock<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        isVisible: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
            }

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionCardFill)
            .overlay(sectionCardStrokeShape)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: sectionShadow, radius: colorScheme == .dark ? 14 : 8, x: 0, y: 6)
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.98)
        .offset(y: isVisible ? 0 : 18)
        .animation(Self.easeOutExpo(duration: 0.55), value: isVisible)
    }

    private func themeRow(_ theme: AppTheme, icon: String) -> some View {
        let isSelected = selectedTheme == theme

        return Button {
            selectedTheme = theme
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isSelected ? selectedLeadingIconStyle : iconContainerStyle)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : secondaryTextColor)
                }
                .frame(width: 42, height: 42)

                Text(theme.title(for: selectedLanguage))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? titleColor : secondaryTextColor.opacity(0.85))

                Spacer(minLength: 0)

                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, 12)
            .frame(height: 66)
            .frame(maxWidth: .infinity)
            .background(isSelected ? selectedRowFill : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScaleStyle(pressedScale: 0.985))
    }

    private func languageRow(_ option: SettingsLanguageOption) -> some View {
        let isSelected = option.id == selectedLanguage.rawValue
        let isEnabled = option.id != "pt"

        return Button {
            guard isEnabled, let language = AppLanguage(rawValue: option.id) else { return }
            selectedLanguage = language
        } label: {
            HStack(spacing: 14) {
                Text(option.flag)
                    .font(.system(size: 19))
                    .frame(width: 42, height: 42)

                Text(option.title(for: selectedLanguage))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? titleColor : secondaryTextColor.opacity(isEnabled ? 0.88 : 0.72))

                Spacer(minLength: 0)

                selectionIndicator(isSelected: isSelected)
                    .opacity(isEnabled ? 1 : 0.65)
            }
            .padding(.horizontal, 12)
            .frame(height: 66)
            .frame(maxWidth: .infinity)
            .background(isSelected ? selectedRowFill : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(isEnabled ? 1 : 0.72)
        }
        .buttonStyle(PressScaleStyle(pressedScale: 0.985))
        .disabled(!isEnabled)
    }

    private func preferenceToggleRow(
        title: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(titleColor)

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: toggleTint))
        }
        .padding(.horizontal, 12)
        .frame(height: 66)
        .frame(maxWidth: .infinity)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.clear : secondaryTextColor.opacity(0.35), lineWidth: 2)
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(selectionIndicatorFill)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRawValue) ?? .system }
        nonmutating set { appThemeRawValue = newValue.rawValue }
    }

    private var selectedLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRawValue) ?? .spanish }
        nonmutating set { appLanguageRawValue = newValue.rawValue }
    }

    private func syncPreferencesToCloud() {
        do {
            let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate<UserPreferences> { preferences in
                    preferences.key == "global"
                }
            )
            let preferences = try modelContext.fetch(descriptor).first ?? UserPreferences()
            if preferences.modelContext == nil {
                modelContext.insert(preferences)
            }
            preferences.dailyGoalCards = selectedDailyGoalCards
            dailyGoalCardsStorage = selectedDailyGoalCards
            preferences.preferredThemeRaw = appThemeRawValue
            preferences.preferredLanguageRaw = appLanguageRawValue
            try modelContext.save()
        } catch {
            // Best-effort sync to iCloud-backed preferences.
        }
    }

    private func loadPreferencesFromCloud() {
        do {
            let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate<UserPreferences> { preferences in
                    preferences.key == "global"
                }
            )

            if let preferences = try modelContext.fetch(descriptor).first {
                selectedDailyGoalCards = preferences.dailyGoalCards
                dailyGoalCardsStorage = preferences.dailyGoalCards
            } else {
                selectedDailyGoalCards = dailyGoalCardsStorage
                syncPreferencesToCloud()
            }
        } catch {
            // Keep defaults if loading fails.
        }
    }

    private func runEntryAnimationsIfNeeded() async {
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true

        // Let the sheet/push transition settle so the first visible frame still contains the entrance motion.
        try? await Task.sleep(for: .milliseconds(180))

        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showHeader = true
        }

        try? await Task.sleep(for: .milliseconds(70))
        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showGoalSection = true
        }

        try? await Task.sleep(for: .milliseconds(60))
        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showThemeSection = true
        }

        try? await Task.sleep(for: .milliseconds(60))
        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showLanguageSection = true
        }

        try? await Task.sleep(for: .milliseconds(60))
        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showPreferencesSection = true
        }

        try? await Task.sleep(for: .milliseconds(60))
        withAnimation(Self.easeOutExpo(duration: 0.55)) {
            showPrivacySection = true
        }

        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(Self.easeOutExpo(duration: 0.45)) {
            showFooter = true
        }
    }

    private var titleText: String {
        selectedLanguage == .english ? "Settings" : "Ajustes"
    }

    private var subtitleText: String {
        switch selectedLanguage {
        case .english:
            return "Customize your experience."
        case .spanish:
            return "Personaliza tu experiencia."
        }
    }

    private var dailyGoalTitle: String {
        selectedLanguage == .english ? "Daily Goal" : "Meta diaria"
    }

    private var dailyGoalSubtitle: String {
        selectedLanguage == .english
            ? "Cards to complete each day."
            : "Tarjetas por completar cada día."
    }

    private var appearanceTitle: String {
        selectedLanguage == .english ? "Appearance" : "Apariencia"
    }

    private var languageTitle: String {
        selectedLanguage == .english ? "Language" : "Idioma"
    }

    private var preferencesTitle: String {
        selectedLanguage == .english ? "Preferences" : "Preferencias"
    }

    private var soundsTitle: String {
        selectedLanguage == .english ? "Sounds" : "Sonidos"
    }

    private var hapticsTitle: String {
        selectedLanguage == .english ? "Haptics" : "Hápticos"
    }

    private var notificationsTitle: String {
        selectedLanguage == .english ? "Notifications" : "Notificaciones"
    }

    private var privacyTitle: String {
        selectedLanguage == .english ? "Privacy" : "Privacidad"
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.03, green: 0.04, blue: 0.09),
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color(red: 0.03, green: 0.05, blue: 0.11)
                ]
                : [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.94, green: 0.94, blue: 0.96),
                    Color(red: 0.93, green: 0.93, blue: 0.95)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.97) : Color(red: 0.07, green: 0.08, blue: 0.14)
    }

    private var subtitleColor: Color {
        colorScheme == .dark ? Color(red: 0.43, green: 0.47, blue: 0.58) : Color(red: 0.46, green: 0.49, blue: 0.57)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.43, green: 0.47, blue: 0.58) : Color(red: 0.48, green: 0.50, blue: 0.58)
    }

    private var footerColor: Color {
        colorScheme == .dark ? Color(red: 0.36, green: 0.39, blue: 0.49) : Color(red: 0.52, green: 0.54, blue: 0.60)
    }

    private var sectionCardFill: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.10, blue: 0.17),
                    Color(red: 0.09, green: 0.11, blue: 0.18)
                ]
                : [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.93, green: 0.93, blue: 0.96)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var sectionCardStrokeShape: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(sectionCardStroke, lineWidth: 1.1)
    }

    private var sectionCardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.83, green: 0.84, blue: 0.88)
    }

    private var sectionShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.18)
            : Color.black.opacity(0.05)
    }

    private var selectedRowFill: Color {
        colorScheme == .dark
            ? Color(red: 0.14, green: 0.21, blue: 0.34)
            : Color(red: 0.87, green: 0.90, blue: 0.98)
    }

    private var selectedLeadingIconStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.28, green: 0.53, blue: 0.98), Color(red: 0.49, green: 0.34, blue: 0.95)]
                    : [Color(red: 0.32, green: 0.56, blue: 0.98), Color(red: 0.50, green: 0.36, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var iconContainerStyle: AnyShapeStyle {
        AnyShapeStyle(iconContainerFill)
    }

    private var iconContainerFill: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.14, blue: 0.22)
            : Color(red: 0.90, green: 0.91, blue: 0.95)
    }

    private var toggleTint: Color {
        Color(red: 0.33, green: 0.54, blue: 0.98)
    }

    private var closeButtonFill: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.11, blue: 0.17)
            : .white
    }

    private var closeButtonStroke: Color {
        colorScheme == .dark
            ? .clear
            : Color.black.opacity(0.05)
    }

    private var closeButtonForeground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.9)
            : Color(red: 0.24, green: 0.26, blue: 0.34)
    }

    private var privacyTitleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.42) : Color.black.opacity(0.55)
    }

    private var privacyChevronColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.24)
    }

    private var selectedGlowColor: Color {
        colorScheme == .dark
            ? Color(red: 0.36, green: 0.54, blue: 0.99).opacity(0.36)
            : Color(red: 0.36, green: 0.54, blue: 0.99).opacity(0.18)
    }

    private var selectionIndicatorFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.33, green: 0.54, blue: 0.98), Color(red: 0.55, green: 0.39, blue: 0.96)]
                    : [Color(red: 0.35, green: 0.57, blue: 0.99), Color(red: 0.57, green: 0.42, blue: 0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func goalChipBackground(_ goal: Int) -> some ShapeStyle {
        if goal == selectedDailyGoalCards {
            return AnyShapeStyle(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.38, green: 0.53, blue: 0.99), Color(red: 0.54, green: 0.40, blue: 0.96)]
                        : [Color(red: 0.39, green: 0.56, blue: 0.99), Color(red: 0.56, green: 0.42, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(
            colorScheme == .dark
                ? Color(red: 0.12, green: 0.13, blue: 0.20)
                : Color(red: 0.90, green: 0.91, blue: 0.95)
        )
    }

    private func goalChipStroke(_ goal: Int) -> Color {
        if goal == selectedDailyGoalCards {
            return Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color(red: 0.84, green: 0.85, blue: 0.90)
    }

    private func goalChipTextColor(_ goal: Int) -> Color {
        goal == selectedDailyGoalCards
            ? .white
            : (colorScheme == .dark ? Color(red: 0.52, green: 0.55, blue: 0.66) : Color(red: 0.36, green: 0.39, blue: 0.47))
    }

    private static func easeOutExpo(duration: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}

private struct SettingsLanguageOption: Identifiable {
    let id: String
    let labelES: String
    let labelEN: String
    let flag: String

    func title(for language: AppLanguage) -> String {
        language == .english ? labelEN : labelES
    }
}

private struct PressScaleStyle: ButtonStyle {
    let pressedScale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview("Settings Light") {
    SettingsView()
        .preferredColorScheme(.light)
        .modelContainer(
            for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
            inMemory: true
        )
}

#Preview("Settings Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
        .modelContainer(
            for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self],
            inMemory: true
        )
}
