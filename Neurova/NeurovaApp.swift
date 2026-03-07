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
        withAnimation(.easeInOut(duration: 0.45)) {
            splashExit = true
        }

        try? await Task.sleep(nanoseconds: 450_000_000)
        withAnimation(.easeOut(duration: 0.22)) {
            showSplash = false
        }
    }
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
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 1.00),
                    Color(red: 0.95, green: 0.96, blue: 0.99),
                    Color(red: 0.97, green: 0.98, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color(red: 0.90, green: 0.94, blue: 1.0).opacity(0.36),
                            .clear
                        ],
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
                        .shadow(color: Color(red: 0.17, green: 0.33, blue: 0.72).opacity(0.22), radius: 16, x: 0, y: 8)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.85, green: 0.87, blue: 0.91).opacity(0.78))
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.29, green: 0.86, blue: 0.75), Color(red: 0.22, green: 0.50, blue: 0.92)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: Color(red: 0.22, green: 0.50, blue: 0.92).opacity(0.24), radius: 5, x: 0, y: 2)
                    }

                    Text("LOADING")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(Color(red: 0.35, green: 0.39, blue: 0.48).opacity(0.88))
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
                    colors: [Color(red: 0.29, green: 0.86, blue: 0.75), Color(red: 0.22, green: 0.50, blue: 0.92)],
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
            Color(red: 0.03, green: 0.05, blue: 0.12)

            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.13, blue: 0.28).opacity(0.40),
                    Color(red: 0.04, green: 0.06, blue: 0.14).opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.20, green: 0.39, blue: 0.96).opacity(0.30),
                            Color(red: 0.15, green: 0.30, blue: 0.74).opacity(0.16),
                            Color(red: 0.09, green: 0.18, blue: 0.44).opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 520
                    )
                )
                .frame(width: 780, height: 620)
                .blur(radius: 26)
                .offset(y: -12)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.44, blue: 0.98).opacity(0.14),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 460
                    )
                )
                .frame(width: 650, height: 520)
                .blur(radius: 38)
                .offset(y: 18)

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
                        .shadow(color: Color(red: 0.22, green: 0.40, blue: 0.95).opacity(0.32), radius: 20, x: 0, y: 8)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.19, green: 0.86, blue: 0.96), Color(red: 0.45, green: 0.30, blue: 0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: Color(red: 0.29, green: 0.53, blue: 0.98).opacity(0.34), radius: 7, x: 0, y: 2)
                    }

                    Text("LOADING")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(Color.white.opacity(0.62))
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
                    colors: [Color(red: 0.19, green: 0.86, blue: 0.96), Color(red: 0.45, green: 0.30, blue: 0.95)],
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
    let onOpenBootstrap: () -> Void

    @State private var isLoading = true
    @State private var hasCompletedOnboarding = false
    @State private var recoveredCloudSession: RecoveredCloudSession?

    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("apple_email") private var appleEmail: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    NColors.Neutrals.background.ignoresSafeArea()
                    ProgressView()
                }
            } else if hasCompletedOnboarding {
                AppTabShellView(onOpenBootstrap: onOpenBootstrap)
            } else if let recoveredCloudSession {
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
            }
        }
        .task {
            loadOnboardingState()
            await pollForRecoveredCloudSession()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await pollForRecoveredCloudSession()
            }
        }
    }

    private func loadOnboardingState() {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        let preferences = try? modelContext.fetch(descriptor).first
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
            return
        }

        if let cloudSession = fetchRecoveredCloudSession() {
            recoveredCloudSession = cloudSession
            hasCompletedOnboarding = false
            isLoading = false
            return
        }

        hasCompletedOnboarding = false
        isLoading = false
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
    }

    @MainActor
    private func pollForRecoveredCloudSession() async {
        guard hasCompletedOnboarding == false else { return }
        guard recoveredCloudSession == nil else { return }

        for _ in 0..<20 {
            if hasCompletedOnboarding {
                return
            }
            if let session = fetchRecoveredCloudSession() {
                recoveredCloudSession = session
                return
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
    }
}

private struct RecoveredCloudSession {
    let appleUserID: String
    let displayName: String
    let email: String?
}

private struct RecoveredCloudSessionView: View {
    let locale: Locale
    let recoveredCloudSession: RecoveredCloudSession
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            NColors.Neutrals.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: NSpacing.md) {
                NCard {
                    VStack(alignment: .leading, spacing: NSpacing.sm) {
                        Text(AppCopy.text(locale, en: "iCloud account found", es: "Cuenta de iCloud encontrada"))
                            .font(NTypography.title.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text(
                            AppCopy.text(
                                locale,
                                en: "We found your Neurova profile in iCloud. You can continue without signing in again.",
                                es: "Encontramos tu perfil de Neurova en iCloud. Puedes continuar sin iniciar sesión otra vez."
                            )
                        )
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textSecondary)

                        Text(recoveredCloudSession.displayName)
                            .font(NTypography.bodyEmphasis.weight(.semibold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        if let email = recoveredCloudSession.email, email.isEmpty == false {
                            Text(email)
                                .font(NTypography.caption)
                                .foregroundStyle(NColors.Text.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                NPrimaryButton(AppCopy.text(locale, en: "Continue to app", es: "Ir a la app")) {
                    onContinue()
                }
            }
            .padding(.horizontal, NSpacing.md)
        }
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
