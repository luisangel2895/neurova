import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue
    @AppStorage("daily_goal_cards") private var dailyGoalCardsStorage: Int = 20
    @State private var selectedDailyGoalCards: Int = 20

    private let dailyGoalOptions = [20, 30, 50, 70, 100]

    var body: some View {
        settingsContent
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
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(subtitleText)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textSecondary)
        }
    }

    private var themeSection: some View {
        settingsSection(
            title: appearanceTitle,
            subtitle: appearanceSubtitle
        ) {
            ForEach(AppTheme.allCases) { theme in
                optionRow(
                    title: theme.title(for: selectedLanguage),
                    isSelected: selectedTheme == theme
                ) {
                    selectedTheme = theme
                }
            }
        }
    }

    private var languageSection: some View {
        settingsSection(
            title: languageTitle,
            subtitle: languageSubtitle
        ) {
            ForEach(AppLanguage.allCases) { language in
                optionRow(
                    title: language.title(for: selectedLanguage),
                    isSelected: selectedLanguage == language
                ) {
                    selectedLanguage = language
                }
            }
        }
    }

    private var dailyGoalSection: some View {
        settingsSection(
            title: dailyGoalTitle,
            subtitle: dailyGoalSubtitle
        ) {
            HStack(spacing: NSpacing.sm) {
                ForEach(dailyGoalOptions, id: \.self) { goal in
                    Button {
                        selectedDailyGoalCards = goal
                    } label: {
                        Text("\(goal)")
                            .font(NTypography.bodyEmphasis.weight(.semibold))
                            .foregroundStyle(
                                selectedDailyGoalCards == goal
                                ? NColors.Brand.neuroBlue
                                : NColors.Text.textPrimary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                    .fill(selectedDailyGoalCards == goal ? NColors.Home.surfaceL1 : NColors.Neutrals.surfaceAlt)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                    .stroke(
                                        selectedDailyGoalCards == goal ? NColors.Brand.neuroBlue : NColors.Neutrals.border,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            Text(title)
                .font(NTypography.caption.weight(.semibold))
                .foregroundStyle(NColors.Text.textSecondary)

            NCard {
                VStack(alignment: .leading, spacing: NSpacing.sm) {
                    Text(subtitle)
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)

                    content()
                }
            }
        }
    }

    private func optionRow(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: NSpacing.sm) {
            Text(title)
                .font(NTypography.bodyEmphasis.weight(.semibold))
                .foregroundStyle(NColors.Text.textPrimary)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(NTypography.bodyEmphasis)
                .foregroundStyle(isSelected ? NColors.Brand.neuroBlue : secondaryTextColor)
        }
        .padding(.horizontal, NSpacing.sm)
        .padding(.vertical, NSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(isSelected ? NColors.Brand.neuroBlue.opacity(0.10) : NColors.Home.surfaceL2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isSelected ? NColors.Brand.neuroBlue.opacity(0.35) : NColors.Home.layeredStroke, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRawValue) ?? .system }
        nonmutating set { appThemeRawValue = newValue.rawValue }
    }

    private var selectedLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRawValue) ?? .spanish }
        nonmutating set { appLanguageRawValue = newValue.rawValue }
    }

    private var settingsContent: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: NSpacing.lg) {
                    headerSection
                    dailyGoalSection
                    themeSection
                    languageSection
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.vertical, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(closeText) {
                        dismiss()
                    }
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Brand.neuroBlue)
                }
            }
        }
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

    private var titleText: String {
        selectedLanguage == .english ? "Settings" : "Ajustes"
    }

    private var subtitleText: String {
        selectedLanguage == .english
            ? "Customize appearance and language."
            : "Personaliza apariencia e idioma."
    }

    private var appearanceTitle: String {
        selectedLanguage == .english ? "Appearance" : "Apariencia"
    }

    private var appearanceSubtitle: String {
        selectedLanguage == .english
            ? "Choose how the app looks."
            : "Elige como se ve la app."
    }

    private var languageTitle: String {
        selectedLanguage == .english ? "Language" : "Idioma"
    }

    private var languageSubtitle: String {
        selectedLanguage == .english
            ? "Choose the app language."
            : "Elige el idioma de la app."
    }

    private var dailyGoalTitle: String {
        selectedLanguage == .english ? "Daily goal" : "Meta diaria"
    }

    private var dailyGoalSubtitle: String {
        selectedLanguage == .english
            ? "Cards to complete each day."
            : "Tarjetas por completar cada día."
    }

    private var closeText: String {
        selectedLanguage == .english ? "Close" : "Cerrar"
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
