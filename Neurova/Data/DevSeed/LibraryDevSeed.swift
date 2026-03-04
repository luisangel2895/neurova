import Foundation
import SwiftData

enum LibraryDevSeed {
    static func insertSampleDataIfNeeded(into context: ModelContext) throws {
#if DEBUG
        let descriptor = FetchDescriptor<Subject>()
        let existingSubjects = try context.fetchCount(descriptor)
        guard existingSubjects == 0 else { return }

        let subject = Subject(
            name: "Biology",
            systemImageName: "leaf",
            colorTokenReference: "NeuralMint"
        )
        let deck = Deck(
            subject: subject,
            title: "Cell Biology Basics",
            description: "Seed deck for local development."
        )

        let seedCards = [
            Card(
                frontText: "What is the powerhouse of the cell?",
                backText: "The mitochondrion.",
                deck: deck
            ),
            Card(
                frontText: "What structure contains genetic material in eukaryotes?",
                backText: "The nucleus.",
                deck: deck
            ),
            Card(
                frontText: "What molecule forms the cell membrane bilayer?",
                backText: "Phospholipids.",
                deck: deck
            ),
            Card(
                frontText: "Which organelle packages and modifies proteins?",
                backText: "The Golgi apparatus.",
                deck: deck
            )
        ]

        context.insert(subject)
        context.insert(deck)
        for card in seedCards {
            context.insert(card)
        }

        try context.save()
#endif
    }
}
