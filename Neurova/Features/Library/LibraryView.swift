import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @State private var viewModel = LibraryViewModel()
    @State private var isPresentingCreateSubject = false
    @State private var editingSubject: Subject?

    @State private var showHeader = false
    @State private var showAddButton = false
    @State private var visibleSubjectCardCount = 0
    @State private var headerAnimationTask: Task<Void, Never>?
    @State private var addButtonAnimationTask: Task<Void, Never>?
    @State private var subjectCardsAnimationTask: Task<Void, Never>?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if viewModel.subjects.isEmpty {
                    emptySection
                } else {
                    subjectsSection
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 140)
        }
        .background(backgroundView.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.load(using: modelContext)
        }
        .onAppear {
            restartEntryAnimation()
        }
        .onDisappear {
            cancelAnimationTasks()
        }
        .sheet(isPresented: $isPresentingCreateSubject, onDismiss: {
            viewModel.load(using: modelContext)
            restartEntryAnimation()
        }) {
            CreateSubjectView { name, systemImageName, colorTokenReference in
                try viewModel.createSubject(
                    name: name,
                    systemImageName: systemImageName,
                    colorTokenReference: colorTokenReference,
                    using: modelContext
                )
            }
        }
        .sheet(item: $editingSubject, onDismiss: {
            viewModel.load(using: modelContext)
        }) { subject in
            CreateSubjectView(subject: subject) { name, systemImageName, colorTokenReference in
                try viewModel.updateSubject(
                    subject,
                    name: name,
                    systemImageName: systemImageName,
                    colorTokenReference: colorTokenReference,
                    using: modelContext
                )
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            Text(AppCopy.text(locale, en: "Library", es: "Biblioteca"))
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(NColors.Text.textPrimary)
                .offset(x: showHeader ? 0 : -10)
                .opacity(showHeader ? 1 : 0)
                .animation(.libraryExpo(duration: 0.5), value: showHeader)

            Spacer(minLength: 0)

            Button {
                isPresentingCreateSubject = true
            } label: {
                ZStack {
                    Circle()
                        .fill(addButtonBackground)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(addButtonBorder, lineWidth: 1)
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(addButtonForeground)
                }
            }
            .buttonStyle(LibraryCircleButtonStyle())
            .scaleEffect(showAddButton ? 1 : 0.01)
            .opacity(showAddButton ? 1 : 0)
            .animation(.librarySpring(delay: 0.15, stiffness: 300, damping: 24), value: showAddButton)
        }
    }

    private var subjectsSection: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(viewModel.subjects.enumerated()), id: \.element.id) { index, subject in
                NavigationLink {
                    SubjectDetailView(subject: subject)
                } label: {
                    subjectCard(subject)
                }
                .buttonStyle(LibraryCardButtonStyle())
                .scaleEffect(visibleSubjectCardCount > index ? 1 : 0.95)
                .offset(y: visibleSubjectCardCount > index ? 0 : 20)
                .opacity(visibleSubjectCardCount > index ? 1 : 0)
                .animation(.libraryExpo(duration: 0.5), value: visibleSubjectCardCount)
                .contextMenu {
                    Button {
                        editingSubject = subject
                    } label: {
                        Label(
                            AppCopy.text(locale, en: "Edit", es: "Editar"),
                            systemImage: "pencil"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.deleteSubject(subject, using: modelContext)
                    } label: {
                        Label(
                            AppCopy.text(locale, en: "Delete", es: "Eliminar"),
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
    }

    private var emptySection: some View {
        NEmptyState(
            systemImage: "books.vertical",
            title: AppCopy.text(locale, en: "No subjects yet", es: "Aun no hay materias"),
            message: AppCopy.text(locale, en: "Create your first subject to start organizing decks offline.", es: "Crea tu primera materia para empezar a organizar mazos offline."),
            ctaTitle: AppCopy.text(locale, en: "Create Subject", es: "Crear Materia")
        ) {
            isPresentingCreateSubject = true
        }
        .padding(.top, 20)
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : 20)
        .animation(.libraryExpo(duration: 0.5, delay: 0.1), value: showHeader)
    }

    private func subjectCard(_ subject: Subject) -> some View {
        let accentColor = NColors.SubjectIcon.color(for: subject.colorTokenReference)

        return RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(subjectCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(subjectCardBorder, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: subject.systemImageName ?? "square.grid.2x2")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(accentColor)
                        .padding(.top, 20)
                        .padding(.leading, 20)

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(subject.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(NColors.Text.textPrimary)
                            .lineLimit(2)

                        Text(
                            AppCopy.countLabel(
                                locale,
                                count: (subject.decks ?? []).count,
                                singularEn: "deck",
                                pluralEn: "decks",
                                singularEs: "mazo",
                                pluralEs: "mazos"
                            )
                        )
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(subjectSecondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            }
            .frame(height: 146)
            .shadow(
                color: colorScheme == .light ? Color.black.opacity(0.03) : .clear,
                radius: colorScheme == .light ? 10 : 0,
                x: 0,
                y: colorScheme == .light ? 4 : 0
            )
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .light
                    ? [NColors.App.backgroundTop, NColors.App.backgroundBottom]
                    : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: colorScheme == .light
                    ? [Color.white.opacity(0.24), .clear, NColors.Brand.neuroBlue.opacity(0.03)]
                    : [NColors.Brand.neuroBlue.opacity(0.07), .clear, .black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var subjectCardBackground: Color {
        colorScheme == .light
            ? Color.white.opacity(0.20)
            : Color(red: 0.07, green: 0.09, blue: 0.15).opacity(0.88)
    }

    private var subjectCardBorder: Color {
        colorScheme == .light
            ? Color.white.opacity(0.42)
            : Color.white.opacity(0.06)
    }

    private var subjectSecondaryText: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var addButtonBackground: Color {
        colorScheme == .light
            ? Color.white.opacity(0.14)
            : Color.white.opacity(0.03)
    }

    private var addButtonBorder: Color {
        colorScheme == .light
            ? Color.white.opacity(0.42)
            : Color.white.opacity(0.08)
    }

    private var addButtonForeground: Color {
        colorScheme == .light ? NColors.Text.textPrimary : Color.white.opacity(0.92)
    }

    private func restartEntryAnimation() {
        cancelAnimationTasks()

        showHeader = false
        showAddButton = false
        visibleSubjectCardCount = 0

        runEntryAnimation()
    }

    private func runEntryAnimation() {
        headerAnimationTask = Task {
            await MainActor.run {
                withAnimation(.libraryExpo(duration: 0.5)) {
                    showHeader = true
                }
            }
        }

        addButtonAnimationTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.librarySpring(delay: 0, stiffness: 300, damping: 24)) {
                    showAddButton = true
                }
            }
        }

        subjectCardsAnimationTask = Task {
            for index in viewModel.subjects.indices {
                let delay = index == 0 ? 100_000_000 : 70_000_000
                try? await Task.sleep(nanoseconds: UInt64(delay))
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.libraryExpo(duration: 0.5)) {
                        visibleSubjectCardCount = index + 1
                    }
                }
            }
        }
    }

    private func cancelAnimationTasks() {
        headerAnimationTask?.cancel()
        addButtonAnimationTask?.cancel()
        subjectCardsAnimationTask?.cancel()
    }
}

private struct LibraryCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct LibraryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

private extension Animation {
    static func libraryExpo(duration: Double, delay: Double = 0) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration).delay(delay)
    }

    static func librarySpring(delay: Double = 0, stiffness: Double, damping: Double) -> Animation {
        .interpolatingSpring(stiffness: stiffness, damping: damping).delay(delay)
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
