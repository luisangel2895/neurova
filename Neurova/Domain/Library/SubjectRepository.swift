import Foundation

protocol SubjectRepository {
    func listSubjects() throws -> [Subject]
    func createSubject(
        name: String,
        systemImageName: String?,
        colorTokenReference: String?
    ) throws -> Subject
    func updateSubject(
        _ subject: Subject,
        name: String,
        systemImageName: String?,
        colorTokenReference: String?
    ) throws
    func deleteSubject(_ subject: Subject) throws
}
