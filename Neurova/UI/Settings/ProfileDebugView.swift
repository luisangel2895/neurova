import AuthenticationServices
import CloudKit
import SwiftData
import SwiftUI

struct ProfileDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
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
                keyValueRow("profile_display_name", value: profileDisplayName.isEmpty ? "<empty>" : profileDisplayName)
                keyValueRow("CloudKit Container", value: containerIdentifier)
                keyValueRow("cloudkit_sync_enabled", value: cloudKitSyncEnabled ? "true" : "false")
                keyValueRow("cloudkit_sync_runtime_active", value: cloudKitRuntimeActive ? "true" : "false")
                keyValueRow("cloudkit_sync_last_error", value: cloudKitLastError.isEmpty ? "<none>" : cloudKitLastError)
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
