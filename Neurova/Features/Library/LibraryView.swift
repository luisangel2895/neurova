import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @State private var viewModel = LibraryViewModel()
    @State private var isPresentingCreateSubject = false
    @State private var editingSubject: Subject?

    private let columns = [
        GridItem(.flexible(), spacing: NSpacing.md),
        GridItem(.flexible(), spacing: NSpacing.md)
    ]

    var body: some View {
        ScrollView {
            Group {
                if viewModel.subjects.isEmpty {
                    NEmptyState(
                        systemImage: "books.vertical",
                        title: AppCopy.text(locale, en: "No subjects yet", es: "Aun no hay materias"),
                        message: AppCopy.text(locale, en: "Create your first subject to start organizing decks offline.", es: "Crea tu primera materia para empezar a organizar mazos offline."),
                        ctaTitle: AppCopy.text(locale, en: "Create Subject", es: "Crear Materia")
                    ) {
                        isPresentingCreateSubject = true
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: NSpacing.md) {
                        ForEach(viewModel.subjects, id: \.id) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject)
                            } label: {
                                subjectCard(subject)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(AppCopy.text(locale, en: "Edit", es: "Editar")) {
                                    editingSubject = subject
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
        .navigationTitle(AppCopy.text(locale, en: "Library", es: "Biblioteca"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateSubject = true
                } label: {
                    Image(systemName: "plus")
                        .font(NTypography.bodyEmphasis)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }
            }
        }
        .task {
            viewModel.load(using: modelContext)
        }
        .sheet(isPresented: $isPresentingCreateSubject) {
            CreateSubjectView { name, systemImageName in
                try viewModel.createSubject(
                    name: name,
                    systemImageName: systemImageName,
                    using: modelContext
                )
            }
        }
        .sheet(item: $editingSubject, onDismiss: {
            viewModel.load(using: modelContext)
        }) { subject in
            CreateSubjectView(subject: subject) { name, systemImageName in
                try viewModel.updateSubject(
                    subject,
                    name: name,
                    systemImageName: systemImageName,
                    using: modelContext
                )
            }
        }
    }

    private func subjectCard(_ subject: Subject) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Image(systemName: subject.systemImageName ?? "square.grid.2x2")
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Brand.neuroBlue)

                Spacer(minLength: 0)

                Text(subject.name)
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(
                    AppCopy.countLabel(
                        locale,
                        count: subject.decks.count,
                        singularEn: "deck",
                        pluralEn: "decks",
                        singularEs: "mazo",
                        pluralEs: "mazos"
                    )
                )
                    .font(NTypography.caption)
                    .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
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

#Preview("Library Light") {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.light)
}

#Preview("Library Dark") {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [Subject.self, Deck.self, Card.self], inMemory: true)
    .preferredColorScheme(.dark)
}
