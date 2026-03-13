import Testing
@testable import Neurova

struct AppLanguageTests {
    @Test
    func titlesAreLocalizedForBothLanguageContexts() {
        #expect(AppLanguage.english.title(for: .english) == "English")
        #expect(AppLanguage.english.title(for: .spanish) == "Ingles")
        #expect(AppLanguage.spanish.title(for: .english) == "Spanish")
        #expect(AppLanguage.spanish.title(for: .spanish) == "Espanol")
    }
}
