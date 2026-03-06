import SwiftData
import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue
    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("cloudkit_sync_enabled") private var cloudKitSyncEnabled: Bool = true

    private let onFinish: () -> Void

    @State private var step: Step = .welcome
    @State private var selectedDailyGoal = 20
    @State private var subjectName = ""
    @State private var deckTitle = ""
    @State private var cardFront = ""
    @State private var cardBack = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var createdDeck: Deck?
    @State private var createdCards: [Card] = []
    @State private var isPresentingFirstStudy = false
    @State private var isAuthenticating = false
    @State private var isWavingMascot = false

    private enum Step: Int, CaseIterable {
        case welcome
        case dailyGoal
        case subject
        case deck
        case firstCard
        case account
        case done
    }

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: NSpacing.lg) {
            progressHeader
            stepContent
            Spacer(minLength: 0)
            actionFooter
        }
        .padding(.horizontal, NSpacing.md + NSpacing.xs)
        .padding(.top, NSpacing.lg)
        .padding(.bottom, NSpacing.lg)
        .background(backgroundView.ignoresSafeArea())
        .fullScreenCover(isPresented: $isPresentingFirstStudy) {
            if let createdDeck {
                NavigationStack {
                    StudyView(
                        deckTitle: createdDeck.title,
                        cards: createdCards,
                        frontText: { $0.frontText },
                        backText: { $0.backText },
                        onBack: {
                            finishOnboarding()
                        }
                    )
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            Text(AppCopy.text(locale, en: "Welcome to Neurova", es: "Bienvenido a Neurova"))
                .font(NTypography.title.weight(.bold))
                .foregroundStyle(NColors.Text.textPrimary)

            NProgressBar(progress: progressValue)

            Text(stepSubtitle)
                .font(NTypography.caption)
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            onboardingCard(
                title: AppCopy.text(locale, en: "Your study control center", es: "Tu centro de estudio"),
                message: AppCopy.text(locale, en: "Set up your daily goal and create your first deck in less than a minute.", es: "Configura tu meta diaria y crea tu primer deck en menos de un minuto.")
            )
        case .dailyGoal:
            dailyGoalCard
        case .subject:
            textInputCard(
                title: AppCopy.text(locale, en: "Create your first subject", es: "Crea tu primera materia"),
                placeholder: AppCopy.text(locale, en: "Example: Biology", es: "Ejemplo: Biología"),
                text: $subjectName
            )
        case .deck:
            textInputCard(
                title: AppCopy.text(locale, en: "Create your first deck", es: "Crea tu primer deck"),
                placeholder: AppCopy.text(locale, en: "Example: Cell Biology Basics", es: "Ejemplo: Bases de Biología Celular"),
                text: $deckTitle
            )
        case .firstCard:
            firstCardEditor
        case .account:
            accountStepCard
        case .done:
            doneStepCard
        }
    }

    private var actionFooter: some View {
        VStack(spacing: NSpacing.sm) {
            if let errorMessage {
                Text(errorMessage)
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Feedback.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if step == .done {
                NPrimaryButton(AppCopy.text(locale, en: "Start first study session", es: "Iniciar primera sesión")) {
                    guard createdCards.isEmpty == false else {
                        finishOnboarding()
                        return
                    }
                    isPresentingFirstStudy = true
                }

                NSecondaryButton(AppCopy.text(locale, en: "Go to app", es: "Ir a la app")) {
                    finishOnboarding()
                }
            } else if step == .account {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                    isAuthenticating = true
                    errorMessage = nil
                } onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
                .disabled(isSaving || isAuthenticating)

                NSecondaryButton(AppCopy.text(locale, en: "Skip for now", es: "Omitir por ahora")) {
                    persistOnboarding()
                }
                .disabled(isSaving || isAuthenticating)
            } else {
                NPrimaryButton(primaryButtonTitle) {
                    handlePrimaryAction()
                }
                .disabled(canContinue == false || isSaving)

                if step != .welcome {
                    NSecondaryButton(AppCopy.text(locale, en: "Back", es: "Atrás")) {
                        goBack()
                    }
                }
            }
        }
    }

    private var dailyGoalCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Pick your daily goal", es: "Elige tu meta diaria"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                HStack(spacing: NSpacing.sm) {
                    ForEach([10, 20, 30, 50], id: \.self) { goal in
                        Button {
                            selectedDailyGoal = goal
                        } label: {
                            Text("\(goal)")
                                .font(NTypography.bodyEmphasis.weight(.semibold))
                                .foregroundStyle(selectedDailyGoal == goal ? NColors.Brand.neuroBlue : NColors.Text.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                        .fill(selectedDailyGoal == goal ? NColors.Home.surfaceL1 : NColors.Neutrals.surfaceAlt)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                        .stroke(
                                            selectedDailyGoal == goal ? NColors.Brand.neuroBlue : NColors.Neutrals.border,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func textInputCard(title: String, placeholder: String, text: Binding<String>) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(title)
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                TextField(placeholder, text: text)
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textPrimary)
                    .padding(.horizontal, NSpacing.md)
                    .frame(height: 48)
                    .background(NColors.Neutrals.surfaceAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                            .stroke(NColors.Neutrals.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
            }
        }
    }

    private var firstCardEditor: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Create your first card", es: "Crea tu primera tarjeta"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Front", es: "Frente"))
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                    TextEditor(text: $cardFront)
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 88)
                        .padding(NSpacing.sm)
                        .background(NColors.Home.surfaceL1)
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                .stroke(NColors.Home.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                }

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Back", es: "Reverso"))
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                    TextEditor(text: $cardBack)
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 88)
                        .padding(NSpacing.sm)
                        .background(NColors.Home.surfaceL1)
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                .stroke(NColors.Home.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                }
            }
        }
    }

    private var accountStepCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm + NSpacing.xs) {
                Text(AppCopy.text(locale, en: "Create account to sync your progress", es: "Crea una cuenta para sincronizar tu progreso"))
                    .font(NTypography.bodyEmphasis.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(
                    AppCopy.text(
                        locale,
                        en: "Sign in with Apple to keep your decks, cards, and progress across devices.",
                        es: "Inicia sesión con Apple para mantener tus decks, tarjetas y progreso entre dispositivos."
                    )
                )
                .font(NTypography.caption)
                .foregroundStyle(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

                if isAuthenticating {
                    HStack(spacing: NSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text(AppCopy.text(locale, en: "Signing in…", es: "Iniciando sesión…"))
                            .font(NTypography.caption)
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.top, NSpacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var doneStepCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Setup complete", es: "Configuración lista"))
                    .font(NTypography.bodyEmphasis.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(AppCopy.text(locale, en: "You are ready to start your first study session.", es: "Ya puedes comenzar tu primera sesión de estudio."))
                    .font(NTypography.body)
                    .foregroundStyle(secondaryTextColor)

                HStack {
                    Spacer(minLength: 0)
                    NImages.Mascot.neruWave
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                        .rotationEffect(.degrees(isWavingMascot ? 15 : 0), anchor: .bottomTrailing)
                        .onAppear {
                            isWavingMascot = false
                            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                                isWavingMascot = true
                            }
                        }
                    Spacer(minLength: 0)
                }
                .padding(.top, NSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func onboardingCard(title: String, message: String) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(title)
                    .font(NTypography.bodyEmphasis.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
                Text(message)
                    .font(NTypography.body)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var progressValue: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    private var stepSubtitle: String {
        switch step {
        case .welcome:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .dailyGoal:
            return AppCopy.text(locale, en: "You can change this later in settings.", es: "Puedes cambiar esto luego en ajustes.")
        case .subject:
            return AppCopy.text(locale, en: "This groups your decks.", es: "Esto agrupa tus decks.")
        case .deck:
            return AppCopy.text(locale, en: "Your first study container.", es: "Tu primer contenedor de estudio.")
        case .firstCard:
            return AppCopy.text(locale, en: "Create one card to launch your first session.", es: "Crea una tarjeta para lanzar tu primera sesión.")
        case .account:
            return AppCopy.text(locale, en: "Optional but recommended for multi-device sync.", es: "Opcional pero recomendado para sincronizar en varios dispositivos.")
        case .done:
            return AppCopy.text(locale, en: "Everything is ready.", es: "Todo está listo.")
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .firstCard:
            return AppCopy.text(locale, en: "Continue", es: "Continuar")
        default:
            return AppCopy.text(locale, en: "Continue", es: "Continuar")
        }
    }

    private var canContinue: Bool {
        switch step {
        case .welcome, .dailyGoal, .account, .done:
            return true
        case .subject:
            return subjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .deck:
            return deckTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .firstCard:
            return cardFront.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                cardBack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    private func handlePrimaryAction() {
        if step == .firstCard {
            withAnimation(.easeInOut(duration: 0.2)) {
                step = .account
            }
            return
        }
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = next
        }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = previous
        }
    }

    private func persistOnboarding() {
        guard isSaving == false else { return }
        isSaving = true
        isAuthenticating = false
        errorMessage = nil

        do {
            let subjectRepository = SwiftDataSubjectRepository(context: modelContext)
            let deckRepository = SwiftDataDeckRepository(context: modelContext)
            let cardRepository = SwiftDataCardRepository(context: modelContext)

            let createdSubject = try subjectRepository.createSubject(
                name: subjectName.trimmingCharacters(in: .whitespacesAndNewlines),
                systemImageName: "book",
                colorTokenReference: nil
            )

            let firstDeck = try deckRepository.createDeck(
                in: createdSubject,
                title: deckTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: nil
            )

            let firstCard = try cardRepository.createCard(
                in: firstDeck,
                frontText: cardFront.trimmingCharacters(in: .whitespacesAndNewlines),
                backText: cardBack.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: .now
            )

            let preferences = try fetchOrCreatePreferences()
            preferences.dailyGoalCards = selectedDailyGoal
            preferences.hasCompletedOnboarding = true
            preferences.preferredThemeRaw = appThemeRawValue
            preferences.preferredLanguageRaw = appLanguageRawValue
            try modelContext.save()

            createdDeck = firstDeck
            createdCards = [firstCard]
            step = .done
        } catch {
            errorMessage = AppCopy.text(
                locale,
                en: "Unable to complete onboarding: \(error.localizedDescription)",
                es: "No se pudo completar el onboarding: \(error.localizedDescription)"
            )
        }

        isSaving = false
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isAuthenticating = false

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = AppCopy.text(locale, en: "Unable to sign in with Apple.", es: "No se pudo iniciar sesión con Apple.")
                return
            }

            appleUserID = credential.user
            cloudKitSyncEnabled = true
            let givenName = credential.fullName?.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if givenName.isEmpty == false {
                appleGivenName = givenName
                profileDisplayName = givenName
            }
            persistOnboarding()

        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            if let authCode = ASAuthorizationError.Code(rawValue: nsError.code) {
                switch authCode {
                case .notHandled:
                    errorMessage = AppCopy.text(
                        locale,
                        en: "Apple sign-in was not completed. Please try again.",
                        es: "El inicio con Apple no se completó. Inténtalo de nuevo."
                    )
                case .failed:
                    errorMessage = AppCopy.text(
                        locale,
                        en: "Apple sign-in failed. Verify the capability is enabled and try again.",
                        es: "Falló el inicio con Apple. Verifica que la capacidad esté habilitada e inténtalo de nuevo."
                    )
                case .invalidResponse:
                    errorMessage = AppCopy.text(
                        locale,
                        en: "Received an invalid Apple response. Try again.",
                        es: "Se recibió una respuesta inválida de Apple. Inténtalo de nuevo."
                    )
                case .unknown:
                    errorMessage = AppCopy.text(
                        locale,
                        en: "Unknown Apple sign-in error. Check iCloud session and try again.",
                        es: "Error desconocido de inicio con Apple. Verifica la sesión de iCloud e inténtalo."
                    )
                default:
                    errorMessage = AppCopy.text(
                        locale,
                        en: "Unable to sign in with Apple right now.",
                        es: "No se pudo iniciar sesión con Apple en este momento."
                    )
                }
            } else {
                errorMessage = AppCopy.text(
                    locale,
                    en: "Unable to sign in with Apple right now.",
                    es: "No se pudo iniciar sesión con Apple en este momento."
                )
            }
        }
    }

    private func fetchOrCreatePreferences() throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { preferences in
                preferences.key == "global"
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let preferences = UserPreferences()
        modelContext.insert(preferences)
        return preferences
    }

    private func finishOnboarding() {
        onFinish()
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("Onboarding Light") {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.light)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}

#Preview("Onboarding Dark") {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.dark)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}
