import SwiftData
import SwiftUI
import AuthenticationServices
import UIKit

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
    @State private var isDeckInputFocused = false
    @State private var isFirstCardFrontFocused = false
    @State private var isFirstCardBackFocused = false
    @State private var lockedViewportHeight: CGFloat = 0

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
        GeometryReader { proxy in
            let effectiveHeight = lockedViewportHeight > 0 ? lockedViewportHeight : proxy.size.height

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
            .frame(width: proxy.size.width, height: effectiveHeight, alignment: .top)
            .onAppear {
                if lockedViewportHeight == 0 {
                    lockedViewportHeight = proxy.size.height
                }
            }
            .onChange(of: proxy.size.height, initial: false) { _, newHeight in
                if lockedViewportHeight == 0 {
                    lockedViewportHeight = newHeight
                }
            }
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
                NGradientButton(
                    AppCopy.text(locale, en: "Start studying", es: "Comenzar a estudiar"),
                    leadingSymbolName: "sparkles",
                    showsChevron: false,
                    animateEffects: true,
                    font: .system(size: 18, weight: .regular, design: .rounded)
                ) {
                    guard createdCards.isEmpty == false else {
                        finishOnboarding()
                        return
                    }
                    isPresentingFirstStudy = true
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
                .frame(height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .disabled(isSaving || isAuthenticating)
            } else {
                if usesAnimatedPrimaryButton {
                    NGradientButton(
                        primaryButtonTitle,
                        showsChevron: true,
                        animateEffects: true,
                        font: .system(size: 18, weight: .regular, design: .rounded)
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

                if step != .welcome && step != .dailyGoal && step != .subject && step != .deck && step != .firstCard {
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

            OnboardingDeckTextField(
                placeholder: AppCopy.text(locale, en: "Example: Cell Biology Basics", es: "Ejemplo: Bases de Biología Celular"),
                text: $deckTitle,
                isFocused: $isDeckInputFocused,
                isDark: colorScheme == .dark
            ) {
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
                    TimelineView(.animation) { timeline in
                        NImages.Mascot.neruWave
                            .resizable()
                            .scaledToFit()
                            .frame(width: 206, height: 206)
                            .rotationEffect(.degrees(welcomeWaveAngle(for: timeline.date)), anchor: .center)
                    }

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

                NOptimizedInputField(
                    placeholder: placeholder,
                    text: text,
                    returnKeyType: .done,
                    autocapitalization: .sentences,
                    font: .systemFont(ofSize: 15, weight: .regular),
                    textColor: UIColor(primaryTitleColor),
                    tintColor: UIColor(NColors.Brand.neuroBlue)
                )
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
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(firstCardInfoBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(firstCardInfoBorder, lineWidth: 1)
                )
                .frame(height: 100)
                .overlay(alignment: .leading) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(firstCardInfoIconBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(firstCardInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppCopy.text(locale, en: "Create your first card", es: "Crea tu primera tarjeta"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "Write the front and back of your first flashcard to start studying.", es: "Escribe el frente y reverso de tu primera flashcard para empezar a estudiar."))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(firstCardSecondaryText)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppCopy.text(locale, en: "FRONT", es: "FRENTE"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(firstCardFrontLabel)
                    .tracking(0.8)

                NOptimizedTextField(
                    placeholder: AppCopy.text(locale, en: "Ex: What is mitochondria?", es: "Ej: ¿Qué es la mitocondria?"),
                    text: $cardFront,
                    isFocused: $isFirstCardFrontFocused,
                    returnKeyType: .done,
                    autocapitalization: .sentences,
                    font: .systemFont(ofSize: 16, weight: .medium),
                    textColor: UIColor(primaryTitleColor),
                    tintColor: UIColor(NColors.Brand.neuroBlue),
                    onSubmit: { isFirstCardFrontFocused = false }
                )
                .padding(.horizontal, 16)
                .frame(height: 58)
                .background(firstCardInputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFirstCardFrontFocused ? firstCardInputActiveBorder : firstCardInputBorder, lineWidth: isFirstCardFrontFocused ? 1.6 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppCopy.text(locale, en: "BACK", es: "REVERSO"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(firstCardBackLabel)
                    .tracking(0.8)

                NOptimizedTextField(
                    placeholder: AppCopy.text(locale, en: "Ex: Organelle that produces energy (ATP).", es: "Ej: Orgánulo que produce energía (ATP)."),
                    text: $cardBack,
                    isFocused: $isFirstCardBackFocused,
                    returnKeyType: .done,
                    autocapitalization: .sentences,
                    font: .systemFont(ofSize: 16, weight: .medium),
                    textColor: UIColor(primaryTitleColor),
                    tintColor: UIColor(NColors.Brand.neuroBlue),
                    onSubmit: { isFirstCardBackFocused = false }
                )
                .padding(.horizontal, 16)
                .frame(height: 58)
                .background(firstCardInputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFirstCardBackFocused ? firstCardInputActiveBorder : firstCardInputBorder, lineWidth: isFirstCardBackFocused ? 1.6 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let yOffset = sin(t * 1.25) * 8

                NImages.Mascot.neruHappy
                    .resizable()
                    .scaledToFit()
                    .frame(width: 116, height: 116)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .offset(y: yOffset)
            }

            Text(AppCopy.text(locale, en: "Your first card is about to be born! 🎉", es: "¡Tu primera tarjeta está a punto de nacer! 🎉"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(firstCardSecondaryText)
                .frame(maxWidth: .infinity, alignment: .center)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(firstCardTipBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(firstCardTipBorder, lineWidth: 1)
                )
                .frame(minHeight: 56)
                .overlay(alignment: .leading) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(firstCardTipIcon)
                        Text(AppCopy.text(locale, en: "Tip: simple, concrete questions improve retention.", es: "Tip: preguntas simples y concretas mejoran la retención."))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(firstCardTipText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .padding(.top, 2)
        }
    }

    private var accountStepCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(accountInfoBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accountInfoBorder, lineWidth: 1)
                )
                .frame(height: 95)
                .overlay(alignment: .leading) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(accountInfoIconBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "shield")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(accountInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppCopy.text(locale, en: "Sign in with Apple", es: "Inicia sesión con Apple"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "Required to sync your progress and protect your data.", es: "Obligatorio para sincronizar tu progreso y proteger tus datos."))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(accountSecondaryText)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let yOffset = sin(t * 1.25) * 8

                NImages.Mascot.neruThinking
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .frame(maxWidth: .infinity)
                    .offset(y: yOffset)
            }

            Text(AppCopy.text(locale, en: "One tap to protect your progress and access it from any device.", es: "Un solo toque para proteger tu progreso y acceder desde cualquier dispositivo."))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(accountSecondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                accountFeatureRow(
                    icon: "lock",
                    text: AppCopy.text(locale, en: "End-to-end encryption", es: "Cifrado de extremo a extremo")
                )
                accountFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: AppCopy.text(locale, en: "Automatic sync across devices", es: "Sincronización automática en todos tus dispositivos"),
                    maxLines: 2,
                    minHeight: 62
                )
                accountFeatureRow(
                    icon: "bolt",
                    text: AppCopy.text(locale, en: "No passwords, one tap and done", es: "Sin contraseñas, un toque y listo")
                )
            }
            .padding(.top, 20)

            if isAuthenticating {
                HStack(spacing: NSpacing.xs) {
                    ProgressView()
                        .controlSize(.small)
                    Text(AppCopy.text(locale, en: "Signing in…", es: "Iniciando sesión…"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(accountSecondaryText)
                }
                .padding(.top, NSpacing.xs)
            }
        }
    }

    private func accountFeatureRow(icon: String, text: String, maxLines: Int = 1, minHeight: CGFloat = 50) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(accountFeatureBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accountFeatureBorder, lineWidth: 1)
            )
            .frame(minHeight: minHeight)
            .overlay(alignment: .leading) {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accountFeatureIconBackground)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(accountFeatureIconColor)
                        )

                    Text(text)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(accountSecondaryText)
                        .lineLimit(maxLines)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.9)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
            }
    }

    private var doneStepCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(doneInfoBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(doneInfoBorder, lineWidth: 1)
                )
                .frame(height: 90)
                .overlay(alignment: .leading) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(doneInfoIconBackground)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(doneInfoIconColor)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppCopy.text(locale, en: "All set!", es: "¡Todo listo!"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryTitleColor)
                            Text(AppCopy.text(locale, en: "Your account is configured and ready to start.", es: "Tu cuenta está configurada y lista para comenzar."))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(welcomeHeaderSubtitleColor)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                }

            Circle()
                .fill(welcomeProgressActiveGradient)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .padding(.top, 2)

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let yOffset = sin(t * 0.95) * 8
                let rotation = sin(t * 1.9) * 4

                NImages.Mascot.neruCelebrate
                    .resizable()
                    .scaledToFit()
                    .frame(width: 122, height: 122)
                    .frame(maxWidth: .infinity)
                    .offset(y: yOffset)
                    .rotationEffect(.degrees(rotation))
            }

            HStack(spacing: 10) {
                doneStatTile(icon: "book", value: "1", label: AppCopy.text(locale, en: "Subject", es: "Materia"))
                doneStatTile(icon: "sparkles", value: "1", label: AppCopy.text(locale, en: "Deck", es: "Mazo"))
                doneStatTile(icon: "brain.head.profile", value: "\(selectedDailyGoal)", label: AppCopy.text(locale, en: "Goal/day", es: "Meta/día"))
            }

            Text(AppCopy.text(locale, en: "You are about to master your learning! 🚀", es: "¡Estás a punto de dominar tu aprendizaje! 🚀"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(welcomeHeaderSubtitleColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    private func doneStatTile(icon: String, value: String, label: String) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(doneStatBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(doneStatBorder, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 116)
            .overlay {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(doneInfoIconBackground)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(doneInfoIconColor)
                        )
                    Text(value)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(primaryTitleColor)
                    Text(label)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(welcomeHeaderSubtitleColor)
                }
                .padding(.horizontal, 8)
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
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .account:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
        case .done:
            return AppCopy.text(locale, en: "Quick setup to start studying.", es: "Configuración rápida para empezar a estudiar.")
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

    private func welcomeWaveAngle(for date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        let cycleDuration = 4.0
        let activeDuration = 2.0
        let phase = t.truncatingRemainder(dividingBy: cycleDuration)
        guard phase <= activeDuration else { return 0 }

        let progress = phase / activeDuration
        let envelope = pow(sin(progress * .pi), 2)
        return sin(progress * .pi * 4) * 6 * envelope
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
        case .welcome, .dailyGoal, .subject, .deck, .firstCard, .account, .done:
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
            colors: [NColors.Onboarding.backgroundTop, NColors.Onboarding.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var secondaryTextColor: Color {
        NColors.Onboarding.secondaryText
    }

    private var welcomeHeaderSubtitleColor: Color {
        NColors.Onboarding.headerSubtitle
    }

    private var primaryTitleColor: Color {
        NColors.Onboarding.title
    }

    private var welcomeCardBackground: Color {
        NColors.Onboarding.cardBackground
    }

    private var welcomeCardBorder: Color {
        NColors.Onboarding.cardBorder
    }

    private var welcomeCardIconBackground: Color {
        NColors.Onboarding.cardIconBackground
    }

    private var welcomeCardIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var welcomeChipBackground: Color {
        NColors.Onboarding.chipBackground
    }

    private var welcomeChipBorder: Color {
        NColors.Onboarding.chipBorder
    }

    private var welcomeChipTextColor: Color {
        NColors.Onboarding.chipText
    }

    private var welcomeChipIconColor: Color {
        NColors.Onboarding.chipIcon
    }

    private var welcomeProgressTrackColor: Color {
        NColors.Onboarding.progressTrack
    }

    private var welcomeProgressActiveGradient: LinearGradient {
        NColors.Onboarding.progressGradient(for: colorScheme)
    }

    private var welcomeCardBodyTextColor: Color {
        NColors.Onboarding.cardBodyText
    }

    private var dailyGoalInfoCardBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var dailyGoalInfoCardBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var dailyGoalInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var dailyGoalInfoIconColor: Color {
        NColors.Onboarding.infoIconColor
    }

    private var dailyGoalSecondaryText: Color {
        NColors.Onboarding.infoSecondaryText
    }

    private var dailyGoalOptionBackground: Color {
        NColors.Onboarding.optionBackground
    }

    private var dailyGoalOptionBorder: Color {
        NColors.Onboarding.optionBorder
    }

    private var dailyGoalOptionSelectedBackground: Color {
        NColors.Onboarding.optionSelectedBackground
    }

    private var dailyGoalOptionSelectedBorder: Color {
        NColors.Onboarding.optionSelectedBorder
    }

    private var dailyGoalIconBadgeBackground: Color {
        NColors.Onboarding.iconBadgeBackground
    }

    private var dailyGoalIconColor: Color {
        NColors.Onboarding.iconColor
    }

    private var dailyGoalSelectedLabelColor: Color {
        NColors.Onboarding.selectedLabel
    }

    private var dailyGoalCheckBackground: Color {
        NColors.Onboarding.checkBackground
    }

    private var dailyGoalHintBackground: Color {
        NColors.Onboarding.hintBackground
    }

    private var dailyGoalHintBorder: Color {
        NColors.Onboarding.hintBorder
    }

    private var dailyGoalHintText: Color {
        NColors.Onboarding.hintText
    }

    private var subjectInfoCardBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var subjectInfoCardBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var subjectInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var subjectInfoIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var subjectSecondaryText: Color {
        NColors.Onboarding.cardBodyText
    }

    private var subjectOptionBackground: Color {
        NColors.Onboarding.optionBackground
    }

    private var subjectOptionBorder: Color {
        NColors.Onboarding.optionBorder
    }

    private var subjectOptionSelectedBackground: Color {
        NColors.Onboarding.optionSelectedBackground
    }

    private var subjectOptionSelectedBorder: Color {
        NColors.Onboarding.optionSelectedBorder
    }

    private var subjectIconBadgeBackground: Color {
        NColors.Onboarding.iconBadgeBackground
    }

    private var subjectIconColor: Color {
        NColors.Onboarding.iconColor
    }

    private var subjectOptionText: Color {
        NColors.Onboarding.subjectOptionText
    }

    private var subjectSelectedText: Color {
        NColors.Onboarding.subjectSelectedText
    }

    private var deckInfoCardBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var deckInfoCardBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var deckInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var deckInfoIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var deckSecondaryText: Color {
        NColors.Onboarding.cardBodyText
    }

    private var deckInputBackground: Color {
        NColors.Onboarding.deckInputBackground
    }

    private var deckInputBorder: Color {
        NColors.Onboarding.deckInputBorder
    }

    private var deckInputActiveBorder: Color {
        NColors.Onboarding.deckInputActiveBorder
    }

    private var deckPreviewBackground: Color {
        NColors.Onboarding.deckPreviewBackground
    }

    private var deckPreviewBorder: Color {
        NColors.Onboarding.deckPreviewBorder
    }

    private var deckPreviewIconBackground: Color {
        NColors.Onboarding.deckPreviewIconBackground
    }

    private var deckPreviewIconColor: Color {
        NColors.Onboarding.deckPreviewIconColor
    }

    private var deckPreviewSkeleton: Color {
        NColors.Onboarding.deckPreviewSkeleton
    }

    private var deckSuggestionBackground: Color {
        NColors.Onboarding.deckSuggestionBackground
    }

    private var deckSuggestionBorder: Color {
        NColors.Onboarding.deckSuggestionBorder
    }

    private var deckSuggestionSelectedBorder: Color {
        NColors.Onboarding.deckSuggestionSelectedBorder
    }

    private var deckSuggestionText: Color {
        NColors.Onboarding.deckSuggestionText
    }

    private var deckSuggestionSelectedText: Color {
        NColors.Onboarding.deckSuggestionSelectedText
    }

    private var firstCardInfoBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var firstCardInfoBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var firstCardInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var firstCardInfoIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var firstCardSecondaryText: Color {
        NColors.Onboarding.infoSecondaryText
    }

    private var firstCardFrontLabel: Color {
        NColors.Onboarding.firstCardFrontLabel
    }

    private var firstCardBackLabel: Color {
        NColors.Onboarding.firstCardBackLabel
    }

    private var firstCardInputBackground: Color {
        NColors.Onboarding.firstCardInputBackground
    }

    private var firstCardInputBorder: Color {
        NColors.Onboarding.firstCardInputBorder
    }

    private var firstCardInputActiveBorder: Color {
        NColors.Onboarding.firstCardInputActiveBorder
    }

    private var firstCardTipBackground: Color {
        NColors.Onboarding.firstCardTipBackground
    }

    private var firstCardTipBorder: Color {
        NColors.Onboarding.firstCardTipBorder
    }

    private var firstCardTipIcon: Color {
        NColors.Onboarding.firstCardTipIcon
    }

    private var firstCardTipText: Color {
        NColors.Onboarding.firstCardTipText
    }

    private var accountInfoBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var accountInfoBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var accountInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var accountInfoIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var accountSecondaryText: Color {
        NColors.Onboarding.infoSecondaryText
    }

    private var accountFeatureBackground: Color {
        NColors.Onboarding.accountFeatureBackground
    }

    private var accountFeatureBorder: Color {
        NColors.Onboarding.accountFeatureBorder
    }

    private var accountFeatureIconBackground: Color {
        NColors.Onboarding.accountFeatureIconBackground
    }

    private var accountFeatureIconColor: Color {
        NColors.Onboarding.accountFeatureIconColor
    }

    private var doneInfoBackground: Color {
        NColors.Onboarding.infoBackground
    }

    private var doneInfoBorder: Color {
        NColors.Onboarding.infoBorder
    }

    private var doneInfoIconBackground: Color {
        NColors.Onboarding.infoIconBackground
    }

    private var doneInfoIconColor: Color {
        NColors.Onboarding.cardIconColor
    }

    private var doneStatBackground: Color {
        NColors.Onboarding.doneStatBackground
    }

    private var doneStatBorder: Color {
        NColors.Onboarding.doneStatBorder
    }
}

private struct OnboardingDeckTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    let isDark: Bool
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        KeyboardWarmup.prepareServicesIfNeeded()

        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.textContentType = .none
        textField.clearButtonMode = .never
        textField.adjustsFontForContentSizeCategory = true
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.text = text
        textField.placeholder = placeholder
        textField.textColor = uiTextColor
        textField.tintColor = NColors.Onboarding.textFieldTint
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
        uiView.textColor = uiTextColor

        if isFocused, uiView.isFirstResponder == false {
            uiView.becomeFirstResponder()
        } else if isFocused == false, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    private var uiTextColor: UIColor {
        NColors.Onboarding.uiTextColor
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private var parent: OnboardingDeckTextField

        init(_ parent: OnboardingDeckTextField) {
            self.parent = parent
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            parent.isFocused = false
            textField.resignFirstResponder()
            return false
        }
    }
}

private enum KeyboardWarmup {
    private static var hasPrepared = false

    static func prepareServicesIfNeeded() {
        guard hasPrepared == false else { return }
        hasPrepared = true

        _ = UITextInputMode.activeInputModes
        _ = UITextChecker()
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
