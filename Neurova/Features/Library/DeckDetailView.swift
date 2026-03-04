import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let deck: Deck

    @State private var viewModel = DeckDetailViewModel()
    @State private var isPresentingCreateCard = false
    @State private var isPresentingStudyOptions = false
    @State private var isPresentingStudy = false
    @State private var selectedStudyCards: [Card] = []
    @State private var shouldPresentStudyAfterSheetDismiss = false
    @State private var noCardsAlertMessage: String?

    var body: some View {
        List {
            Section {
                summaryStrip
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                if viewModel.cards.isEmpty {
                    NEmptyState(
                        systemImage: "rectangle.stack",
                        title: AppCopy.text(locale, en: "No cards yet", es: "Aun no hay tarjetas"),
                        message: AppCopy.text(locale, en: "Add cards to this deck before starting a study session.", es: "Agrega tarjetas a este mazo antes de iniciar una sesion de estudio."),
                        ctaTitle: AppCopy.text(locale, en: "Add Card", es: "Agregar Tarjeta")
                    ) {
                        isPresentingCreateCard = true
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.offset) { index, card in
                        NCard {
                            VStack(alignment: .leading, spacing: NSpacing.xs) {
                                Text(card.frontText)
                                    .font(NTypography.bodyEmphasis.weight(.semibold))
                                    .foregroundStyle(NColors.Text.textPrimary)
                                    .multilineTextAlignment(.leading)

                                Text(card.backText)
                                    .font(NTypography.caption)
                                    .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .listRowInsets(EdgeInsets(top: NSpacing.xs, leading: NSpacing.md, bottom: NSpacing.xs, trailing: NSpacing.md))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteCard(
                                    at: index,
                                    in: deck,
                                    using: modelContext
                                )
                            } label: {
                                Label(AppCopy.text(locale, en: "Delete", es: "Eliminar"), systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text(AppCopy.text(locale, en: "Cards", es: "Tarjetas"))
                    .font(NTypography.caption.weight(.semibold))
                    .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
            }

            Section {
                NPrimaryButton(AppCopy.text(locale, en: "Start Study", es: "Iniciar Estudio")) {
                    isPresentingStudyOptions = true
                }
                .disabled(viewModel.cards.isEmpty)
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(backgroundView)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: NLayout.bottomBarClearance)
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateCard = true
                } label: {
                    Image(systemName: "plus")
                        .font(NTypography.bodyEmphasis)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }
            }
        }
        .task {
            viewModel.load(deck: deck, using: modelContext)
        }
        .sheet(isPresented: $isPresentingCreateCard) {
            CreateCardView { frontText, backText in
                viewModel.createCard(
                    in: deck,
                    frontText: frontText,
                    backText: backText,
                    using: modelContext
                )
            }
        }
        .sheet(isPresented: $isPresentingStudyOptions) {
            StudyOptionsSheetView(
                counts: [
                    .due: viewModel.count(for: .due),
                    .new: viewModel.count(for: .new),
                    .review: viewModel.count(for: .review),
                    .all: viewModel.count(for: .all)
                ],
                onSelect: { filter in
                    let filteredCards = viewModel.filteredCards(for: filter)
                    guard filteredCards.isEmpty == false else {
                        noCardsAlertMessage = AppCopy.text(locale, en: "No cards available for this mode.", es: "No hay tarjetas disponibles para este modo.")
                        isPresentingStudyOptions = false
                        return
                    }

                    selectedStudyCards = filteredCards
                    shouldPresentStudyAfterSheetDismiss = true
                    isPresentingStudyOptions = false
                }
            )
            .presentationDetents([.fraction(0.48), .medium])
        }
        .onChange(of: isPresentingStudyOptions) { _, isPresented in
            guard isPresented == false, shouldPresentStudyAfterSheetDismiss else { return }
            shouldPresentStudyAfterSheetDismiss = false
            isPresentingStudy = true
        }
        .sheet(isPresented: $isPresentingStudy) {
            NavigationStack {
                StudyView(
                    deckTitle: deck.title,
                    cards: selectedStudyCards,
                    frontText: { $0.frontText },
                    backText: { $0.backText }
                )
            }
        }
        .onChange(of: isPresentingStudy) { _, isPresented in
            guard isPresented == false else { return }
            viewModel.load(deck: deck, using: modelContext)
        }
        .alert(
            AppCopy.text(locale, en: "Study Unavailable", es: "Estudio no disponible"),
            isPresented: Binding(
                get: { noCardsAlertMessage != nil },
                set: { isPresented in
                    if isPresented == false {
                        noCardsAlertMessage = nil
                    }
                }
            )
        ) {
            Button(AppCopy.text(locale, en: "OK", es: "OK"), role: .cancel) {}
        } message: {
            Text(noCardsAlertMessage ?? "")
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: NSpacing.sm) {
            NStatCard(
                systemImage: "rectangle.stack",
                iconColor: NColors.Brand.neuroBlue,
                value: "\(viewModel.totalCards)",
                label: AppCopy.text(locale, en: "Total", es: "Total")
            )

            NStatCard(
                systemImage: "calendar",
                iconColor: NColors.Feedback.warning,
                value: "\(viewModel.dueTodayCount)",
                label: AppCopy.text(locale, en: "Ready", es: "Listo")
            )

            NStatCard(
                systemImage: "sparkles",
                iconColor: NColors.Brand.neuralMint,
                value: "\(viewModel.newCardsCount)",
                label: AppCopy.text(locale, en: "New", es: "Nuevo")
            )
        }
        .padding(.horizontal, NSpacing.md)
        .padding(.top, NSpacing.md)
        .padding(.bottom, NSpacing.sm)
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview("Deck Detail Light") {
    NavigationStack {
        let subject = Subject(name: "Biology")
        let deck = Deck(subject: subject, title: "Cells")
        DeckDetailView(deck: deck)
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.light)
}

#Preview("Deck Detail Dark") {
    NavigationStack {
        let subject = Subject(name: "Biology")
        let deck = Deck(subject: subject, title: "Cells")
        DeckDetailView(deck: deck)
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.dark)
}
