import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let subject: Subject

    @State private var viewModel = SubjectDetailViewModel()
    @State private var isPresentingCreateDeck = false
    @State private var editingDeck: Deck?
    @State private var isDeckListVisible = false
    @State private var hasAnimatedDecksIn = false

    var body: some View {
        ScrollView {
            Group {
                if viewModel.decks.isEmpty {
                    NEmptyState(
                        systemImage: "square.stack.3d.up",
                        title: AppCopy.text(locale, en: "No decks yet", es: "Aun no hay mazos"),
                        message: AppCopy.text(locale, en: "Create a deck inside this subject to start building cards.", es: "Crea un mazo dentro de esta materia para empezar a crear tarjetas."),
                        ctaTitle: AppCopy.text(locale, en: "Create Deck", es: "Crear Mazo")
                    ) {
                        isPresentingCreateDeck = true
                    }
                } else if isDeckListVisible {
                    LazyVStack(spacing: NSpacing.md) {
                        ForEach(Array(viewModel.decks.enumerated()), id: \.element.id) { index, deck in
                            NavigationLink {
                                DeckDetailView(deck: deck)
                            } label: {
                                deckCard(deck)
                            }
                            .buttonStyle(.plain)
                            .opacity(hasAnimatedDecksIn ? 1 : 0)
                            .offset(x: hasAnimatedDecksIn ? 0 : -52)
                            .animation(
                                .timingCurve(0.16, 1, 0.3, 1, duration: 0.62)
                                    .delay(Double(index) * 0.11),
                                value: hasAnimatedDecksIn
                            )
                            .contextMenu {
                                Button {
                                    editingDeck = deck
                                } label: {
                                    Label(
                                        AppCopy.text(locale, en: "Edit", es: "Editar"),
                                        systemImage: "pencil"
                                    )
                                }

                                Divider()

                                Button(role: .destructive) {
                                    viewModel.deleteDeck(
                                        deck,
                                        subject: subject,
                                        using: modelContext
                                    )
                                } label: {
                                    Label(
                                        AppCopy.text(locale, en: "Delete", es: "Eliminar"),
                                        systemImage: "trash"
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: max(CGFloat(viewModel.decks.count) * 132, 160))
                }
            }
            .padding(.horizontal, NSpacing.md)
            .padding(.vertical, NSpacing.md)
        }
        .scrollIndicators(.hidden)
        .background(backgroundView.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(subject.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateDeck = true
                } label: {
                    Image(systemName: "plus")
                        .font(NTypography.bodyEmphasis)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }
            }
        }
        .onAppear {
            reloadDecks(animated: true)
        }
        .onDisappear {
            isDeckListVisible = false
            hasAnimatedDecksIn = false
        }
        .sheet(isPresented: $isPresentingCreateDeck, onDismiss: {
            reloadDecks(animated: true)
        }) {
            CreateDeckView { title, description in
                viewModel.createDeck(
                    in: subject,
                    title: title,
                    description: description,
                    using: modelContext
                )
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingDeck, onDismiss: {
            reloadDecks(animated: true)
        }) { deck in
            CreateDeckView(deck: deck) { title, description in
                viewModel.updateDeck(
                    deck,
                    title: title,
                    description: description,
                    isArchived: deck.isArchived,
                    subject: subject,
                    using: modelContext
                )
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }

    private func deckCard(_ deck: Deck) -> some View {
        let metrics = viewModel.metrics(for: deck)
        let subjectAccentColor = NColors.SubjectIcon.color(for: subject.colorTokenReference)
        let secondaryTextColor = colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
        let cardBackground = colorScheme == .light ? NColors.Neutrals.surface : NColors.Neutrals.surfaceAlt
        let cardBorder = colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.08)
        let accentBackground = subjectAccentColor.opacity(colorScheme == .light ? 0.12 : 0.18)

        return VStack(alignment: .leading, spacing: NSpacing.sm) {
            HStack(alignment: .top, spacing: NSpacing.sm) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentBackground)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(subjectAccentColor)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(
                        deck.description?.isEmpty == false
                            ? deck.description!
                            : AppCopy.text(locale, en: "No description yet", es: "Aun sin descripcion")
                    )
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(secondaryTextColor.opacity(0.8))
                    .padding(.top, 4)
            }

            HStack(spacing: 10) {
                deckMetricPill(
                    icon: "square.on.square",
                    value: "\(metrics.cardCount)",
                    label: AppCopy.text(locale, en: "Cards", es: "Tarjetas"),
                    tint: NColors.Brand.neuroBlue
                )

                deckMetricPill(
                    icon: "bolt.fill",
                    value: "\(metrics.dueCount)",
                    label: AppCopy.text(locale, en: "Ready", es: "Listas"),
                    tint: subjectAccentColor
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            radius: colorScheme == .light ? 18 : 22,
            x: 0,
            y: 10
        )
    }

    private func deckMetricPill(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(NColors.Neutrals.surfaceAlt)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(colorScheme == .light ? 0.18 : 0.24), lineWidth: 1)
        }
    }

    private func triggerDeckEntranceAnimation() {
        isDeckListVisible = false
        hasAnimatedDecksIn = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(110))
            isDeckListVisible = true
            try? await Task.sleep(for: .milliseconds(40))
            hasAnimatedDecksIn = true
        }
    }

    private func reloadDecks(animated: Bool) {
        viewModel.load(subject: subject, using: modelContext)

        guard animated else {
            isDeckListVisible = true
            hasAnimatedDecksIn = true
            return
        }

        triggerDeckEntranceAnimation()
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
}

#Preview("Subject Detail Light") {
    NavigationStack {
        SubjectDetailView(subject: Subject(name: "Biology", systemImageName: "leaf"))
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.light)
}

#Preview("Subject Detail Dark") {
    NavigationStack {
        SubjectDetailView(subject: Subject(name: "Biology", systemImageName: "leaf"))
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.dark)
}
