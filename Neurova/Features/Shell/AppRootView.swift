//
//  AppRootView.swift
//  Neurova
//

import SwiftData
import SwiftUI

struct AppRootView: View {
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

struct HomeLaunchGateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    let onOpenBootstrap: () -> Void

    @State private var isLoading = true
    @State private var hasCompletedOnboarding = false
    @State private var recoveredCloudSession: RecoveredCloudSession?
    @State private var isOnboardingActive = false
    @State private var accountResetToastMessage: String?

    @AppStorage("cloudkit_sync_enabled") private var cloudKitSyncEnabled: Bool = true
    @AppStorage("cloudkit_sync_runtime_active") private var cloudKitSyncRuntimeActive: Bool = true
    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("apple_email") private var appleEmail: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    private enum InitialCloudRecovery {
        static let maxAttempts = 6
        static let pollIntervalNanoseconds: UInt64 = 1_000_000_000
    }

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    NColors.Neutrals.background.ignoresSafeArea()
                    ProgressView()
                }
            } else if hasCompletedOnboarding {
                AppTabShellView(onOpenBootstrap: onOpenBootstrap)
            } else if let recoveredCloudSession, isOnboardingActive == false {
                RecoveredCloudSessionView(
                    locale: locale,
                    recoveredCloudSession: recoveredCloudSession,
                    onContinue: {
                        restoreCloudSessionAndEnterApp(recoveredCloudSession)
                    }
                )
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
                .onAppear {
                    isOnboardingActive = true
                }
                .onDisappear {
                    isOnboardingActive = false
                }
            }
        }
        .task {
            await resolveInitialLaunchState()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await refreshLaunchStateAfterForeground()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountDidReset)) { notification in
            recoveredCloudSession = nil
            hasCompletedOnboarding = false
            isLoading = false
            isOnboardingActive = false

            accountResetToastMessage = notification.object as? String

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.easeOut(duration: 0.28)) {
                    accountResetToastMessage = nil
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let accountResetToastMessage {
                accountResetToast(message: accountResetToastMessage)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @MainActor
    private func resolveInitialLaunchState() async {
        if applyCurrentLaunchState() {
            return
        }

        guard shouldAwaitInitialCloudRecovery else {
            hasCompletedOnboarding = false
            recoveredCloudSession = nil
            isLoading = false
            return
        }

        for _ in 0..<InitialCloudRecovery.maxAttempts {
            try? await Task.sleep(nanoseconds: InitialCloudRecovery.pollIntervalNanoseconds)
            if applyCurrentLaunchState() {
                return
            }
        }

        hasCompletedOnboarding = false
        recoveredCloudSession = nil
        isLoading = false
    }

    @MainActor
    private func refreshLaunchStateAfterForeground() async {
        if applyCurrentLaunchState() {
            return
        }

        await pollForRecoveredCloudSession()

        if recoveredCloudSession == nil, hasCompletedOnboarding == false, isLoading {
            isLoading = false
        }
    }

    @MainActor
    @discardableResult
    private func applyCurrentLaunchState() -> Bool {
        if isOnboardingActive, hasCompletedOnboarding == false {
            recoveredCloudSession = nil
            isLoading = false
            return false
        }

        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        let preferences = try? modelContext.fetch(descriptor).first
        let cloudSession = fetchRecoveredCloudSession()
        let hasPersistedLocalIdentity = profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        if hasPersistedLocalIdentity == false, let cloudSession {
            recoveredCloudSession = cloudSession
            hasCompletedOnboarding = false
            isLoading = false
            return true
        }

        if preferences?.hasCompletedOnboarding == true {
            if let theme = preferences?.preferredThemeRaw, theme.isEmpty == false {
                appThemeRawValue = theme
            }
            if let language = preferences?.preferredLanguageRaw, language.isEmpty == false {
                appLanguageRawValue = language
            }
            hasCompletedOnboarding = true
            recoveredCloudSession = nil
            isLoading = false
            return true
        }

        if let cloudSession {
            recoveredCloudSession = cloudSession
            hasCompletedOnboarding = false
            isLoading = false
            return true
        }

        hasCompletedOnboarding = false
        return false
    }

    private var shouldAwaitInitialCloudRecovery: Bool {
        guard cloudKitSyncEnabled, cloudKitSyncRuntimeActive else { return false }

        let trimmedDisplayName = profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAppleUserID = appleUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDisplayName.isEmpty && trimmedAppleUserID.isEmpty
    }

    private func fetchRecoveredCloudSession() -> RecoveredCloudSession? {
        let descriptor = FetchDescriptor<CloudAccountProfile>(
            predicate: #Predicate<CloudAccountProfile> { profile in
                profile.key == "primary"
            }
        )

        guard
            let profile = try? modelContext.fetch(descriptor).first,
            let displayName = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName.isEmpty == false
        else {
            return nil
        }

        return RecoveredCloudSession(
            appleUserID: profile.appleUserID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            displayName: displayName,
            email: profile.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func restoreCloudSessionAndEnterApp(_ session: RecoveredCloudSession) {
        if session.appleUserID.isEmpty == false {
            appleUserID = session.appleUserID
        }
        appleGivenName = session.displayName
        profileDisplayName = session.displayName
        if let email = session.email, email.isEmpty == false {
            appleEmail = email
        }

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
            preferences.hasCompletedOnboarding = true
            try modelContext.save()
        } catch {
            // If local preferences fail to persist, still allow entering app for this launch.
        }

        recoveredCloudSession = nil
        hasCompletedOnboarding = true

        Task { @MainActor in
            NotificationCenter.default.post(name: .homeShouldForceRefresh, object: nil)
            try? await Task.sleep(for: .milliseconds(650))
            NotificationCenter.default.post(name: .homeShouldForceRefresh, object: nil)
        }
    }

    @MainActor
    private func pollForRecoveredCloudSession() async {
        guard hasCompletedOnboarding == false else { return }
        guard recoveredCloudSession == nil else { return }
        guard isOnboardingActive == false else { return }

        for _ in 0..<20 {
            if hasCompletedOnboarding {
                return
            }
            if isOnboardingActive {
                return
            }
            if let session = fetchRecoveredCloudSession() {
                guard isOnboardingActive == false else { return }
                recoveredCloudSession = session
                return
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
    }

    private func accountResetToast(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NColors.Brand.neuroBlue.opacity(0.16))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.text(locale, en: "Account removed", es: "Cuenta eliminada"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(NColors.Text.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? NColors.Neutrals.surfaceAlt : NColors.Neutrals.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.14), radius: 18, x: 0, y: 10)
    }
}
