//
//  NeurovaApp.swift
//  Neurova
//
//  Created by Angel Orellana on 2/03/26.
//

import SwiftData
import SwiftUI

@main
struct NeurovaApp: App {
    @State private var launchMode: AppLaunchMode = AppDevConfig.defaultLaunchMode
    private static let cloudKitSyncFlagKey = "cloudkit_sync_enabled"
    private static let cloudKitRuntimeActiveKey = "cloudkit_sync_runtime_active"
    private static let cloudKitLastErrorKey = "cloudkit_sync_last_error"

    private let modelContainer: ModelContainer = {
        let fullSchema = Schema([
            Subject.self,
            Deck.self,
            Card.self,
            XPEventEntity.self,
            XPStatsEntity.self,
            UserPreferences.self,
            ScanEntity.self,
            MindMapEntity.self,
            StudyGuideEntity.self
        ])

        do {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: cloudKitSyncFlagKey) == nil {
                defaults.set(true, forKey: cloudKitSyncFlagKey)
            }

            let cloudKitEnabled = defaults.bool(forKey: cloudKitSyncFlagKey)
            if cloudKitEnabled {
                do {
                    let cloudSchema = Schema([
                        Subject.self,
                        Deck.self,
                        Card.self,
                        XPEventEntity.self,
                        XPStatsEntity.self,
                        UserPreferences.self
                    ])
                    let localOnlySchema = Schema([
                        ScanEntity.self,
                        MindMapEntity.self,
                        StudyGuideEntity.self
                    ])

                    let cloudConfiguration = ModelConfiguration(
                        "cloud",
                        schema: cloudSchema
                    )
                    let localConfiguration = ModelConfiguration(
                        "local",
                        schema: localOnlySchema,
                        cloudKitDatabase: .none
                    )

                    let container = try ModelContainer(
                        for: fullSchema,
                        configurations: [cloudConfiguration, localConfiguration]
                    )
                    defaults.set(true, forKey: cloudKitRuntimeActiveKey)
                    defaults.removeObject(forKey: cloudKitLastErrorKey)
                    return container
                } catch {
                    // Keep the desired flag intact; fall back to local mode for this run.
                    defaults.set(false, forKey: cloudKitRuntimeActiveKey)
                    let nsError = error as NSError
                    let details = [
                        "CloudKit init failed",
                        "domain=\(nsError.domain)",
                        "code=\(nsError.code)",
                        "description=\(nsError.localizedDescription)",
                        "debug=\(String(describing: error))",
                        "userInfo=\(nsError.userInfo)"
                    ].joined(separator: " | ")
                    defaults.set(details, forKey: cloudKitLastErrorKey)
                }
            } else {
                defaults.set(false, forKey: cloudKitRuntimeActiveKey)
            }

            let localConfiguration = ModelConfiguration(
                schema: fullSchema,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: fullSchema, configurations: [localConfiguration])
        } catch {
            let localConfiguration = ModelConfiguration(
                schema: fullSchema,
                cloudKitDatabase: .none
            )

            if let fallbackContainer = try? ModelContainer(for: fullSchema, configurations: [localConfiguration]) {
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: cloudKitRuntimeActiveKey)
                defaults.set("Fallback local init used", forKey: cloudKitLastErrorKey)
                return fallbackContainer
            }

            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppSceneContainer(launchMode: $launchMode)
                .modelContainer(modelContainer)
        }
    }
}

private enum AppDevConfig {
    // Change this during UI work to jump directly into a screen.
    static let defaultLaunchMode: AppLaunchMode = .home
}

private enum AppLaunchMode {
    case home
    case bootstrap
    case brandPreview
    case designShowcase
}

private struct AppSceneContainer: View {
    @Binding var launchMode: AppLaunchMode
    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    var body: some View {
        AppRootView(launchMode: $launchMode)
            .appTheme(selectedTheme)
            .environment(\.locale, selectedLanguage.locale)
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appThemeRawValue) ?? .system
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
    }
}

private struct AppRootView: View {
    @Binding var launchMode: AppLaunchMode

    var body: some View {
        Group {
            switch launchMode {
            case .home:
                HomeLaunchGateView(
                    onOpenBootstrap: {
                        launchMode = .bootstrap
                    }
                )
            case .bootstrap:
                ContentView {
                    launchMode = .home
                }
            case .brandPreview:
                NavigationStack {
                    BrandPreviewView()
                }
            case .designShowcase:
                NavigationStack {
                    DesignSystemShowcaseView()
                }
            }
        }
    }
}

private struct HomeLaunchGateView: View {
    @Environment(\.modelContext) private var modelContext
    let onOpenBootstrap: () -> Void

    @State private var isLoading = true
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    NColors.Neutrals.background.ignoresSafeArea()
                    ProgressView()
                }
            } else if hasCompletedOnboarding {
                AppTabShellView(onOpenBootstrap: onOpenBootstrap)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .task {
            loadOnboardingState()
        }
    }

    private func loadOnboardingState() {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        let preferences = try? modelContext.fetch(descriptor).first
        hasCompletedOnboarding = preferences?.hasCompletedOnboarding ?? false
        isLoading = false
    }
}

private struct AppTabShellView: View {
    @Environment(\.locale) private var locale
    @State private var selectedTab: NBottomNavItem = .home
    @State private var isShowingScanPlaceholder = false
    @State private var isShowingSettings = false
    @State private var scanResultMessage: String?
    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    let onOpenBootstrap: () -> Void

    private enum Layout {
        static let contentBottomInset: CGFloat = 116
        static let navBarBottomPadding: CGFloat = 0
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                currentScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                NBottomNavBar(
                    selectedTab: $selectedTab,
                    onSelect: { _ in },
                    onScanTap: {
                        isShowingScanPlaceholder = true
                    }
                )
                .padding(.bottom, Layout.navBarBottomPadding)
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $isShowingScanPlaceholder) {
                NavigationStack {
                    ScanCaptureView { message in
                        scanResultMessage = message
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
                    .id("settings-\(appThemeRawValue)")
            }
            .alert(
                AppCopy.text(locale, en: "Generation Complete", es: "Generación completada"),
                isPresented: Binding(
                    get: { scanResultMessage != nil },
                    set: { isPresented in
                        if isPresented == false {
                            scanResultMessage = nil
                        }
                    }
                )
            ) {
                Button(AppCopy.text(locale, en: "OK", es: "OK"), role: .cancel) {}
            } message: {
                Text(scanResultMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            HomeView(
                viewModel: HomeViewModel(language: selectedLanguage),
                onSettingsTap: {
                    isShowingSettings = true
                },
                onOpenBootstrap: onOpenBootstrap,
                onOpenLibrary: {
                    selectedTab = .library
                }
            )
            .id("home-\(selectedLanguage.rawValue)")
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        case .library:
            NavigationStack {
                LibraryView()
            }
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        case .insights:
            NavigationStack {
                InsightsView()
            }
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        case .profile:
            NavigationStack {
                ProfileDebugView()
            }
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        }
    }

    private func placeholderScreen(title: String) -> some View {
        NavigationStack {
            VStack(spacing: NSpacing.sm) {
                Text(title)
                    .font(NTypography.title)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(AppCopy.text(locale, en: "Placeholder screen", es: "Pantalla placeholder"))
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NColors.Neutrals.background.ignoresSafeArea())
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
    }
}
