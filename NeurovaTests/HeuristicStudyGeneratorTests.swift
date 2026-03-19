import Testing
@testable import Neurova

struct HeuristicStudyGeneratorTests {
    @Test
    func generatorExtractsDefinitionPairsAndDeduplicatesDrafts() {
        let text = """
        BIOLOGY:
        Cell: Basic unit of life
        - Mitosis: Cell division
        Cell: Basic unit of life
        """

        let result = HeuristicStudyGenerator().generate(from: text, language: .english)

        #expect(result.flashcards.count == 2)
        #expect(result.flashcards.map(\.front) == ["Cell", "Mitosis"])
        #expect(result.flashcards.map(\.back) == ["Basic unit of life", "Cell division"])
        #expect(result.mindMapRoot.title == "Mind Map")
        #expect(result.studyGuide.title == "Study Guide")
    }

    @Test
    func emptyInputKeepsLocalizedFallbackContent() {
        let result = HeuristicStudyGenerator().generate(from: "  \n  ", language: .spanish)

        #expect(result.flashcards.isEmpty)
        #expect(result.mindMapRoot.title == "Mapa mental")
        #expect(result.studyGuide.title == "Guía de estudio")
        #expect(result.studyGuide.summary == "Generación de guía deshabilitada temporalmente.")
    }

    @Test
    func generatorParsesTwoColumnTableLikeContent() {
        let text = """
        TERM    DEFINITION
        Atom    Smallest unit of matter
        Molecule    Group of bonded atoms
        """

        let result = HeuristicStudyGenerator().generate(from: text, language: .english)

        #expect(result.flashcards.count == 2)
        #expect(result.flashcards.map(\.front) == ["Atom", "Molecule"])
        #expect(result.flashcards.map(\.back) == ["Smallest unit of matter", "Group of bonded atoms"])
    }
}
