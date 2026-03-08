import SwiftData
import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("app_theme") private var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue
    @AppStorage("daily_goal_cards") private var dailyGoalCardsStorage: Int = 20
    @AppStorage("apple_user_id") private var appleUserID: String = ""
    @AppStorage("apple_given_name") private var appleGivenName: String = ""
    @AppStorage("apple_email") private var appleEmail: String = ""
    @AppStorage("profile_display_name") private var profileDisplayName: String = ""
    @AppStorage("cloudkit_sync_enabled") private var cloudKitSyncEnabled: Bool = true
    @AppStorage("auth_session_confirmed") private var authSessionConfirmed: Bool = false

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
    @FocusState private var isDeckInputFocused: Bool

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
            if step == .welcome {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                stepContent
                Spacer(minLength: 0)
            }
            actionFooter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, NSpacing.md + NSpacing.xs)
        .padding(.top, NSpacing.lg)
        .padding(.bottom, (step == .welcome || step == .dailyGoal || step == .subject || step == .deck || step == .firstCard) ? 0 : NSpacing.lg)
        .background(backgroundView.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
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
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTitleColor)
                .lineLimit(1)

            if showsOnboardingProgressStyle {
                welcomeProgressBar
            } else {
                NProgressBar(progress: progressValue)
            }

            Text(stepSubtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(welcomeHeaderSubtitleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            welcomeStepView
        case .dailyGoal:
            dailyGoalCard
        case .subject:
            subjectStepView
        case .deck:
            deckStepView
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
            } else {
                if usesAnimatedPrimaryButton {
                    OnboardingAnimatedPrimaryButton(
                        title: primaryButtonTitle,
                        isDark: colorScheme == .dark,
                        gradientColors: colorScheme == .dark
                            ? [Color(red: 0.30, green: 0.63, blue: 0.95), Color(red: 0.50, green: 0.34, blue: 0.95)]
                            : [Color(red: 0.24, green: 0.50, blue: 0.90), Color(red: 0.30, green: 0.46, blue: 0.87), Color(red: 0.39, green: 0.27, blue: 0.82)]
                    ) {
                        handlePrimaryAction()
                    }
                    .disabled(canContinue == false || isSaving)
                } else {
                    NPrimaryButton(primaryButtonTitle) {
                        handlePrimaryAction()
                    }
                    .disabled(canContinue == false || isSaving)
                }

                if step != .welcome && step != .dailyGoal && step != .subject && step != .deck {
                    NSecondaryButton(AppCopy.text(locale, en: "Back", es: "Atrás")) {
                        goBack()
                    }
                }
            }
        }
    }

    private var dailyGoalCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(dailyGoalInfoCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(dailyGoalInfoCardBorder, lineWidth: 1)
                )
                .frame(height: 85)
                .overlay(alignment: .leading) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(dailyGoalInfoIconBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "scope")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(dailyGoalInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppCopy.text(locale, en: "Your daily goal", es: "Tu meta diaria"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "How many cards do you want to review each day?", es: "¿Cuántas tarjetas quieres repasar cada día?"))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(dailyGoalSecondaryText)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    dailyGoalOptionCard(goal: 10, title: AppCopy.text(locale, en: "Relaxed", es: "Relajado"), icon: "bolt")
                    dailyGoalOptionCard(goal: 20, title: AppCopy.text(locale, en: "Steady", es: "Constante"), icon: "flame")
                }
                HStack(spacing: 12) {
                    dailyGoalOptionCard(goal: 30, title: AppCopy.text(locale, en: "Dedicated", es: "Dedicado"), icon: "trophy")
                    dailyGoalOptionCard(goal: 50, title: AppCopy.text(locale, en: "Intense", es: "Intenso"), icon: "crown")
                }
            }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(dailyGoalHintBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(dailyGoalHintBorder, lineWidth: 1)
                )
                .frame(height: 40)
                .overlay {
                    HStack(spacing: 8) {
                        Image(systemName: "flame")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(dailyGoalInfoIconColor)
                        Text(AppCopy.text(locale, en: "Recommended: 20 cards to start", es: "Recomendado: 20 tarjetas para empezar"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(dailyGoalHintText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                }
        }
    }

    private func dailyGoalOptionCard(goal: Int, title: String, icon: String) -> some View {
        let isSelected = selectedDailyGoal == goal
        return Button {
            selectedDailyGoal = goal
        } label: {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? dailyGoalOptionSelectedBackground : dailyGoalOptionBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? dailyGoalOptionSelectedBorder : dailyGoalOptionBorder, lineWidth: isSelected ? 2 : 1)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Circle()
                            .fill(dailyGoalCheckBackground)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .padding(.top, 10)
                            .padding(.trailing, 10)
                    }
                }
                .overlay {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(dailyGoalIconBadgeBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(dailyGoalIconColor)
                            )
                        Text("\(goal)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryTitleColor)
                        Text(title)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? dailyGoalSelectedLabelColor : dailyGoalSecondaryText)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var subjectStepView: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(subjectInfoCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(subjectInfoCardBorder, lineWidth: 1)
                )
                .frame(height: 85)
                .overlay(alignment: .leading) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(subjectInfoIconBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "graduationcap")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(subjectInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppCopy.text(locale, en: "Create your first subject", es: "Crea tu primera materia"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "Organize your studies by subject for better tracking.", es: "Organiza tus estudios por materias para un mejor seguimiento."))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(subjectSecondaryText)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    subjectOptionCard(title: AppCopy.text(locale, en: "Mathematics", es: "Matemáticas"), icon: "plus.forwardslash.minus")
                    subjectOptionCard(title: AppCopy.text(locale, en: "Science", es: "Ciencias"), icon: "atom")
                }
                HStack(spacing: 12) {
                    subjectOptionCard(title: AppCopy.text(locale, en: "Languages", es: "Idiomas"), icon: "globe")
                    subjectOptionCard(title: AppCopy.text(locale, en: "Art", es: "Arte"), icon: "paintpalette")
                }
                HStack(spacing: 12) {
                    subjectOptionCard(title: AppCopy.text(locale, en: "Music", es: "Música"), icon: "music.note")
                    subjectOptionCard(title: AppCopy.text(locale, en: "Programming", es: "Programación"), icon: "chevron.left.forwardslash.chevron.right")
                }
                HStack(spacing: 12) {
                    subjectOptionCard(title: AppCopy.text(locale, en: "Medicine", es: "Medicina"), icon: "stethoscope")
                    subjectOptionCard(title: AppCopy.text(locale, en: "Other", es: "Otra"), icon: "book")
                }
            }

            Text(AppCopy.text(locale, en: "You can create more subjects later", es: "Podrás crear más materias después"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(subjectSecondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
    }

    private func subjectOptionCard(title: String, icon: String) -> some View {
        let isSelected = subjectName == title
        return Button {
            subjectName = title
        } label: {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? subjectOptionSelectedBackground : subjectOptionBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? subjectOptionSelectedBorder : subjectOptionBorder, lineWidth: isSelected ? 2 : 1)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 82)
                .overlay {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(subjectIconBadgeBackground)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(subjectIconColor)
                            )

                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? subjectSelectedText : subjectOptionText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                }
        }
        .buttonStyle(.plain)
    }

    private var deckStepView: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(deckInfoCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(deckInfoCardBorder, lineWidth: 1)
                )
                .frame(height: 85)
                .overlay(alignment: .leading) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(deckInfoIconBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "square.stack.3d.down.forward")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(deckInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppCopy.text(locale, en: "Create your first deck", es: "Crea tu primer mazo"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "Decks group cards around a specific topic inside your subject.", es: "Los mazos agrupan tarjetas sobre un tema específico dentro de tu materia."))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(deckSecondaryText)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            TextField(
                AppCopy.text(locale, en: "Example: Cell Biology Basics", es: "Ejemplo: Bases de Biología Celular"),
                text: $deckTitle
            )
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(primaryTitleColor)
            .focused($isDeckInputFocused)
            .submitLabel(.done)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.words)
            .onSubmit {
                isDeckInputFocused = false
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(deckInputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isDeckInputFocused ? deckInputActiveBorder : deckInputBorder, lineWidth: isDeckInputFocused ? 1.6 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(deckPreviewBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(deckPreviewBorder, lineWidth: 1)
                )
                .frame(height: 96)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(deckPreviewIconBackground)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "square.stack.3d.down.forward.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(deckPreviewIconColor)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(deckTitleDisplay)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryTitleColor)
                                    .lineLimit(1)
                                Text(AppCopy.text(locale, en: "0 cards · New", es: "0 tarjetas · Nuevo"))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(deckSecondaryText)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 8) {
                            Capsule().fill(deckPreviewSkeleton).frame(height: 4)
                            Capsule().fill(deckPreviewSkeleton).frame(height: 4)
                            Capsule().fill(deckPreviewSkeleton).frame(height: 4)
                            Capsule().fill(deckPreviewSkeleton).frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(AppCopy.text(locale, en: "Or choose a suggestion:", es: "O elige una sugerencia:"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(deckSecondaryText)

                HStack(spacing: 8) {
                    deckSuggestionChip(
                        label: AppCopy.text(locale, en: "🧠 Human Anatomy", es: "🧠 Anatomía Humana"),
                        value: AppCopy.text(locale, en: "Human Anatomy", es: "Anatomía Humana")
                    )
                    deckSuggestionChip(
                        label: AppCopy.text(locale, en: "🧪 Key Formulas", es: "🧪 Fórmulas Clave"),
                        value: AppCopy.text(locale, en: "Key Formulas", es: "Fórmulas Clave")
                    )
                }
                HStack(spacing: 8) {
                    deckSuggestionChip(
                        label: AppCopy.text(locale, en: "📖 Vocabulary", es: "📖 Vocabulario"),
                        value: AppCopy.text(locale, en: "Vocabulary", es: "Vocabulario")
                    )
                    deckSuggestionChip(
                        label: AppCopy.text(locale, en: "⚡ Core Concepts", es: "⚡ Conceptos Base"),
                        value: AppCopy.text(locale, en: "Core Concepts", es: "Conceptos Base")
                    )
                }
                HStack(spacing: 8) {
                    deckSuggestionChip(
                        label: AppCopy.text(locale, en: "✏️ Practice", es: "✏️ Práctica"),
                        value: AppCopy.text(locale, en: "Practice", es: "Práctica")
                    )
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func deckSuggestionChip(label: String, value: String) -> some View {
        let isSelected = deckTitle == value
        return Button {
            deckTitle = value
            isDeckInputFocused = false
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? deckSuggestionSelectedText : deckSuggestionText)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(deckSuggestionBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? deckSuggestionSelectedBorder : deckSuggestionBorder, lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var welcomeStepView: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                welcomeInfoCard

                VStack(spacing: 20) {
                    NImages.Mascot.neruWave
                        .resizable()
                        .scaledToFit()
                        .frame(width: 206, height: 206)

                    HStack(spacing: 5) {
                        welcomeFeatureChip(
                            icon: "book.pages",
                            text: AppCopy.text(locale, en: "Unlimited decks", es: "Decks ilimitados")
                        )
                        welcomeFeatureChip(
                            icon: "sparkles",
                            text: AppCopy.text(locale, en: "Smart review", es: "Repaso inteligente")
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }

    private var welcomeInfoCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(welcomeCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(welcomeCardBorder, lineWidth: 1)
            )
            .frame(height: 85)
            .overlay(
                HStack(alignment: .center, spacing: 16) {
                    Circle()
                        .fill(welcomeCardIconBackground)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "book")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(welcomeCardIconColor)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppCopy.text(locale, en: "Your study control center", es: "Tu centro de estudio"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryTitleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        Text(AppCopy.text(locale, en: "Set up your daily goal and create your first deck in less than a minute.", es: "Configura tu meta diaria y crea tu primer deck en menos de un minuto."))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(welcomeCardBodyTextColor)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12),
                alignment: .leading
            )
    }

    private func welcomeFeatureChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(welcomeChipIconColor)
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(welcomeChipTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .padding(.horizontal, 0)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(welcomeChipBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(welcomeChipBorder, lineWidth: 1)
        )
    }

    private var welcomeProgressBar: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let activeWidth = max(26, proxy.size.width * max(0.16, progressValue))
                let tickTime = timeline.date.timeIntervalSinceReferenceDate
                let phase = (tickTime / 2.0).truncatingRemainder(dividingBy: 1.0)
                let xOffset = (activeWidth * 1.8 * phase) - (activeWidth * 0.9)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(welcomeProgressTrackColor)
                        .frame(height: 5)

                    Capsule()
                        .fill(welcomeProgressActiveGradient)
                        .frame(width: activeWidth, height: 5)
                        .overlay {
                            Capsule()
                                .fill(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, Color.white.opacity(0.30), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 34, height: 8)
                                        .offset(x: xOffset)
                                )
                                .clipShape(Capsule())
                        }
                }
            }
            .frame(height: 5)
        }
    }

    private func textInputCard(title: String, placeholder: String, text: Binding<String>) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTitleColor)

                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryTitleColor)
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTitleColor)

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Front", es: "Frente"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(welcomeHeaderSubtitleColor)
                    TextEditor(text: $cardFront)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(primaryTitleColor)
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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(welcomeHeaderSubtitleColor)
                    TextEditor(text: $cardBack)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(primaryTitleColor)
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTitleColor)

                Text(
                    AppCopy.text(
                        locale,
                        en: "Sign in with Apple to keep your decks, cards, and progress across devices.",
                        es: "Inicia sesión con Apple para mantener tus decks, tarjetas y progreso entre dispositivos."
                    )
                )
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(welcomeHeaderSubtitleColor)
                .fixedSize(horizontal: false, vertical: true)

                if isAuthenticating {
                    HStack(spacing: NSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text(AppCopy.text(locale, en: "Signing in…", es: "Iniciando sesión…"))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(welcomeHeaderSubtitleColor)
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTitleColor)

                Text(AppCopy.text(locale, en: "You are ready to start your first study session.", es: "Ya puedes comenzar tu primera sesión de estudio."))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(welcomeHeaderSubtitleColor)

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

    private var defaultDeckSuggestion: String {
        switch subjectName {
        case AppCopy.text(locale, en: "Mathematics", es: "Matemáticas"):
            return AppCopy.text(locale, en: "Key Formulas", es: "Fórmulas Clave")
        case AppCopy.text(locale, en: "Medicine", es: "Medicina"):
            return AppCopy.text(locale, en: "Human Anatomy", es: "Anatomía Humana")
        case AppCopy.text(locale, en: "Programming", es: "Programación"):
            return AppCopy.text(locale, en: "Core Concepts", es: "Conceptos Base")
        default:
            return AppCopy.text(locale, en: "Human Anatomy", es: "Anatomía Humana")
        }
    }

    private var deckTitleDisplay: String {
        deckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var stepSubtitle: String {
        switch step {
        case .welcome:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .dailyGoal:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .subject:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .deck:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
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

    private var usesAnimatedPrimaryButton: Bool {
        switch step {
        case .welcome, .dailyGoal, .subject, .deck, .firstCard:
            return true
        default:
            return false
        }
    }

    private var showsOnboardingProgressStyle: Bool {
        switch step {
        case .welcome, .dailyGoal, .subject, .deck, .firstCard:
            return true
        default:
            return false
        }
    }

    private func handlePrimaryAction() {
        if step == .subject, deckTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deckTitle = defaultDeckSuggestion
        }

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
                name: firstNonEmpty([
                    subjectName.trimmingCharacters(in: .whitespacesAndNewlines),
                    AppCopy.text(locale, en: "General", es: "General")
                ]) ?? AppCopy.text(locale, en: "General", es: "General"),
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
            dailyGoalCardsStorage = selectedDailyGoal
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
            let email = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if email.isEmpty == false {
                appleEmail = email
            }
            authSessionConfirmed = true

            let displayNameForCloud = firstNonEmpty([givenName, profileDisplayName, appleGivenName])
            let emailForCloud = firstNonEmpty([email, appleEmail])
            do {
                let profile = try fetchOrCreateCloudAccountProfile()
                profile.appleUserID = credential.user
                profile.displayName = displayNameForCloud
                profile.email = emailForCloud
                profile.updatedAt = .now
                try modelContext.save()
            } catch {
                errorMessage = AppCopy.text(
                    locale,
                    en: "Apple login succeeded, but profile sync failed. You can continue and retry later.",
                    es: "El login de Apple funcionó, pero falló la sincronización del perfil. Puedes continuar y reintentar luego."
                )
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

    private func fetchOrCreateCloudAccountProfile() throws -> CloudAccountProfile {
        let descriptor = FetchDescriptor<CloudAccountProfile>(
            predicate: #Predicate<CloudAccountProfile> { profile in
                profile.key == "primary"
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let profile = CloudAccountProfile()
        modelContext.insert(profile)
        return profile
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.isEmpty == false }
    }

    private func finishOnboarding() {
        onFinish()
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color(red: 0.93, green: 0.93, blue: 0.95), Color(red: 0.92, green: 0.92, blue: 0.94)]
                : [Color(red: 0.04, green: 0.05, blue: 0.11), Color(red: 0.03, green: 0.04, blue: 0.09)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var secondaryTextColor: Color {
        colorScheme == .light
            ? Color(red: 0.39, green: 0.43, blue: 0.52)
            : Color(red: 0.34, green: 0.40, blue: 0.53)
    }

    private var welcomeHeaderSubtitleColor: Color {
        colorScheme == .light
            ? Color(red: 0.40, green: 0.44, blue: 0.53)
            : Color(red: 0.53, green: 0.58, blue: 0.70)
    }

    private var primaryTitleColor: Color {
        colorScheme == .light
            ? Color(red: 0.06, green: 0.08, blue: 0.15)
            : Color(red: 0.93, green: 0.95, blue: 0.99)
    }

    private var welcomeCardBackground: Color {
        colorScheme == .light
            ? Color(red: 0.88, green: 0.89, blue: 0.92)
            : Color(red: 0.08, green: 0.10, blue: 0.18)
    }

    private var welcomeCardBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color.white.opacity(0.08)
    }

    private var welcomeCardIconBackground: Color {
        colorScheme == .light
            ? Color(red: 0.81, green: 0.86, blue: 0.97)
            : Color(red: 0.12, green: 0.17, blue: 0.30)
    }

    private var welcomeCardIconColor: Color {
        colorScheme == .light
            ? Color(red: 0.45, green: 0.62, blue: 0.95)
            : Color(red: 0.45, green: 0.66, blue: 0.97)
    }

    private var welcomeChipBackground: Color {
        colorScheme == .light
            ? Color(red: 0.86, green: 0.87, blue: 0.90)
            : Color(red: 0.10, green: 0.12, blue: 0.20)
    }

    private var welcomeChipBorder: Color {
        colorScheme == .light
            ? Color(red: 0.78, green: 0.80, blue: 0.84).opacity(0.9)
            : Color.white.opacity(0.06)
    }

    private var welcomeChipTextColor: Color {
        colorScheme == .light
            ? Color(red: 0.39, green: 0.43, blue: 0.52)
            : Color(red: 0.38, green: 0.43, blue: 0.56)
    }

    private var welcomeChipIconColor: Color {
        colorScheme == .light
            ? Color(red: 0.48, green: 0.63, blue: 0.94)
            : Color(red: 0.42, green: 0.62, blue: 0.96)
    }

    private var welcomeProgressTrackColor: Color {
        colorScheme == .light
            ? Color(red: 0.81, green: 0.82, blue: 0.85)
            : Color(red: 0.13, green: 0.15, blue: 0.23)
    }

    private var welcomeProgressActiveGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color(red: 0.37, green: 0.56, blue: 0.92), Color(red: 0.45, green: 0.34, blue: 0.90)]
                : [Color(red: 0.16, green: 0.63, blue: 0.98), Color(red: 0.48, green: 0.30, blue: 0.96)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var welcomeCardBodyTextColor: Color {
        colorScheme == .light
            ? Color(red: 0.40, green: 0.44, blue: 0.53)
            : Color(red: 0.38, green: 0.43, blue: 0.54)
    }

    private var dailyGoalInfoCardBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.08, green: 0.10, blue: 0.18)
    }

    private var dailyGoalInfoCardBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color.white.opacity(0.08)
    }

    private var dailyGoalInfoIconBackground: Color {
        colorScheme == .light ? Color(red: 0.80, green: 0.86, blue: 0.97) : Color(red: 0.11, green: 0.17, blue: 0.31)
    }

    private var dailyGoalInfoIconColor: Color {
        colorScheme == .light ? Color(red: 0.36, green: 0.55, blue: 0.92) : Color(red: 0.31, green: 0.59, blue: 0.98)
    }

    private var dailyGoalSecondaryText: Color {
        colorScheme == .light ? Color(red: 0.39, green: 0.43, blue: 0.52) : Color(red: 0.36, green: 0.42, blue: 0.55)
    }

    private var dailyGoalOptionBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.09, green: 0.11, blue: 0.19)
    }

    private var dailyGoalOptionBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color(red: 0.16, green: 0.19, blue: 0.30)
    }

    private var dailyGoalOptionSelectedBackground: Color {
        colorScheme == .light ? Color(red: 0.79, green: 0.82, blue: 0.89) : Color(red: 0.11, green: 0.16, blue: 0.28)
    }

    private var dailyGoalOptionSelectedBorder: Color {
        colorScheme == .light ? Color(red: 0.26, green: 0.50, blue: 0.91) : Color(red: 0.25, green: 0.55, blue: 0.98)
    }

    private var dailyGoalIconBadgeBackground: Color {
        colorScheme == .light ? Color(red: 0.84, green: 0.85, blue: 0.89) : Color(red: 0.12, green: 0.15, blue: 0.24)
    }

    private var dailyGoalIconColor: Color {
        colorScheme == .light ? Color(red: 0.32, green: 0.36, blue: 0.45) : Color(red: 0.50, green: 0.55, blue: 0.66)
    }

    private var dailyGoalSelectedLabelColor: Color {
        colorScheme == .light ? Color(red: 0.28, green: 0.50, blue: 0.90) : Color(red: 0.30, green: 0.57, blue: 0.97)
    }

    private var dailyGoalCheckBackground: Color {
        colorScheme == .light ? Color(red: 0.34, green: 0.41, blue: 0.89) : Color(red: 0.35, green: 0.45, blue: 0.96)
    }

    private var dailyGoalHintBackground: Color {
        colorScheme == .light ? Color(red: 0.84, green: 0.87, blue: 0.93) : Color(red: 0.07, green: 0.13, blue: 0.24)
    }

    private var dailyGoalHintBorder: Color {
        colorScheme == .light ? Color(red: 0.75, green: 0.79, blue: 0.89) : Color(red: 0.16, green: 0.27, blue: 0.46)
    }

    private var dailyGoalHintText: Color {
        colorScheme == .light ? Color(red: 0.33, green: 0.37, blue: 0.48) : Color(red: 0.53, green: 0.58, blue: 0.68)
    }

    private var subjectInfoCardBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.08, green: 0.10, blue: 0.18)
    }

    private var subjectInfoCardBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color.white.opacity(0.08)
    }

    private var subjectInfoIconBackground: Color {
        colorScheme == .light ? Color(red: 0.82, green: 0.86, blue: 0.96) : Color(red: 0.11, green: 0.17, blue: 0.31)
    }

    private var subjectInfoIconColor: Color {
        colorScheme == .light ? Color(red: 0.41, green: 0.61, blue: 0.94) : Color(red: 0.37, green: 0.64, blue: 0.97)
    }

    private var subjectSecondaryText: Color {
        colorScheme == .light ? Color(red: 0.40, green: 0.44, blue: 0.53) : Color(red: 0.38, green: 0.43, blue: 0.54)
    }

    private var subjectOptionBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.09, green: 0.11, blue: 0.19)
    }

    private var subjectOptionBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color(red: 0.16, green: 0.19, blue: 0.30)
    }

    private var subjectOptionSelectedBackground: Color {
        colorScheme == .light ? Color(red: 0.80, green: 0.83, blue: 0.90) : Color(red: 0.11, green: 0.16, blue: 0.28)
    }

    private var subjectOptionSelectedBorder: Color {
        colorScheme == .light ? Color(red: 0.26, green: 0.50, blue: 0.91) : Color(red: 0.25, green: 0.55, blue: 0.98)
    }

    private var subjectIconBadgeBackground: Color {
        colorScheme == .light ? Color(red: 0.84, green: 0.85, blue: 0.89) : Color(red: 0.12, green: 0.15, blue: 0.24)
    }

    private var subjectIconColor: Color {
        colorScheme == .light ? Color(red: 0.42, green: 0.45, blue: 0.53) : Color(red: 0.50, green: 0.55, blue: 0.66)
    }

    private var subjectOptionText: Color {
        colorScheme == .light ? Color(red: 0.35, green: 0.37, blue: 0.44) : Color(red: 0.74, green: 0.77, blue: 0.84)
    }

    private var subjectSelectedText: Color {
        colorScheme == .light ? Color(red: 0.19, green: 0.28, blue: 0.48) : Color(red: 0.88, green: 0.91, blue: 0.98)
    }

    private var deckInfoCardBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.08, green: 0.10, blue: 0.18)
    }

    private var deckInfoCardBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color.white.opacity(0.08)
    }

    private var deckInfoIconBackground: Color {
        colorScheme == .light ? Color(red: 0.82, green: 0.86, blue: 0.96) : Color(red: 0.11, green: 0.17, blue: 0.31)
    }

    private var deckInfoIconColor: Color {
        colorScheme == .light ? Color(red: 0.41, green: 0.61, blue: 0.94) : Color(red: 0.37, green: 0.64, blue: 0.97)
    }

    private var deckSecondaryText: Color {
        colorScheme == .light ? Color(red: 0.40, green: 0.44, blue: 0.53) : Color(red: 0.38, green: 0.43, blue: 0.54)
    }

    private var deckInputBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.09, green: 0.11, blue: 0.19)
    }

    private var deckInputBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color(red: 0.16, green: 0.19, blue: 0.30)
    }

    private var deckInputActiveBorder: Color {
        colorScheme == .light ? Color(red: 0.30, green: 0.51, blue: 0.92) : Color(red: 0.25, green: 0.55, blue: 0.98)
    }

    private var deckPreviewBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.08, green: 0.10, blue: 0.18)
    }

    private var deckPreviewBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color.white.opacity(0.08)
    }

    private var deckPreviewIconBackground: Color {
        colorScheme == .light ? Color(red: 0.33, green: 0.47, blue: 0.89) : Color(red: 0.35, green: 0.31, blue: 0.92)
    }

    private var deckPreviewIconColor: Color {
        Color(red: 0.84, green: 0.91, blue: 1.0)
    }

    private var deckPreviewSkeleton: Color {
        colorScheme == .light ? Color(red: 0.80, green: 0.82, blue: 0.87) : Color(red: 0.20, green: 0.23, blue: 0.32)
    }

    private var deckSuggestionBackground: Color {
        colorScheme == .light ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.09, green: 0.11, blue: 0.19)
    }

    private var deckSuggestionBorder: Color {
        colorScheme == .light
            ? Color(red: 0.79, green: 0.80, blue: 0.85).opacity(0.9)
            : Color(red: 0.16, green: 0.19, blue: 0.30)
    }

    private var deckSuggestionSelectedBorder: Color {
        colorScheme == .light ? Color(red: 0.30, green: 0.51, blue: 0.92) : Color(red: 0.25, green: 0.55, blue: 0.98)
    }

    private var deckSuggestionText: Color {
        colorScheme == .light ? Color(red: 0.40, green: 0.43, blue: 0.51) : Color(red: 0.58, green: 0.62, blue: 0.72)
    }

    private var deckSuggestionSelectedText: Color {
        colorScheme == .light ? Color(red: 0.20, green: 0.28, blue: 0.48) : Color(red: 0.86, green: 0.90, blue: 0.98)
    }
}

private struct OnboardingAnimatedPrimaryButton: View {
    let title: String
    let isDark: Bool
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
            }
            .foregroundStyle(isDark ? Color(red: 0.05, green: 0.08, blue: 0.16) : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                TimelineView(.animation) { timeline in
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let tickTime = timeline.date.timeIntervalSinceReferenceDate
                        let phase = (tickTime / 2.15).truncatingRemainder(dividingBy: 1.0)
                        let shinePhase = -1.45 + (2.9 * phase)
                        let xOffset = width * shinePhase

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.clear)
                            .overlay(
                                Ellipse()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .clear,
                                                Color.white.opacity(0.10),
                                                Color.white.opacity(0.30),
                                                Color.white.opacity(0.10),
                                                .clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 188, height: 126)
                                    .rotationEffect(.degrees(20))
                                    .blur(radius: 9)
                                    .offset(x: xOffset)
                            )
                            .blendMode(.screen)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Onboarding Light") {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.light)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}

#Preview("Onboarding Dark") {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.dark)
        .modelContainer(for: [Subject.self, Deck.self, Card.self, CloudAccountProfile.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self], inMemory: true)
}
