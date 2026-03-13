//
//  NeurovaApp.swift
//  Neurova
//
//  Created by Angel Orellana on 2/03/26.
//

import SwiftData
import SwiftUI
import Combine

@main
struct NeurovaApp: App {
    @State private var launchMode: AppLaunchMode = AppDevConfig.defaultLaunchMode
    private static let cloudKitSyncFlagKey = "cloudkit_sync_enabled"
    private static let cloudKitRuntimeActiveKey = "cloudkit_sync_runtime_active"
    private static let cloudKitLastErrorKey = "cloudkit_sync_last_error"
    private static let migratedLegacyLocalStoreKey = "migrated_legacy_local_store_v1_to_cloud"

    private let modelContainer: ModelContainer = {
        let fullSchema = Schema([
            Subject.self,
            Deck.self,
            Card.self,
            CloudAccountProfile.self,
            XPEventEntity.self,
            XPStatsEntity.self,
            UserPreferences.self,
            ScanEntity.self
        ])

        do {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: cloudKitSyncFlagKey) == nil {
                defaults.set(true, forKey: cloudKitSyncFlagKey)
            }

            let cloudKitEnabled = defaults.bool(forKey: cloudKitSyncFlagKey)
            if cloudKitEnabled {
                do {
                    let container = try makeCloudBackedContainer(for: fullSchema)
                    migrateLegacyLocalDataIfNeeded(into: container)
                    defaults.set(true, forKey: cloudKitRuntimeActiveKey)
                    defaults.removeObject(forKey: cloudKitLastErrorKey)
                    return container
                } catch {
                    // One-shot recovery: clear likely stale cloud store cache and retry once.
                    let purgeSummary = purgeLikelyCloudStoreFiles()
                    do {
                        let container = try makeCloudBackedContainer(for: fullSchema)
                        migrateLegacyLocalDataIfNeeded(into: container)
                        defaults.set(true, forKey: cloudKitRuntimeActiveKey)
                        defaults.set("Recovered after purge: \(purgeSummary)", forKey: cloudKitLastErrorKey)
                        return container
                    } catch {
                        // Keep the desired flag intact; fall back to local mode for this run.
                        defaults.set(false, forKey: cloudKitRuntimeActiveKey)
                        let nsError = error as NSError
                        let details = [
                            "CloudKit init failed",
                            "purge=\(purgeSummary)",
                            "domain=\(nsError.domain)",
                            "code=\(nsError.code)",
                            "description=\(nsError.localizedDescription)",
                            "debug=\(String(describing: error))",
                            "userInfo=\(nsError.userInfo)"
                        ].joined(separator: " | ")
                        defaults.set(details, forKey: cloudKitLastErrorKey)
                    }
                }
            } else {
                defaults.set(false, forKey: cloudKitRuntimeActiveKey)
            }

            let localConfiguration = ModelConfiguration(
                schema: fullSchema,
                url: storeURL(named: "neurova-local-fallback.store"),
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: fullSchema, configurations: [localConfiguration])
        } catch {
            let localConfiguration = ModelConfiguration(
                schema: fullSchema,
                url: storeURL(named: "neurova-local-fallback.store"),
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

    private static func makeCloudBackedContainer(for fullSchema: Schema) throws -> ModelContainer {
        let cloudStoreURL = storeURL(named: "neurova-cloud-v1.store")
        let localStoreURL = storeURL(named: "neurova-local-v1.store")
        let cloudSchema = Schema([
            Subject.self,
            Deck.self,
            Card.self,
            CloudAccountProfile.self,
            XPEventEntity.self,
            XPStatsEntity.self,
            UserPreferences.self
        ])
        let localOnlySchema = Schema([
            ScanEntity.self
        ])

        let cloudConfiguration = ModelConfiguration(
            "cloud",
            schema: cloudSchema,
            url: cloudStoreURL,
            cloudKitDatabase: .automatic
        )
        let localConfiguration = ModelConfiguration(
            "local",
            schema: localOnlySchema,
            url: localStoreURL,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: fullSchema,
            configurations: [cloudConfiguration, localConfiguration]
        )
    }

    private static func migrateLegacyLocalDataIfNeeded(into container: ModelContainer) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: migratedLegacyLocalStoreKey) == false else { return }

        let legacyURL = storeURL(named: "neurova-local-v1.store")
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            defaults.set(true, forKey: migratedLegacyLocalStoreKey)
            return
        }

        do {
            let legacySchema = Schema([
                XPEventEntity.self,
                XPStatsEntity.self,
                UserPreferences.self
            ])
            let legacyConfiguration = ModelConfiguration(
                "legacy-local-v1",
                schema: legacySchema,
                url: legacyURL,
                cloudKitDatabase: .none
            )
            let legacyContainer = try ModelContainer(for: legacySchema, configurations: [legacyConfiguration])

            let targetContext = ModelContext(container)
            let legacyContext = ModelContext(legacyContainer)

            try mergeLegacyXPEvents(from: legacyContext, into: targetContext)
            try mergeLegacyXPStats(from: legacyContext, into: targetContext)
            try mergeLegacyUserPreferences(from: legacyContext, into: targetContext)

            if targetContext.hasChanges {
                try targetContext.save()
            }
            defaults.set(true, forKey: migratedLegacyLocalStoreKey)
        } catch {
            defaults.set("Legacy local migration failed: \(error.localizedDescription)", forKey: cloudKitLastErrorKey)
        }
    }

    private static func mergeLegacyXPEvents(from legacyContext: ModelContext, into targetContext: ModelContext) throws {
        let existingEvents = try targetContext.fetch(FetchDescriptor<XPEventEntity>())
        let existingIDs = Set(existingEvents.map(\.id))

        let legacyEvents = try legacyContext.fetch(
            FetchDescriptor<XPEventEntity>(sortBy: [SortDescriptor(\.date, order: .forward)])
        )
        for event in legacyEvents where existingIDs.contains(event.id) == false {
            targetContext.insert(
                XPEventEntity(
                    id: event.id,
                    date: event.date,
                    deckId: event.deckId,
                    cardId: event.cardId,
                    eventTypeRaw: event.eventTypeRaw,
                    xpDelta: event.xpDelta
                )
            )
        }
    }

    private static func mergeLegacyXPStats(from legacyContext: ModelContext, into targetContext: ModelContext) throws {
        let legacyStatsDescriptor = FetchDescriptor<XPStatsEntity>(
            predicate: #Predicate<XPStatsEntity> { stats in
                stats.key == "global"
            }
        )
        guard let legacyStats = try legacyContext.fetch(legacyStatsDescriptor).first else { return }

        let targetStatsDescriptor = FetchDescriptor<XPStatsEntity>(
            predicate: #Predicate<XPStatsEntity> { stats in
                stats.key == "global"
            }
        )
        if let targetStats = try targetContext.fetch(targetStatsDescriptor).first {
            targetStats.totalXP = max(targetStats.totalXP, legacyStats.totalXP)
        } else {
            targetContext.insert(XPStatsEntity(key: "global", totalXP: legacyStats.totalXP))
        }
    }

    private static func mergeLegacyUserPreferences(from legacyContext: ModelContext, into targetContext: ModelContext) throws {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )
        guard let legacyPreferences = try legacyContext.fetch(descriptor).first else { return }

        if let targetPreferences = try targetContext.fetch(descriptor).first {
            if targetPreferences.dailyGoalCards == 20 {
                targetPreferences.dailyGoalCards = legacyPreferences.dailyGoalCards
            }
            targetPreferences.hasCompletedOnboarding = targetPreferences.hasCompletedOnboarding || legacyPreferences.hasCompletedOnboarding

            if (targetPreferences.preferredThemeRaw?.isEmpty ?? true),
               let legacyTheme = legacyPreferences.preferredThemeRaw,
               legacyTheme.isEmpty == false {
                targetPreferences.preferredThemeRaw = legacyTheme
            }

            if (targetPreferences.preferredLanguageRaw?.isEmpty ?? true),
               let legacyLanguage = legacyPreferences.preferredLanguageRaw,
               legacyLanguage.isEmpty == false {
                targetPreferences.preferredLanguageRaw = legacyLanguage
            }
        } else {
            targetContext.insert(
                UserPreferences(
                    key: legacyPreferences.key,
                    dailyGoalCards: legacyPreferences.dailyGoalCards,
                    hasCompletedOnboarding: legacyPreferences.hasCompletedOnboarding,
                    preferredThemeRaw: legacyPreferences.preferredThemeRaw,
                    preferredLanguageRaw: legacyPreferences.preferredLanguageRaw
                )
            )
        }
    }

    private static func storeURL(named fileName: String) -> URL {
        let manager = FileManager.default
        let baseURL = (try? manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? manager.temporaryDirectory
        return baseURL.appendingPathComponent(fileName, isDirectory: false)
    }

    private static func purgeLikelyCloudStoreFiles() -> String {
        let manager = FileManager.default
        do {
            let appSupport = try manager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            guard let enumerator = manager.enumerator(
                at: appSupport,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return "no-enumerator"
            }

            var removed: [String] = []
            for case let fileURL as URL in enumerator {
                let name = fileURL.lastPathComponent.lowercased()
                let shouldRemove =
                    name.contains("privatedefault") ||
                    name.contains("privatecloud") ||
                    name.contains("cloud") ||
                    name.contains("swiftdata") ||
                    name.contains("neurova-cloud-v1") ||
                    name.contains("neurova-local-v1") ||
                    name.hasSuffix(".store") ||
                    name.hasSuffix(".sqlite") ||
                    name.hasSuffix(".sqlite-wal") ||
                    name.hasSuffix(".sqlite-shm")
                if shouldRemove {
                    if (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                        try? manager.removeItem(at: fileURL)
                        removed.append(fileURL.lastPathComponent)
                    }
                }
            }

            if removed.isEmpty {
                return "no-files-removed"
            }
            return "removed=\(removed.joined(separator: ","))"
        } catch {
            return "purge-error=\(error.localizedDescription)"
        }
    }

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
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue
    @State private var showSplash = true
    @State private var splashAnimationStarted = false
    @State private var splashLogoVisible = false
    @State private var splashPulse = false
    @State private var splashExit = false

    var body: some View {
        ZStack {
            AppRootView(launchMode: $launchMode)
                .appTheme(selectedTheme)
                .environment(\.locale, selectedLanguage.locale)

            if showSplash {
                AppSplashView(
                    isDark: usesDarkSplashStyle,
                    logoVisible: splashLogoVisible,
                    pulsing: splashPulse,
                    exiting: splashExit
                )
                .transition(.opacity.combined(with: .scale(scale: 1.03)))
                .zIndex(10)
            }
        }
        .task {
            await runSplashIfNeeded()
        }
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appThemeRawValue) ?? .system
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
    }

    private var usesDarkSplashStyle: Bool {
        switch selectedTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return colorScheme == .dark
        }
    }

    @MainActor
    private func runSplashIfNeeded() async {
        guard splashAnimationStarted == false else { return }
        splashAnimationStarted = true

        withAnimation(.spring(response: 0.62, dampingFraction: 0.82)) {
            splashLogoVisible = true
        }
        withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
            splashPulse = true
        }

        try? await Task.sleep(nanoseconds: 1_950_000_000)
        NotificationCenter.default.post(name: .appSplashWillExit, object: nil)
        withAnimation(.easeInOut(duration: 0.45)) {
            splashExit = true
        }

        try? await Task.sleep(nanoseconds: 450_000_000)
        withAnimation(.easeOut(duration: 0.22)) {
            showSplash = false
        }
    }
}

extension Notification.Name {
    static let appSplashWillExit = Notification.Name("appSplashWillExit")
    static let homeShouldForceRefresh = Notification.Name("homeShouldForceRefresh")
    static let accountDidReset = Notification.Name("accountDidReset")
}

private struct AppSplashView: View {
    let isDark: Bool
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    var body: some View {
        Group {
            if isDark {
                darkSplash
            } else {
                LightSplashView(
                    logoVisible: logoVisible,
                    pulsing: pulsing,
                    exiting: exiting
                )
            }
        }
        .ignoresSafeArea()
    }

    private var darkSplash: some View {
        DarkSplashView(
            logoVisible: logoVisible,
            pulsing: pulsing,
            exiting: exiting
        )
    }
}

private struct LightSplashView: View {
    @Environment(\.locale) private var locale
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    @State private var loadingVisible = false
    @State private var progress: CGFloat = 0.0

    private let barWidth: CGFloat = 170
    private let particleVectors: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-1.0, 0.0, 7, 0.00),
        (1.0, 0.0, 6, 0.22),
        (0.0, 1.0, 7, 0.34),
        (0.0, -1.0, 5, 0.12)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: NColors.Splash.lightBackground,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.lightGlow,
                        center: .center,
                        startRadius: 20,
                        endRadius: 230
                    )
                )
                .frame(width: 330, height: 330)

            VStack(spacing: 22) {
                ZStack {
                    ForEach(Array(particleVectors.enumerated()), id: \.offset) { _, vector in
                        LightSplashParticle(
                            dx: vector.0,
                            dy: vector.1,
                            size: vector.2,
                            delay: vector.3,
                            active: logoVisible && exiting == false
                        )
                    }

                    NImages.Brand.logoMark
                        .resizable()
                        .scaledToFit()
                        .frame(width: 124)
                        .shadow(color: NColors.Splash.lightLogoShadow, radius: 16, x: 0, y: 8)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NColors.Splash.lightTrack)
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: NColors.Splash.lightParticleGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: NColors.Splash.lightProgressShadow, radius: 5, x: 0, y: 2)
                    }

                    Text(AppCopy.text(locale, en: "LOADING", es: "CARGANDO"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(NColors.Splash.lightLabel)
                }
                .offset(y: loadingVisible ? 0 : 16)
                .opacity(loadingVisible ? (exiting ? 0.0 : 1.0) : 0.0)
            }
            .offset(y: -8)
        }
        .task {
            guard loadingVisible == false else { return }
            withAnimation(.easeOut(duration: 0.55).delay(0.08)) {
                loadingVisible = true
            }
            withAnimation(.easeOut(duration: 1.42).delay(0.22)) {
                progress = 1.0
            }
        }
    }
}

private struct LightSplashParticle: View {
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let delay: Double
    let active: Bool

    @State private var phase = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: NColors.Splash.lightParticleGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .opacity(active ? (phase ? 0.0 : 0.92) : 0.0)
            .scaleEffect(phase ? 1.25 : 0.45)
            .offset(x: dx * (phase ? 104 : 40), y: dy * (phase ? 104 : 40))
            .task(id: active) {
                guard active else {
                    phase = false
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                while Task.isCancelled == false {
                    phase = false
                    withAnimation(.easeOut(duration: 1.08)) {
                        phase = true
                    }
                    try? await Task.sleep(nanoseconds: 1_120_000_000)
                }
            }
    }
}

private struct DarkSplashView: View {
    @Environment(\.locale) private var locale
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    @State private var loadingVisible = false
    @State private var progress: CGFloat = 0.0

    private let barWidth: CGFloat = 170
    private let particleVectors: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-1.0, 0.0, 7, 0.00),
        (1.0, 0.0, 6, 0.22),
        (0.0, 1.0, 7, 0.34),
        (0.0, -1.0, 5, 0.12)
    ]

    var body: some View {
        ZStack {
            NColors.Splash.darkBase

            LinearGradient(
                colors: NColors.Splash.darkOverlay,
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.darkPrimaryGlow,
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 360, height: 320)
                .blur(radius: 14)
                .offset(y: -10)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.darkSecondaryGlow,
                        center: .center,
                        startRadius: 0,
                        endRadius: 210
                    )
                )
                .frame(width: 320, height: 280)
                .blur(radius: 18)
                .offset(y: 10)

            VStack(spacing: 22) {
                ZStack {
                    ForEach(Array(particleVectors.enumerated()), id: \.offset) { _, vector in
                        DarkSplashParticle(
                            dx: vector.0,
                            dy: vector.1,
                            size: vector.2,
                            delay: vector.3,
                            active: logoVisible && exiting == false
                        )
                    }

                    NImages.Brand.logoOutline
                        .resizable()
                        .scaledToFit()
                        .frame(width: 124)
                        .shadow(color: NColors.Splash.darkLogoShadow, radius: 12, x: 0, y: 6)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NColors.Splash.darkTrack)
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: NColors.Splash.darkParticleGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: NColors.Splash.darkProgressShadow, radius: 7, x: 0, y: 2)
                    }

                    Text(AppCopy.text(locale, en: "LOADING", es: "CARGANDO"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(NColors.Splash.darkLabel)
                }
                .offset(y: loadingVisible ? 0 : 16)
                .opacity(loadingVisible ? (exiting ? 0.0 : 1.0) : 0.0)
            }
            .offset(y: -8)
        }
        .task {
            guard loadingVisible == false else { return }
            withAnimation(.easeOut(duration: 0.55).delay(0.08)) {
                loadingVisible = true
            }
            withAnimation(.easeOut(duration: 1.42).delay(0.22)) {
                progress = 1.0
            }
        }
    }
}

private struct DarkSplashParticle: View {
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let delay: Double
    let active: Bool

    @State private var phase = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: NColors.Splash.darkParticleGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .opacity(active ? (phase ? 0.0 : 0.90) : 0.0)
            .scaleEffect(phase ? 1.25 : 0.45)
            .offset(x: dx * (phase ? 104 : 40), y: dy * (phase ? 104 : 40))
            .task(id: active) {
                guard active else {
                    phase = false
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                while Task.isCancelled == false {
                    phase = false
                    withAnimation(.easeOut(duration: 1.08)) {
                        phase = true
                    }
                    try? await Task.sleep(nanoseconds: 1_120_000_000)
                }
            }
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

        // If iCloud profile exists but local identity has not been explicitly restored yet,
        // keep showing the recovered-session gate until user taps "Go to app".
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

private struct RecoveredCloudSession {
    let appleUserID: String
    let displayName: String
    let email: String?
}

private struct RecoveredCloudSessionView: View {
    @Environment(\.colorScheme) private var colorScheme
    let locale: Locale
    let recoveredCloudSession: RecoveredCloudSession
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDark ? NColors.Recovery.backgroundDark : NColors.Recovery.backgroundLight,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 54)

                (isDark ? NImages.Brand.logoOutline : NImages.Brand.logoMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66, height: 66)
                    .shadow(color: logoShadowColor, radius: 18, x: 0, y: 8)
                    .modifier(FloatingLogoEffect(period: 2.1, amplitude: 2))
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: "icloud")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NColors.Recovery.iconTint)
                            .frame(width: 30, height: 30)
                            .background(NColors.Recovery.iconBackground)
                            .clipShape(Circle())

                        Text(AppCopy.text(locale, en: "ICLOUD SYNCED", es: "ICLOUD SINCRONIZADO"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(NColors.Recovery.eyebrow)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(AppCopy.text(locale, en: "Account found", es: "Cuenta encontrada"))
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                            .foregroundStyle(NColors.Recovery.title)

                        Text(
                            AppCopy.text(
                                locale,
                                en: "We found your Neurova profile in iCloud. You can continue without signing in again.",
                                es: "Encontramos tu perfil de Neurova en iCloud. Puedes continuar sin iniciar sesión otra vez."
                            )
                        )
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(NColors.Recovery.body)
                    }

                    profilePill
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    NColors.Recovery.cardBackgroundTop,
                                    NColors.Recovery.cardBackgroundBottom
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(NColors.Recovery.cardBorder, lineWidth: 1)
                )

                NGradientButton(
                    AppCopy.text(locale, en: "Go to app", es: "Ir a la app"),
                    showsChevron: true,
                    animateEffects: true,
                    foregroundColor: NColors.Recovery.buttonText,
                    gradientColors: NColors.Recovery.buttonGradient(for: colorScheme)
                ) {
                    onContinue()
                }
                .shadow(color: NColors.Recovery.buttonShadow, radius: 14, x: 0, y: 8)
                .modifier(PressScaleEffect())

                Text(AppCopy.text(locale, en: "Your data is protected with end-to-end encryption", es: "Tus datos están protegidos con cifrado de extremo a extremo"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(NColors.Recovery.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
        }
    }

    private var profilePill: some View {
        HStack(spacing: 12) {
            AnimatedGradientAvatar(initial: avatarInitial)

            VStack(alignment: .leading, spacing: 2) {
                Text(recoveredCloudSession.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(NColors.Recovery.name)

                if let email = recoveredCloudSession.email, email.isEmpty == false {
                    Text(email)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(NColors.Recovery.email)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(NColors.Recovery.pillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(NColors.Recovery.pillBorder, lineWidth: 1)
        )
    }

    private var isDark: Bool { colorScheme == .dark }
    private var logoShadowColor: Color {
        NColors.Recovery.logoShadow
    }

    private var avatarInitial: String {
        let trimmed = recoveredCloudSession.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "N" }
        return String(first).uppercased()
    }
}

private struct AnimatedGradientAvatar: View {
    let initial: String
    @State private var tickTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(initial)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(NColors.Recovery.avatarText)
            .frame(width: 46, height: 46)
            .background(
                LinearGradient(
                    colors: NColors.Recovery.avatarGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let phase = (tickTime / 2.15).truncatingRemainder(dividingBy: 1.0)
                    let shinePhase = -1.4 + (2.8 * phase)
                    let xOffset = width * shinePhase

                    Circle()
                        .fill(.clear)
                        .overlay(
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            Color.white.opacity(0.10),
                                            Color.white.opacity(0.24),
                                            Color.white.opacity(0.10),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .rotationEffect(.degrees(20))
                                .blur(radius: 2.4)
                                .offset(x: xOffset)
                        )
                        .blendMode(.screen)
                }
                .clipShape(Circle())
            }
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
            }
            .overlay(alignment: .top) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 42, height: 18)
                    .blur(radius: 0.5)
                    .offset(y: -2)
                    .allowsHitTesting(false)
            }
            .clipShape(Circle())
            .onReceive(tick) { date in
                tickTime = date.timeIntervalSinceReferenceDate
            }
    }
}

private struct FloatingLogoEffect: ViewModifier {
    let period: Double
    let amplitude: CGFloat
    @State private var tickTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        let phase = (tickTime / period) * 2.0 * Double.pi
        let y = CGFloat(sin(phase)) * amplitude

        content
            .offset(y: y)
            .onReceive(tick) { date in
                tickTime = date.timeIntervalSinceReferenceDate
            }
    }
}

private struct PressScaleEffect: ViewModifier {
    @GestureState private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.98 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($pressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

private struct AppTabShellView: View {
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
