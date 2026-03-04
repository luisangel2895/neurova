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
            AppRootView(launchMode: $launchMode)
                .modelContainer(for: [Subject.self, Deck.self, Card.self])
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

private struct AppRootView: View {
    @Binding var launchMode: AppLaunchMode

    var body: some View {
        Group {
            switch launchMode {
            case .home:
                AppTabShellView(
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

private struct AppTabShellView: View {
    @State private var selectedTab: NBottomNavItem = .home
    @State private var isShowingScanPlaceholder = false

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
                    ScanPlaceholderView()
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            HomeView(
                onSettingsTap: {},
                onOpenBootstrap: onOpenBootstrap
            )
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        case .library:
            NavigationStack {
                LibraryView()
            }
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        case .insights:
            placeholderScreen(title: "Insights")
        case .profile:
            placeholderScreen(title: "Profile")
        }
    }

    private func placeholderScreen(title: String) -> some View {
        NavigationStack {
            VStack(spacing: NSpacing.sm) {
                Text(title)
                    .font(NTypography.title)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text("Placeholder screen")
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NColors.Neutrals.background.ignoresSafeArea())
            .safeAreaPadding(.bottom, Layout.contentBottomInset)
        }
    }
}

private struct ScanPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: NSpacing.lg) {
            Image(systemName: "viewfinder.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(NColors.neuroGradient)

            Text("Scan")
                .font(NTypography.title)
                .foregroundStyle(NColors.Text.textPrimary)

            Text("Scan flow placeholder while the feature is being wired.")
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textSecondary)
                .multilineTextAlignment(.center)

            Button("Close") {
                dismiss()
            }
            .font(NTypography.bodyEmphasis)
            .foregroundStyle(NColors.Brand.neuroBlue)
        }
        .padding(NSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NColors.Neutrals.background.ignoresSafeArea())
    }
}
