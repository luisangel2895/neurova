import Foundation

struct CardDraft: Identifiable, Equatable {
    let id = UUID()
    var front: String
    var back: String
}

struct MindMapNode: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var children: [MindMapNode]
}

struct StudyGuideSection: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var bullets: [String]
}

struct StudyGuide: Equatable {
    var title: String
    var summary: String
    var sections: [StudyGuideSection]
}

struct GeneratedStudyContent: Equatable {
    var flashcards: [CardDraft]
    var mindMapRoot: MindMapNode
    var studyGuide: StudyGuide
}
