import AuthenticationServices
import CloudKit
import SwiftData
import SwiftUI

struct ProfileDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("apple_email") private var appleEmail: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("cloudkit_sync_enabled") private var cloudKitSyncEnabled: Bool = true
    @AppStorage("cloudkit_sync_runtime_active") private var cloudKitRuntimeActive: Bool = false
    @AppStorage("cloudkit_sync_last_error") private var cloudKitLastError: String = ""

    @State private var cloudKitStatusText: String = "Not checked"
    @State private var appleCredentialStatusText: String = "Not checked"
    @State private var storageSmokeTestText: String = "Not checked"
    @State private var subjectsCountText: String = "Not checked"
    @State private var preferencesStateText: String = "Not checked"
    @State private var latestErrorText: String = "-"
    @State private var cloudContainerProbeText: String = "Not checked"
    @State private var localContainerProbeText: String = "Not checked"
    @State private var modelEntityProbeText: String = "Not checked"
    @State private var fileSystemProbeText: String = "Not checked"
    @State private var cloudIdentityProbeText: String = "Not checked"
    @State private var cloudSchemaStageProbeText: String = "Not checked"
    @State private var cloudRecordProbeText: String = "Not checked"
    @State private var cloudProfileDisplayNameText: String = "Not checked"
    @State private var cloudProfileEmailText: String = "Not checked"
    @State private var cloudProfileUpdatedAtText: String = "Not checked"

    private let containerIdentifier = "iCloud.com.angelorellana.neurova"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                headerCard
                accountCard
                statusCard
                actionsCard
            }
            .padding(.horizontal, NSpacing.md)
            .padding(.vertical, NSpacing.md)
        }
        .background(backgroundView.ignoresSafeArea())
        .navigationTitle(AppCopy.text(locale, en: "Profile Debug", es: "Debug de Perfil"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            refreshLocalState()
        }
    }

    private var headerCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                Text(AppCopy.text(locale, en: "Diagnostics", es: "Diagnóstico"))
                    .font(NTypography.bodyEmphasis.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
                Text(AppCopy.text(locale, en: "Use this screen to debug Apple Sign In, CloudKit and SwiftData persistence.", es: "Usa esta pantalla para depurar Apple Sign In, CloudKit y la persistencia de SwiftData."))
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var accountCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                keyValueRow("apple_user_id", value: appleUserID.isEmpty ? "<empty>" : appleUserID)
                keyValueRow("apple_given_name", value: appleGivenName.isEmpty ? "<empty>" : appleGivenName)
                keyValueRow("apple_email", value: appleEmail.isEmpty ? "<empty>" : appleEmail)
                keyValueRow("profile_display_name", value: profileDisplayName.isEmpty ? "<empty>" : profileDisplayName)
                keyValueRow("CloudKit Container", value: containerIdentifier)
                keyValueRow("cloudkit_sync_enabled", value: cloudKitSyncEnabled ? "true" : "false")
                keyValueRow("cloudkit_sync_runtime_active", value: cloudKitRuntimeActive ? "true" : "false")
                keyValueRow("cloudkit_sync_last_error", value: cloudKitLastError.isEmpty ? "<none>" : cloudKitLastError)
                keyValueRow("cloud_profile_display_name", value: cloudProfileDisplayNameText)
                keyValueRow("cloud_profile_email", value: cloudProfileEmailText)
                keyValueRow("cloud_profile_updated_at", value: cloudProfileUpdatedAtText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                keyValueRow(AppCopy.text(locale, en: "iCloud account", es: "Cuenta iCloud"), value: cloudKitStatusText)
                keyValueRow(AppCopy.text(locale, en: "Apple credential", es: "Credencial Apple"), value: appleCredentialStatusText)
                keyValueRow(AppCopy.text(locale, en: "SwiftData smoke test", es: "Prueba SwiftData"), value: storageSmokeTestText)
                keyValueRow(AppCopy.text(locale, en: "Cloud container probe", es: "Prueba contenedor cloud"), value: cloudContainerProbeText)
                keyValueRow(AppCopy.text(locale, en: "Local container probe", es: "Prueba contenedor local"), value: localContainerProbeText)
                keyValueRow(AppCopy.text(locale, en: "Subject/Deck/Card probe", es: "Prueba Subject/Deck/Card"), value: modelEntityProbeText)
                keyValueRow(AppCopy.text(locale, en: "Cloud identity probe", es: "Prueba identidad Cloud"), value: cloudIdentityProbeText)
                keyValueRow(AppCopy.text(locale, en: "Cloud schema stage probe", es: "Prueba etapas schema cloud"), value: cloudSchemaStageProbeText)
                keyValueRow(AppCopy.text(locale, en: "CloudKit record probe", es: "Prueba registro CloudKit"), value: cloudRecordProbeText)
                keyValueRow(AppCopy.text(locale, en: "Store files probe", es: "Prueba archivos store"), value: fileSystemProbeText)
                keyValueRow(AppCopy.text(locale, en: "Subjects count", es: "Total materias"), value: subjectsCountText)
                keyValueRow(AppCopy.text(locale, en: "Global preferences", es: "Preferencias globales"), value: preferencesStateText)
                keyValueRow(AppCopy.text(locale, en: "Latest error", es: "Último error"), value: latestErrorText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionsCard: some View {
        NCard {
            VStack(spacing: NSpacing.sm) {
                NPrimaryButton(AppCopy.text(locale, en: "Check iCloud account", es: "Verificar cuenta iCloud")) {
                    checkCloudKitStatus()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Check Apple credential state", es: "Verificar credencial Apple")) {
                    checkAppleCredentialState()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Run SwiftData write test", es: "Probar escritura SwiftData")) {
                    runStorageSmokeTest()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Probe Subject/Deck/Card chain", es: "Probar cadena Subject/Deck/Card")) {
                    runModelEntityProbe()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Probe model containers", es: "Probar model containers")) {
                    runContainerProbes()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Probe Cloud identity", es: "Probar identidad Cloud")) {
                    runCloudIdentityProbe()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Probe cloud schema stages", es: "Probar etapas schema cloud")) {
                    runCloudSchemaStageProbe()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Probe CloudKit record I/O", es: "Probar lectura/escritura CloudKit")) {
                    runCloudRecordProbe()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Inspect store files", es: "Inspeccionar archivos store")) {
                    runFileSystemProbe()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Run full diagnostics", es: "Ejecutar diagnóstico completo")) {
                    runFullDiagnostics()
                }

                NSecondaryButton(
                    cloudKitSyncEnabled
                    ? AppCopy.text(locale, en: "Disable CloudKit sync (restart app)", es: "Desactivar sync CloudKit (reiniciar app)")
                    : AppCopy.text(locale, en: "Enable CloudKit sync (restart app)", es: "Activar sync CloudKit (reiniciar app)")
                ) {
                    cloudKitSyncEnabled.toggle()
                }

                NSecondaryButton(AppCopy.text(locale, en: "Refresh local state", es: "Actualizar estado local")) {
                    refreshLocalState()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        AppCopy.text(
                            locale,
                            en: "Display name for Home greeting",
                            es: "Nombre mostrado para saludo en Home"
                        )
                    )
                    .font(NTypography.micro.weight(.bold))
                    .foregroundStyle(NColors.Text.textTertiary)

                    TextField(
                        AppCopy.text(locale, en: "Example: Angel", es: "Ejemplo: Angel"),
                        text: $profileDisplayName
                    )
                    .font(NTypography.body)
                    .padding(.horizontal, NSpacing.md)
                    .frame(height: 44)
                    .background(NColors.Neutrals.surfaceAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                            .stroke(NColors.Neutrals.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
                }
            }
        }
    }

    private func keyValueRow(_ key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(NTypography.micro.weight(.bold))
                .foregroundStyle(NColors.Text.textTertiary)
            Text(value)
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textPrimary)
                .textSelection(.enabled)
        }
    }

    private func checkCloudKitStatus() {
        CKContainer(identifier: containerIdentifier).accountStatus { status, error in
            DispatchQueue.main.async {
                if let error {
                    cloudKitStatusText = "Error: \(error.localizedDescription)"
                    latestErrorText = "CloudKit: \(error.localizedDescription)"
                    return
                }

                switch status {
                case .available:
                    cloudKitStatusText = "available"
                case .noAccount:
                    cloudKitStatusText = "noAccount"
                case .restricted:
                    cloudKitStatusText = "restricted"
                case .couldNotDetermine:
                    cloudKitStatusText = "couldNotDetermine"
                case .temporarilyUnavailable:
                    cloudKitStatusText = "temporarilyUnavailable"
                @unknown default:
                    cloudKitStatusText = "unknown"
                }
            }
        }
    }

    private func checkAppleCredentialState() {
        guard appleUserID.isEmpty == false else {
            appleCredentialStatusText = "No apple_user_id saved"
            return
        }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleUserID) { state, error in
            DispatchQueue.main.async {
                if let error {
                    appleCredentialStatusText = "Error: \(error.localizedDescription)"
                    latestErrorText = "Apple credential: \(error.localizedDescription)"
                    return
                }

                switch state {
                case .authorized:
                    appleCredentialStatusText = "authorized"
                case .revoked:
                    appleCredentialStatusText = "revoked"
                case .notFound:
                    appleCredentialStatusText = "notFound"
                case .transferred:
                    appleCredentialStatusText = "transferred"
                @unknown default:
                    appleCredentialStatusText = "unknown"
                }
            }
        }
    }

    private func runStorageSmokeTest() {
        do {
            let subjectName = "Debug Subject \(Int(Date().timeIntervalSince1970))"
            let repository = SwiftDataSubjectRepository(context: modelContext)
            let created = try repository.createSubject(
                name: subjectName,
                systemImageName: "wrench.and.screwdriver",
                colorTokenReference: "NeuroBlue"
            )

            let subjects = try repository.listSubjects()
            let existsByID = subjects.contains { $0.id == created.id }
            let existsByName = subjects.contains { $0.name == subjectName }
            if let inserted = subjects.first(where: { $0.id == created.id || $0.name == subjectName }) {
                try repository.deleteSubject(inserted)
            }

            if existsByID || existsByName {
                storageSmokeTestText = "OK (create/fetch/delete)"
            } else {
                storageSmokeTestText = "Failed (not found after create) - fetched \(subjects.count)"
            }
            refreshLocalState()
        } catch {
            storageSmokeTestText = "Error: \(error.localizedDescription)"
            latestErrorText = "SwiftData: \(error.localizedDescription)"
        }
    }

    private func runModelEntityProbe() {
        do {
            let timestamp = Int(Date().timeIntervalSince1970)
            let subjectRepository = SwiftDataSubjectRepository(context: modelContext)
            let deckRepository = SwiftDataDeckRepository(context: modelContext)
            let cardRepository = SwiftDataCardRepository(context: modelContext)

            let subject = try subjectRepository.createSubject(
                name: "Probe Subject \(timestamp)",
                systemImageName: "checkmark.seal",
                colorTokenReference: "NeuroBlue"
            )

            let deck = try deckRepository.createDeck(
                in: subject,
                title: "Probe Deck \(timestamp)",
                description: "CloudKit probe"
            )

            let card = try cardRepository.createCard(
                in: deck,
                frontText: "Probe front \(timestamp)",
                backText: "Probe back \(timestamp)",
                createdAt: .now
            )

            let subjects = try subjectRepository.listSubjects()
            let found = subjects.contains { subjectItem in
                subjectItem.id == subject.id &&
                (subjectItem.decks ?? []).contains { $0.id == deck.id && ($0.cards ?? []).contains(where: { $0 === card }) }
            }

            try subjectRepository.deleteSubject(subject)

            modelEntityProbeText = found ? "OK (create/fetch/delete chain)" : "Failed (chain not found after create)"
            if found == false {
                latestErrorText = "Model probe: chain not found after create"
            }
            refreshLocalState()
        } catch {
            let details = expandedErrorDetails(error)
            modelEntityProbeText = "Error: \(details)"
            latestErrorText = "Model probe: \(details)"
        }
    }

    private func runContainerProbes() {
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
            let cloudSchema = Schema([
                Subject.self,
                Deck.self,
                Card.self,
                CloudAccountProfile.self
            ])
            let localOnlySchema = Schema([
                XPEventEntity.self,
                XPStatsEntity.self,
                UserPreferences.self,
                ScanEntity.self
            ])
            let cloudConfiguration = ModelConfiguration("cloudProbe", schema: cloudSchema)
            let localConfiguration = ModelConfiguration("localProbe", schema: localOnlySchema, cloudKitDatabase: .none)
            _ = try ModelContainer(for: fullSchema, configurations: [cloudConfiguration, localConfiguration])
            cloudContainerProbeText = "OK"
        } catch {
            let details = expandedErrorDetails(error)
            cloudContainerProbeText = "Error: \(details)"
            latestErrorText = "Cloud container probe: \(details)"
        }

        do {
            let localConfiguration = ModelConfiguration(schema: fullSchema, cloudKitDatabase: .none)
            _ = try ModelContainer(for: fullSchema, configurations: [localConfiguration])
            localContainerProbeText = "OK"
        } catch {
            let details = expandedErrorDetails(error)
            localContainerProbeText = "Error: \(details)"
            latestErrorText = "Local container probe: \(details)"
        }
    }

    private func runCloudIdentityProbe() {
        let container = CKContainer(identifier: containerIdentifier)
        container.fetchUserRecordID { recordID, error in
            DispatchQueue.main.async {
                if let error {
                    let details = expandedErrorDetails(error)
                    cloudIdentityProbeText = "Error: \(details)"
                    latestErrorText = "Cloud identity: \(details)"
                    return
                }

                if let recordID {
                    cloudIdentityProbeText = "OK (\(recordID.recordName))"
                } else {
                    cloudIdentityProbeText = "No record ID returned"
                }
            }
        }
    }

    private func runFileSystemProbe() {
        let manager = FileManager.default
        do {
            let appSupport = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let enumerator = manager.enumerator(
                at: appSupport,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            var lines: [String] = []
            while let url = enumerator?.nextObject() as? URL {
                let ext = url.pathExtension.lowercased()
                if ["sqlite", "store", "db", "wal", "shm"].contains(ext) {
                    let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    if values?.isRegularFile == true {
                        let relativePath = url.path.replacingOccurrences(of: appSupport.path + "/", with: "")
                        let size = values?.fileSize ?? 0
                        lines.append("\(relativePath) (\(size) bytes)")
                    }
                }
            }

            if lines.isEmpty {
                fileSystemProbeText = "No store-like files in Application Support"
            } else {
                fileSystemProbeText = "Found \(lines.count) files"
                latestErrorText = "Store files: " + lines.prefix(8).joined(separator: " | ")
            }
        } catch {
            let details = expandedErrorDetails(error)
            fileSystemProbeText = "Error: \(details)"
            latestErrorText = "File probe: \(details)"
        }
    }

    private func runFullDiagnostics() {
        refreshLocalState()
        checkCloudKitStatus()
        checkAppleCredentialState()
        runStorageSmokeTest()
        runModelEntityProbe()
        runContainerProbes()
        runCloudIdentityProbe()
        runCloudSchemaStageProbe()
        runCloudRecordProbe()
        runFileSystemProbe()
    }

    private func runCloudSchemaStageProbe() {
        func probe(_ schema: Schema, name: String) -> String {
            do {
                let configuration = ModelConfiguration(name, schema: schema)
                _ = try ModelContainer(for: schema, configurations: [configuration])
                return "OK"
            } catch {
                return "Error: \(expandedErrorDetails(error))"
            }
        }

        let subjectOnly = probe(Schema([Subject.self]), name: "cloudStageSubject")
        let subjectDeck = probe(Schema([Subject.self, Deck.self]), name: "cloudStageSubjectDeck")
        let subjectDeckCard = probe(Schema([Subject.self, Deck.self, Card.self]), name: "cloudStageSubjectDeckCard")

        cloudSchemaStageProbeText = "S=\(subjectOnly) | SD=\(subjectDeck) | SDC=\(subjectDeckCard)"
        if subjectOnly.hasPrefix("Error:") || subjectDeck.hasPrefix("Error:") || subjectDeckCard.hasPrefix("Error:") {
            latestErrorText = cloudSchemaStageProbeText
        }
    }

    private func runCloudRecordProbe() {
        let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "probe-\(UUID().uuidString.lowercased())")
        let record = CKRecord(recordType: "ProfileDebugProbe", recordID: recordID)
        record["createdAt"] = Date() as NSDate
        record["app"] = "Neurova" as NSString

        database.save(record) { savedRecord, saveError in
            if let saveError {
                DispatchQueue.main.async {
                    let details = expandedErrorDetails(saveError)
                    cloudRecordProbeText = "Save error: \(details)"
                    latestErrorText = "Cloud record save: \(details)"
                }
                return
            }

            guard let savedRecord else {
                DispatchQueue.main.async {
                    cloudRecordProbeText = "Save failed: no record returned"
                    latestErrorText = "Cloud record save: no record returned"
                }
                return
            }

            database.fetch(withRecordID: savedRecord.recordID) { fetchedRecord, fetchError in
                if let fetchError {
                    DispatchQueue.main.async {
                        let details = expandedErrorDetails(fetchError)
                        cloudRecordProbeText = "Fetch error: \(details)"
                        latestErrorText = "Cloud record fetch: \(details)"
                    }
                    return
                }

                guard fetchedRecord != nil else {
                    DispatchQueue.main.async {
                        cloudRecordProbeText = "Fetch failed: nil record"
                        latestErrorText = "Cloud record fetch: nil record"
                    }
                    return
                }

                database.delete(withRecordID: savedRecord.recordID) { _, deleteError in
                    DispatchQueue.main.async {
                        if let deleteError {
                            let details = expandedErrorDetails(deleteError)
                            cloudRecordProbeText = "Save+Fetch OK, delete error: \(details)"
                            latestErrorText = "Cloud record delete: \(details)"
                        } else {
                            cloudRecordProbeText = "OK (save/fetch/delete)"
                        }
                    }
                }
            }
        }
    }

    private func expandedErrorDetails(_ error: Error) -> String {
        let nsError = error as NSError
        let userInfoDump = nsError.userInfo
            .map { key, value in "\(key)=\(value)" }
            .joined(separator: ", ")
        return "domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription) userInfo={\(userInfoDump)}"
    }

    private func refreshLocalState() {
        do {
            let subjectRepository = SwiftDataSubjectRepository(context: modelContext)
            let subjects = try subjectRepository.listSubjects()
            subjectsCountText = "\(subjects.count)"
        } catch {
            subjectsCountText = "Error: \(error.localizedDescription)"
            latestErrorText = "Subjects: \(error.localizedDescription)"
        }

        do {
            let descriptor = FetchDescriptor<CloudAccountProfile>(
                predicate: #Predicate<CloudAccountProfile> { profile in
                    profile.key == "primary"
                }
            )
            let profile = try modelContext.fetch(descriptor).first
            if let profile {
                cloudProfileDisplayNameText = profile.displayName?.isEmpty == false ? (profile.displayName ?? "<empty>") : "<empty>"
                cloudProfileEmailText = profile.email?.isEmpty == false ? (profile.email ?? "<empty>") : "<empty>"
                cloudProfileUpdatedAtText = profile.updatedAt.formatted(date: .abbreviated, time: .shortened)
            } else {
                cloudProfileDisplayNameText = "missing"
                cloudProfileEmailText = "missing"
                cloudProfileUpdatedAtText = "missing"
            }
        } catch {
            cloudProfileDisplayNameText = "Error: \(error.localizedDescription)"
            cloudProfileEmailText = "Error: \(error.localizedDescription)"
            cloudProfileUpdatedAtText = "Error: \(error.localizedDescription)"
        }

        do {
            let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate<UserPreferences> { preferences in
                    preferences.key == "global"
                }
            )
            let preferences = try modelContext.fetch(descriptor).first
            if let preferences {
                preferencesStateText = "exists (goal: \(preferences.dailyGoalCards), onboarding: \(preferences.hasCompletedOnboarding))"
            } else {
                preferencesStateText = "missing"
            }
        } catch {
            preferencesStateText = "Error: \(error.localizedDescription)"
            latestErrorText = "Preferences: \(error.localizedDescription)"
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
