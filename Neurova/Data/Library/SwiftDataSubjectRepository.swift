import Foundation
import SwiftData

struct SwiftDataSubjectRepository: SubjectRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func listSubjects() throws -> [Subject] {
        var descriptor = FetchDescriptor<Subject>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    func createSubject(
        name: String,
        systemImageName: String?,
        colorTokenReference: String?
    ) throws -> Subject {
        let subject = Subject(
            name: name,
            systemImageName: systemImageName,
            colorTokenReference: colorTokenReference
        )
        context.insert(subject)
        try context.save()
        return subject
    }

    func updateSubject(
        _ subject: Subject,
        name: String,
        systemImageName: String?,
        colorTokenReference: String?
    ) throws {
        subject.name = name
        subject.systemImageName = systemImageName
        subject.colorTokenReference = colorTokenReference
        try context.save()
    }

    func deleteSubject(_ subject: Subject) throws {
        context.delete(subject)
        try context.save()
    }
}
