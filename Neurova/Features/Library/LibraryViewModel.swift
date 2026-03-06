import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LibraryViewModel {
    private var subjectRepository: (any SubjectRepository)?
    private var hasSeeded = false

    private(set) var subjects: [Subject] = []
    private(set) var readyCountBySubjectID: [UUID: Int] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    func load(using context: ModelContext) {
        configureIfNeeded(context: context)
        isLoading = true
        errorMessage = nil

        do {
            if hasSeeded == false {
                try LibraryDevSeed.insertSampleDataIfNeeded(into: context)
                hasSeeded = true
            }

            subjects = try subjectRepository?.listSubjects() ?? []
            recalculateReadyCounts(using: context)
        } catch {
            errorMessage = "Unable to load subjects."
        }

        isLoading = false
    }

    func createSubject(
        name: String,
        systemImageName: String?,
        colorTokenReference: String?,
        using context: ModelContext
    ) throws {
        configureIfNeeded(context: context)
        errorMessage = nil

        _ = try subjectRepository?.createSubject(
            name: name,
            systemImageName: normalized(systemImageName),
            colorTokenReference: normalized(colorTokenReference)
        )
        subjects = try subjectRepository?.listSubjects() ?? []
        recalculateReadyCounts(using: context)
    }

    func updateSubject(
        _ subject: Subject,
        name: String,
        systemImageName: String?,
        colorTokenReference: String?,
        using context: ModelContext
    ) throws {
        configureIfNeeded(context: context)
        errorMessage = nil

        try subjectRepository?.updateSubject(
            subject,
            name: name,
            systemImageName: normalized(systemImageName),
            colorTokenReference: normalized(colorTokenReference)
        )
        subjects = try subjectRepository?.listSubjects() ?? []
        recalculateReadyCounts(using: context)
    }

    func deleteSubject(
        _ subject: Subject,
        using context: ModelContext
    ) {
        configureIfNeeded(context: context)
        errorMessage = nil

        do {
            try subjectRepository?.deleteSubject(subject)
            subjects = try subjectRepository?.listSubjects() ?? []
            recalculateReadyCounts(using: context)
        } catch {
            errorMessage = "Unable to delete subject."
        }
    }

    func readyCount(for subject: Subject) -> Int {
        readyCountBySubjectID[subject.id] ?? 0
    }

    private func configureIfNeeded(context: ModelContext) {
        guard subjectRepository == nil else { return }
        subjectRepository = SwiftDataSubjectRepository(context: context)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func recalculateReadyCounts(using context: ModelContext) {
        let now = Date.now
        var counts: [UUID: Int] = [:]

        for subject in subjects {
            let subjectDeckIDs = Set(
                subject.decks
                    .filter { $0.isArchived == false }
                    .map(\.id)
            )

            guard subjectDeckIDs.isEmpty == false else {
                counts[subject.id] = 0
                continue
            }

            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate<Card> { card in
                    card.nextReviewDate <= now
                }
            )

            let dueCards = (try? context.fetch(descriptor)) ?? []
            counts[subject.id] = dueCards.reduce(into: 0) { partialResult, card in
                if let deckID = card.deck?.id, subjectDeckIDs.contains(deckID) {
                    partialResult += 1
                }
            }
        }

        readyCountBySubjectID = counts
    }
}
