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
    @State private var isCardListVisible = false
    @State private var hasAnimatedCardsIn = false
    @State private var hasAnimatedHeaderIn = false

    var body: some View {
        VStack(spacing: NSpacing.md) {
            summaryStrip

            NGradientButton(
                AppCopy.text(locale, en: "Start Study", es: "Iniciar Estudio"),
                animateEffects: true,
                font: .system(size: 18, weight: .bold, design: .rounded),
                height: 58,
                cornerRadius: NRadius.button
            ) {
                isPresentingStudyOptions = true
            }
            .opacity(hasAnimatedHeaderIn ? 1 : 0)
            .offset(y: hasAnimatedHeaderIn ? 0 : 18)
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62).delay(0.12), value: hasAnimatedHeaderIn)
            .disabled(viewModel.cards.isEmpty)
            .padding(.horizontal, NSpacing.md)

            cardsContainer
        }
        .background(backgroundView)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: NLayout.bottomBarClearance)
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(deck.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(1)
            }

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
        .onAppear {
            reloadCards(animated: true)
        }
        .onDisappear {
            isCardListVisible = false
            hasAnimatedCardsIn = false
            hasAnimatedHeaderIn = false
        }
        .sheet(isPresented: $isPresentingCreateCard, onDismiss: {
            reloadCards(animated: true)
        }) {
            CreateCardView { frontText, backText in
                viewModel.createCard(
                    in: deck,
                    frontText: frontText,
                    backText: backText,
                    using: modelContext
                )
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
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
        .fullScreenCover(isPresented: $isPresentingStudy) {
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
            reloadCards(animated: false)
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

    private var cardsContainer: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            Text(AppCopy.text(locale, en: "Cards", es: "Tarjetas"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
                .padding(.horizontal, NSpacing.md)
                .opacity(hasAnimatedHeaderIn ? 1 : 0)
                .offset(y: hasAnimatedHeaderIn ? 0 : 18)
                .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62).delay(0.16), value: hasAnimatedHeaderIn)

            if viewModel.cards.isEmpty {
                NEmptyState(
                    systemImage: "rectangle.stack",
                    title: AppCopy.text(locale, en: "No cards yet", es: "Aun no hay tarjetas"),
                    message: AppCopy.text(locale, en: "Add cards to this deck before starting a study session.", es: "Agrega tarjetas a este mazo antes de iniciar una sesion de estudio."),
                    ctaTitle: AppCopy.text(locale, en: "Add Card", es: "Agregar Tarjeta")
                ) {
                    isPresentingCreateCard = true
                }
                .padding(.horizontal, NSpacing.md)
            } else if isCardListVisible {
                ScrollView {
                    LazyVStack(spacing: NSpacing.xs) {
                        ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                            cardRow(card, index: index)
                                .opacity(hasAnimatedCardsIn ? 1 : 0)
                                .offset(x: hasAnimatedCardsIn ? 0 : -48)
                                .animation(
                                    .timingCurve(0.16, 1, 0.3, 1, duration: 0.76)
                                        .delay(Double(index) * 0.07),
                                    value: hasAnimatedCardsIn
                                )
                            .contextMenu {
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
                    .padding(.horizontal, NSpacing.md)
                    .padding(.vertical, NSpacing.xs)
                }
                .scrollIndicators(.hidden)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: max(CGFloat(viewModel.cards.count) * 132, 160))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 350, maxHeight: 350, alignment: .top)
    }

    private func cardRow(_ card: Card, index: Int) -> some View {
        let secondaryTextColor = colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
        let cardBackground = colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt
        let cardBorder = colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(NColors.Brand.neuroBlue.opacity(colorScheme == .light ? 0.12 : 0.18))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text("\(index + 1)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Brand.neuroBlue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppCopy.text(locale, en: "Front", es: "Frente"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)

                    Text(card.frontText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Rectangle()
                .fill(cardBorder)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppCopy.text(locale, en: "Back", es: "Reverso"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryTextColor)

                Text(card.backText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(
            color: colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.24),
            radius: colorScheme == .light ? 16 : 20,
            x: 0,
            y: 8
        )
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
        .padding(.bottom, NSpacing.xs)
        .opacity(hasAnimatedHeaderIn ? 1 : 0)
        .offset(y: hasAnimatedHeaderIn ? 0 : 18)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.62).delay(0.04), value: hasAnimatedHeaderIn)
    }

    private func reloadCards(animated: Bool) {
        viewModel.load(deck: deck, using: modelContext)

        guard animated else {
            isCardListVisible = true
            hasAnimatedHeaderIn = true
            hasAnimatedCardsIn = true
            return
        }

        triggerDetailEntranceAnimation()
    }

    private func triggerDetailEntranceAnimation() {
        isCardListVisible = false
        hasAnimatedCardsIn = false
        hasAnimatedHeaderIn = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(70))
            hasAnimatedHeaderIn = true
            try? await Task.sleep(for: .milliseconds(140))
            isCardListVisible = true
            try? await Task.sleep(for: .milliseconds(60))
            hasAnimatedCardsIn = true
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
