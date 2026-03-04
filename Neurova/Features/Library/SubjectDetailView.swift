import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let subject: Subject

    @State private var viewModel = SubjectDetailViewModel()
    @State private var isPresentingCreateDeck = false
    @State private var editingDeck: Deck?

    var body: some View {
        ScrollView {
            Group {
                if viewModel.decks.isEmpty {
                    NEmptyState(
                        systemImage: "square.stack.3d.up",
                        title: "No decks yet",
                        message: "Create a deck inside this subject to start building cards.",
                        ctaTitle: "Create Deck"
                    ) {
                        isPresentingCreateDeck = true
                    }
                } else {
                    LazyVStack(spacing: NSpacing.md) {
                        ForEach(viewModel.decks, id: \.id) { deck in
                            NavigationLink {
                                DeckDetailView(deck: deck)
                            } label: {
                                deckCard(deck)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") {
                                    editingDeck = deck
                                }

                                Button("Archive") {
                                    viewModel.archiveDeck(
                                        deck,
                                        subject: subject,
                                        using: modelContext
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, NSpacing.md)
            .padding(.vertical, NSpacing.md)
        }
        .background(backgroundView.ignoresSafeArea())
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .task {
            viewModel.load(subject: subject, using: modelContext)
        }
        .sheet(isPresented: $isPresentingCreateDeck) {
            CreateDeckView { title, description, isArchived in
                viewModel.createDeck(
                    in: subject,
                    title: title,
                    description: description,
                    using: modelContext
                )

                if isArchived, let latestDeck = viewModel.decks.last {
                    viewModel.updateDeck(
                        latestDeck,
                        title: latestDeck.title,
                        description: latestDeck.description,
                        isArchived: true,
                        subject: subject,
                        using: modelContext
                    )
                }
            }
        }
        .sheet(item: $editingDeck, onDismiss: {
            viewModel.load(subject: subject, using: modelContext)
        }) { deck in
            CreateDeckView(deck: deck) { title, description, isArchived in
                viewModel.updateDeck(
                    deck,
                    title: title,
                    description: description,
                    isArchived: isArchived,
                    subject: subject,
                    using: modelContext
                )
            }
        }
    }

    private func deckCard(_ deck: Deck) -> some View {
        let metrics = viewModel.metrics(for: deck)

        return NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(deck.title)
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .multilineTextAlignment(.leading)

                if let description = deck.description {
                    Text(description)
                        .font(NTypography.caption)
                        .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: NSpacing.sm) {
                    NChip(metrics.cardCount == 1 ? "1 card" : "\(metrics.cardCount) cards", isSelected: false)
                    NChip(metrics.dueCount == 1 ? "1 due" : "\(metrics.dueCount) due", isSelected: false)
                }
            }
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
