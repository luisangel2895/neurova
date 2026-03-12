import SwiftData
import SwiftUI
import UIKit

struct GeneratorPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    private let cleanedText: String
    private let onFlashcardsSaved: (String) -> Void
    private let generator = HeuristicStudyGenerator()

    @State private var selectedTab: GeneratorTab = .location
    @State private var drafts: [CardDraft] = []

    @State private var subjects: [Subject] = []
    @State private var decks: [Deck] = []
    @State private var selectedSubjectID: UUID?
    @State private var selectedDeckID: UUID?

    @State private var newSubjectName = ""
    @State private var newDeckTitle = ""

    @State private var isSaving = false
    @State private var bannerMessage: String?
    @State private var hasSavedFlashcards = false
    @State private var showHero = false
    @State private var showContent = false
    @State private var visibleDraftCount = 0

    init(cleanedText: String, onFlashcardsSaved: @escaping (String) -> Void = { _ in }) {
        self.cleanedText = cleanedText
        self.onFlashcardsSaved = onFlashcardsSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                heroSection
                pickerTabs
                actionButton
                contentArea
            }
            .padding(.horizontal, NSpacing.md + 2)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(backgroundView.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppCopy.text(locale, en: "Generator", es: "Generador"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(NColors.Text.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(colorScheme == .light ? Color.white.opacity(0.92) : NColors.Neutrals.surfaceAlt)
                            )
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .task {
                runGenerationIfNeeded()
                loadTargets()
                startEntryAnimation()
            }
        }
    }

    private var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(heroGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(heroBorder, lineWidth: 1)
                }

            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.14 : 0.18))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: selectedTab == .location ? "sparkles.rectangle.stack.fill" : "rectangle.stack.badge.person.crop.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(NColors.Brand.neuroBlue)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(AppCopy.text(locale, en: "DRAFT READY", es: "BORRADOR LISTO"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(NColors.Text.textTertiary)

                        Spacer(minLength: 0)

                        selectionBadge(
                            AppCopy.text(
                                locale,
                                en: "\(drafts.count) cards",
                                es: "\(drafts.count) tarjetas"
                            )
                        )
                        .offset(y: -3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(
                        selectedTab == .location
                            ? AppCopy.text(locale, en: "Choose where these flashcards should live", es: "Elige dónde vivirán estas flashcards")
                            : AppCopy.text(locale, en: "Review every card before saving", es: "Revisa cada tarjeta antes de guardar")
                    )
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .frame(height: 100)
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.06) : Color.black.opacity(0.28), radius: 24, x: 0, y: 14)
        .opacity(showHero ? 1 : 0)
        .offset(y: showHero ? 0 : 24)
        .scaleEffect(showHero ? 1 : 0.98)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62), value: showHero)
    }

    private var pickerTabs: some View {
        Picker("", selection: $selectedTab) {
            ForEach(GeneratorTab.allCases, id: \.self) { tab in
                Text(tab.title(for: locale))
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .light ? Color.white.opacity(0.82) : NColors.Neutrals.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: selectedTab) { _, newValue in
            guard newValue == .flashcards, selectedDeck == nil else { return }
            selectedTab = .location
            bannerMessage = AppCopy.text(locale, en: "Select where to save first.", es: "Selecciona primero dónde guardar.")
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        switch selectedTab {
        case .location:
            locationTabView
        case .flashcards:
            flashcardsView
        }
    }

    private var locationTabView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                premiumCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(
                            icon: "shippingbox.fill",
                            title: AppCopy.text(locale, en: "Save destination", es: "Destino de guardado"),
                            subtitle: AppCopy.text(locale, en: "Place these flashcards in the right subject and deck.", es: "Coloca estas flashcards en la materia y deck correctos.")
                        )

                        if subjects.isEmpty {
                            createSubjectInlineView
                        } else {
                            subjectPickerView
                        }

                        if selectedSubject != nil {
                            if decks.isEmpty {
                                createDeckInlineView(
                                    title: AppCopy.text(locale, en: "No decks here yet. Create the first one.", es: "Aún no hay decks aquí. Crea el primero.")
                                )
                            } else {
                                deckPickerView
                                createDeckInlineView(
                                    title: AppCopy.text(locale, en: "Want a fresh deck for this import?", es: "¿Quieres un deck nuevo para esta importación?")
                                )
                            }
                        }

                        if let selectedDeck {
                            selectionBadge(
                                AppCopy.text(locale, en: "Saving into \(selectedDeck.title)", es: "Se guardará en \(selectedDeck.title)")
                            )
                        }

                        if let bannerMessage {
                            helperMessage(bannerMessage)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 16)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62).delay(0.06), value: showContent)
    }

    private var subjectPickerView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Subject", es: "Materia"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            Menu {
                ForEach(subjects, id: \.id) { subject in
                    Button(subject.name) {
                        selectedSubjectID = subject.id
                        loadDecksForSelectedSubject()
                    }
                }
            } label: {
                selectorLabel(
                    title: selectedSubject?.name ?? AppCopy.text(locale, en: "Choose subject", es: "Elige materia"),
                    icon: "book.closed.fill"
                )
            }

            createSubjectInlineView
        }
    }

    private var deckPickerView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Deck", es: "Deck"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            Menu {
                ForEach(decks, id: \.id) { deck in
                    Button(deck.title) {
                        selectedDeckID = deck.id
                    }
                }
            } label: {
                selectorLabel(
                    title: selectedDeck?.title ?? AppCopy.text(locale, en: "Choose deck", es: "Elige deck"),
                    icon: "square.stack.3d.up.fill"
                )
            }
        }
    }

    private var createSubjectInlineView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Create subject", es: "Crear materia"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            NOptimizedInputField(
                placeholder: AppCopy.text(locale, en: "Subject name", es: "Nombre de la materia"),
                text: $newSubjectName,
                returnKeyType: .done,
                autocapitalization: .words,
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: UIColor(NColors.Text.textPrimary),
                tintColor: UIColor(NColors.Brand.neuroBlue)
            )
            .font(NTypography.body)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 46)
            .background(NColors.Neutrals.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )

            NSecondaryButton(AppCopy.text(locale, en: "Add subject", es: "Agregar materia")) {
                createSubjectQuickly()
            }
            .disabled(newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func createDeckInlineView(title: String) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(title)
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            NOptimizedInputField(
                placeholder: AppCopy.text(locale, en: "Deck title", es: "Título del deck"),
                text: $newDeckTitle,
                returnKeyType: .done,
                autocapitalization: .sentences,
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: UIColor(NColors.Text.textPrimary),
                tintColor: UIColor(NColors.Brand.neuroBlue)
            )
            .font(NTypography.body)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 46)
            .background(NColors.Neutrals.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )

            NSecondaryButton(AppCopy.text(locale, en: "Add deck", es: "Agregar deck")) {
                createDeckQuickly()
            }
            .disabled(newDeckTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSubject == nil)
        }
    }

    private var flashcardsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                if drafts.isEmpty {
                    emptyMessage(AppCopy.text(locale, en: "No card drafts generated.", es: "No se generaron tarjetas."))
                } else {
                    ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                        if index < visibleDraftCount {
                            premiumCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text("\(AppCopy.text(locale, en: "Card", es: "Tarjeta")) \(index + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(NColors.Text.textTertiary)

                                        Spacer()

                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(NColors.Brand.neuroBlue)
                                    }

                                    labeledInput(
                                        title: AppCopy.text(locale, en: "Front", es: "Frente"),
                                        text: Binding(
                                            get: { draft.front },
                                            set: { drafts[index].front = $0 }
                                        )
                                    )

                                    labeledInput(
                                        title: AppCopy.text(locale, en: "Back", es: "Reverso"),
                                        text: Binding(
                                            get: { draft.back },
                                            set: { drafts[index].back = $0 }
                                        )
                                    )
                                }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 16)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62).delay(0.06), value: showContent)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch selectedTab {
        case .location:
            NGradientButton(
                AppCopy.text(locale, en: "Review Flashcards", es: "Revisar flashcards"),
                showsChevron: true,
                font: .system(size: 18, weight: .semibold, design: .rounded),
                height: 58,
                cornerRadius: 18
            ) {
                guard selectedDeck != nil else {
                    bannerMessage = AppCopy.text(locale, en: "Choose a deck first.", es: "Primero elige un deck.")
                    return
                }
                selectedTab = .flashcards
            }
        case .flashcards:
            NGradientButton(
                isSaving
                    ? AppCopy.text(locale, en: "Saving...", es: "Guardando...")
                    : AppCopy.text(locale, en: "Save to Deck", es: "Guardar en deck"),
                leadingSymbolName: "tray.and.arrow.down.fill",
                font: .system(size: 18, weight: .semibold, design: .rounded),
                height: 58,
                cornerRadius: 18
            ) {
                saveFlashcards()
            }
            .disabled(canSaveFlashcards == false || isSaving || hasSavedFlashcards)
        }
    }

    private var canSaveFlashcards: Bool {
        selectedDeck != nil && drafts.contains { draft in
            draft.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
                draft.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    private var selectedDeck: Deck? {
        guard let selectedDeckID else { return decks.first }
        return decks.first(where: { $0.id == selectedDeckID })
    }

    private var selectedSubject: Subject? {
        guard let selectedSubjectID else { return subjects.first }
        return subjects.first(where: { $0.id == selectedSubjectID })
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
    }

    private func runGenerationIfNeeded() {
        guard drafts.isEmpty else { return }
        let output = generator.generate(from: cleanedText, language: selectedLanguage)
        drafts = output.flashcards
    }

    private func loadTargets() {
        let subjectRepository = SwiftDataSubjectRepository(context: modelContext)
        do {
            subjects = try subjectRepository.listSubjects()
            if selectedSubjectID == nil {
                selectedSubjectID = subjects.first?.id
            }
            loadDecksForSelectedSubject()
        } catch {
            bannerMessage = AppCopy.text(locale, en: "Could not load save targets.", es: "No se pudieron cargar destinos.")
        }
    }

    private func loadDecksForSelectedSubject() {
        guard let selectedSubject else {
            decks = []
            selectedDeckID = nil
            return
        }

        let deckRepository = SwiftDataDeckRepository(context: modelContext)
        do {
            decks = try deckRepository.decks(for: selectedSubject)
            if selectedDeckID == nil || decks.contains(where: { $0.id == selectedDeckID }) == false {
                selectedDeckID = decks.first?.id
            }
        } catch {
            decks = []
            selectedDeckID = nil
            bannerMessage = AppCopy.text(locale, en: "Could not load decks.", es: "No se pudieron cargar decks.")
        }
    }

    private func createSubjectQuickly() {
        let normalized = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else { return }

        let subjectRepository = SwiftDataSubjectRepository(context: modelContext)
        do {
            let created = try subjectRepository.createSubject(name: normalized, systemImageName: "book", colorTokenReference: nil)
            subjects.append(created)
            selectedSubjectID = created.id
            newSubjectName = ""
            bannerMessage = AppCopy.text(locale, en: "Subject created.", es: "Materia creada.")
            loadDecksForSelectedSubject()
        } catch {
            bannerMessage = AppCopy.text(locale, en: "Could not create subject.", es: "No se pudo crear la materia.")
        }
    }

    private func createDeckQuickly() {
        guard let selectedSubject else { return }
        let normalized = newDeckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else { return }

        let deckRepository = SwiftDataDeckRepository(context: modelContext)
        do {
            let created = try deckRepository.createDeck(in: selectedSubject, title: normalized, description: nil)
            decks.append(created)
            selectedDeckID = created.id
            newDeckTitle = ""
            bannerMessage = AppCopy.text(locale, en: "Deck created.", es: "Deck creado.")
        } catch {
            bannerMessage = AppCopy.text(locale, en: "Could not create deck.", es: "No se pudo crear el deck.")
        }
    }

    private func saveFlashcards() {
        guard let selectedDeck else { return }
        guard isSaving == false else { return }
        isSaving = true

        let cardRepository = SwiftDataCardRepository(context: modelContext)
        do {
            let existing = Set((try cardRepository.cards(for: selectedDeck)).map {
                "\($0.frontText.lowercased())|\($0.backText.lowercased())"
            })

            var insertedCount = 0
            var seen = existing
            for draft in drafts {
                let front = draft.front.trimmingCharacters(in: .whitespacesAndNewlines)
                let back = draft.back.trimmingCharacters(in: .whitespacesAndNewlines)
                guard front.isEmpty == false, back.isEmpty == false else { continue }

                let key = "\(front.lowercased())|\(back.lowercased())"
                guard seen.contains(key) == false else { continue }
                _ = try cardRepository.createCard(in: selectedDeck, frontText: front, backText: back, createdAt: .now)
                insertedCount += 1
                seen.insert(key)
            }

            hasSavedFlashcards = true
            let subjectName = selectedSubject?.name ?? AppCopy.text(locale, en: "Unknown subject", es: "Materia desconocida")
            let successMessage = AppCopy.text(
                locale,
                en: "Created \(insertedCount) flashcards in \(subjectName) / \(selectedDeck.title).",
                es: "Se crearon \(insertedCount) flashcards en \(subjectName) / \(selectedDeck.title)."
            )
            bannerMessage = successMessage
            onFlashcardsSaved(successMessage)
            dismiss()
        } catch {
            bannerMessage = AppCopy.text(locale, en: "Could not save flashcards.", es: "No se pudieron guardar las flashcards.")
        }

        isSaving = false
    }

    private func emptyMessage(_ text: String) -> some View {
        premiumCard {
            Text(text)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color.white.opacity(0.92), NColors.Brand.neuroBlue.opacity(0.08), NColors.Brand.neuralMint.opacity(0.08)]
                : [NColors.Neutrals.surfaceAlt, NColors.Brand.neuroBlue.opacity(0.16), NColors.Brand.neuralMint.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroBorder: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }

    private func premiumCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.22),
                radius: colorScheme == .light ? 16 : 20,
                x: 0,
                y: 8
            )
    }

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.12 : 0.18))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
            }
        }
    }

    private func selectorLabel(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NColors.Brand.neuroBlue)

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(NColors.Text.textTertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(NColors.Neutrals.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NColors.Neutrals.border, lineWidth: 1)
        )
    }

    private func selectionBadge(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(NColors.Brand.neuroBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.10 : 0.16))
            .clipShape(Capsule())
    }

    private func helperMessage(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledInput(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textTertiary)

            NOptimizedInputField(
                placeholder: title,
                text: text,
                returnKeyType: .done,
                autocapitalization: .sentences,
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: UIColor(NColors.Text.textPrimary),
                tintColor: UIColor(NColors.Brand.neuroBlue)
            )
            .font(NTypography.body)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 46)
            .background(NColors.Neutrals.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )
        }
    }

    private func startEntryAnimation() {
        showHero = false
        showContent = false
        visibleDraftCount = 0

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            showHero = true
            try? await Task.sleep(for: .milliseconds(70))
            showContent = true
            if drafts.isEmpty == false {
                for count in 1...drafts.count {
                    visibleDraftCount = count
                    try? await Task.sleep(for: .milliseconds(70))
                }
            }
        }
    }
}

private enum GeneratorTab: CaseIterable {
    case location
    case flashcards

    func title(for locale: Locale) -> String {
        switch self {
        case .location:
            return AppCopy.text(locale, en: "Location", es: "Ubicación")
        case .flashcards:
            return AppCopy.text(locale, en: "Flashcards", es: "Flashcards")
        }
    }
}

#Preview {
    GeneratorPreviewView(
        cleanedText: """
        CELL BIOLOGY:
        Cell membrane: Protects cell structure.
        Nucleus: Stores genetic material.
        """
    )
    .modelContainer(
        for: [
            Subject.self,
            Deck.self,
            Card.self,
            XPEventEntity.self,
            XPStatsEntity.self,
            UserPreferences.self,
            ScanEntity.self
        ],
        inMemory: true
    )
}
