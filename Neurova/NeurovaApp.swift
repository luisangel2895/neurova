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

    var body: some Scene {
        WindowGroup {
            AppSceneContainer(launchMode: $launchMode)
                .modelContainer(
                    for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self, ScanEntity.self]
                )
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
                    ScanCaptureView()
                }
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
                    .id("settings-\(appThemeRawValue)")
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
            placeholderScreen(title: AppCopy.text(locale, en: "Profile", es: "Perfil"))
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
