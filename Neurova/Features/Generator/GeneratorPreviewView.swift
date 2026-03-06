import SwiftData
import SwiftUI

struct GeneratorPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
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

    init(cleanedText: String, onFlashcardsSaved: @escaping (String) -> Void = { _ in }) {
        self.cleanedText = cleanedText
        self.onFlashcardsSaved = onFlashcardsSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: NSpacing.md) {
                pickerTabs
                contentArea
                actionButton
            }
            .padding(.horizontal, NSpacing.md)
            .padding(.top, NSpacing.sm)
            .padding(.bottom, NSpacing.md)
            .background(NColors.Neutrals.background.ignoresSafeArea())
            .navigationTitle(AppCopy.text(locale, en: "Generator", es: "Generador"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppCopy.text(locale, en: "Close", es: "Cerrar")) {
                        dismiss()
                    }
                }
            }
            .task {
                runGenerationIfNeeded()
                loadTargets()
            }
        }
    }

    private var pickerTabs: some View {
        Picker("", selection: $selectedTab) {
            ForEach(GeneratorTab.allCases, id: \.self) { tab in
                Text(tab.title(for: locale))
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
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
        ScrollView {
            VStack(spacing: NSpacing.sm) {
                NCard {
                    VStack(alignment: .leading, spacing: NSpacing.sm) {
                        Text(AppCopy.text(locale, en: "Save destination", es: "Destino de guardado"))
                            .font(NTypography.bodyEmphasis.weight(.semibold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        if subjects.isEmpty {
                            createSubjectInlineView
                        } else {
                            subjectPickerView
                        }

                        if selectedSubject != nil {
                            if decks.isEmpty {
                                createDeckInlineView(
                                    title: AppCopy.text(locale, en: "No decks in this subject. Create one:", es: "No hay decks en esta materia. Crea uno:")
                                )
                            } else {
                                deckPickerView
                                createDeckInlineView(
                                    title: AppCopy.text(locale, en: "Or create a new deck:", es: "O crea un nuevo deck:")
                                )
                            }
                        }

                        if let selectedDeck {
                            Text(
                                AppCopy.text(
                                    locale,
                                    en: "Selected: \(selectedDeck.title)",
                                    es: "Seleccionado: \(selectedDeck.title)"
                                )
                            )
                            .font(NTypography.caption)
                            .foregroundStyle(NColors.Brand.neuroBlue)
                        }

                        if let bannerMessage {
                            Text(bannerMessage)
                                .font(NTypography.caption)
                                .foregroundStyle(NColors.Text.textSecondary)
                        }
                    }
                }
            }
            .padding(.bottom, NSpacing.sm)
        }
    }

    private var subjectPickerView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Subject", es: "Materia"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            Picker(
                "",
                selection: Binding(
                    get: { selectedSubjectID ?? subjects.first?.id ?? UUID() },
                    set: { newValue in
                        selectedSubjectID = newValue
                        loadDecksForSelectedSubject()
                    }
                )
            ) {
                ForEach(subjects, id: \.id) { subject in
                    Text(subject.name).tag(subject.id)
                }
            }
            .pickerStyle(.menu)

            createSubjectInlineView
        }
    }

    private var deckPickerView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Deck", es: "Deck"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            Picker(
                "",
                selection: Binding(
                    get: { selectedDeckID ?? decks.first?.id ?? UUID() },
                    set: { selectedDeckID = $0 }
                )
            ) {
                ForEach(decks, id: \.id) { deck in
                    Text(deck.title).tag(deck.id)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var createSubjectInlineView: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Create subject", es: "Crear materia"))
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)

            TextField(
                AppCopy.text(locale, en: "Subject name", es: "Nombre de la materia"),
                text: $newSubjectName
            )
            .font(NTypography.body)
            .padding(.horizontal, NSpacing.sm)
            .frame(height: 40)
            .background(NColors.Neutrals.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )

            NSecondaryButton(AppCopy.text(locale, en: "Create subject", es: "Crear materia")) {
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

            TextField(
                AppCopy.text(locale, en: "Deck title", es: "Título del deck"),
                text: $newDeckTitle
            )
            .font(NTypography.body)
            .padding(.horizontal, NSpacing.sm)
            .frame(height: 40)
            .background(NColors.Neutrals.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )

            NSecondaryButton(AppCopy.text(locale, en: "Create deck", es: "Crear deck")) {
                createDeckQuickly()
            }
            .disabled(newDeckTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSubject == nil)
        }
    }

    private var flashcardsView: some View {
        ScrollView {
            VStack(spacing: NSpacing.sm) {
                if drafts.isEmpty {
                    emptyMessage(AppCopy.text(locale, en: "No card drafts generated.", es: "No se generaron tarjetas."))
                } else {
                    ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                        NCard {
                            VStack(alignment: .leading, spacing: NSpacing.xs) {
                                Text("\(AppCopy.text(locale, en: "Card", es: "Tarjeta")) \(index + 1)")
                                    .font(NTypography.caption.weight(.semibold))
                                    .foregroundStyle(NColors.Text.textSecondary)

                                TextField(
                                    AppCopy.text(locale, en: "Front", es: "Frente"),
                                    text: Binding(
                                        get: { draft.front },
                                        set: { drafts[index].front = $0 }
                                    )
                                )
                                .font(NTypography.bodyEmphasis)

                                TextField(
                                    AppCopy.text(locale, en: "Back", es: "Reverso"),
                                    text: Binding(
                                        get: { draft.back },
                                        set: { drafts[index].back = $0 }
                                    ),
                                    axis: .vertical
                                )
                                .font(NTypography.body)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, NSpacing.sm)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch selectedTab {
        case .location:
            NPrimaryButton(AppCopy.text(locale, en: "Continue to Flashcards", es: "Continuar a Flashcards")) {
                guard selectedDeck != nil else {
                    bannerMessage = AppCopy.text(locale, en: "Choose a deck first.", es: "Primero elige un deck.")
                    return
                }
                selectedTab = .flashcards
            }
        case .flashcards:
            NPrimaryButton(
                isSaving
                    ? AppCopy.text(locale, en: "Saving...", es: "Guardando...")
                    : AppCopy.text(locale, en: "Save Flashcards to Deck", es: "Guardar flashcards en deck")
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
        NCard {
            Text(text)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
