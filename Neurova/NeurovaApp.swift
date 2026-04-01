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
                            "code=\(nsError.code)"
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

            // Last resort: in-memory store so the app can still launch.
            let inMemory = ModelConfiguration(schema: fullSchema, isStoredInMemoryOnly: true)
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: cloudKitRuntimeActiveKey)
            defaults.set("Emergency in-memory store", forKey: cloudKitLastErrorKey)
            return try! ModelContainer(for: fullSchema, configurations: [inMemory])
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

enum AppDevConfig {
    // Change this during UI work to jump directly into a screen.
    static let defaultLaunchMode: AppLaunchMode = .home
}

enum AppLaunchMode {
    case home
    case bootstrap
    case brandPreview
    case designShowcase
}

struct AppSceneContainer: View {
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








