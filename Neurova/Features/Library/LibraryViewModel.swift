import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LibraryViewModel {
    private var subjectRepository: (any SubjectRepository)?
    private var hasSeeded = false

    private(set) var subjects: [Subject] = []
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
}
