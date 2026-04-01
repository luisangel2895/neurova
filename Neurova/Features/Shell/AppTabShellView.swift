//
//  AppTabShellView.swift
//  Neurova
//

import SwiftUI

struct AppTabShellView: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: NBottomNavItem = .home
    @State private var isShowingScanPlaceholder = false
    @State private var isShowingSettings = false
    @State private var scanSheetDetent: PresentationDetent = .medium
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
                        scanSheetDetent = .medium
                        isShowingScanPlaceholder = true
                    }
                )
                .padding(.bottom, Layout.navBarBottomPadding)

                if let scanResultMessage {
                    Color.black.opacity(colorScheme == .light ? 0.22 : 0.42)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(10)
                        .onTapGesture {
                            self.scanResultMessage = nil
                        }

                    generationCompleteModal(message: scanResultMessage)
                        .padding(.horizontal, 22)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 22))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(11)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $isShowingScanPlaceholder) {
                NavigationStack {
                    ScanCaptureView { message in
                        scanResultMessage = message
                    } onRequestFullHeight: {
                        scanSheetDetent = .large
                    }
                }
                .presentationDetents([.medium, .large], selection: $scanSheetDetent)
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
                    .id("settings-\(appThemeRawValue)")
            }
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.42), value: scanResultMessage != nil)
        }
    }

    private func generationCompleteModal(message: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.14 : 0.18))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(NColors.Brand.neuroBlue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppCopy.text(locale, en: "Generation Complete", es: "Generación completada"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)

                    Text(AppCopy.text(locale, en: "Your new flashcards are ready!", es: "¡Tus nuevas flashcards están listas!"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
                }
            }

            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            NGradientButton(
                AppCopy.text(locale, en: "Continue", es: "Continuar"),
                showsChevron: true,
                font: .system(size: 18, weight: .semibold, design: .rounded),
                height: 58,
                cornerRadius: 18
            ) {
                selectedTab = .library
                scanResultMessage = nil
            }
        }
        .padding(22)
        .frame(maxWidth: 420, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .light ? Color.black.opacity(0.12) : Color.black.opacity(0.34),
            radius: 26,
            x: 0,
            y: 16
        )
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
                ProfileView()
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
