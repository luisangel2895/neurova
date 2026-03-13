import Foundation
import Testing
@testable import Neurova

struct AppCopyTests {
    @Test
    func languageDetectionPrefersSpanishLocales() {
        #expect(AppCopy.language(for: Locale(identifier: "es_ES")) == .spanish)
        #expect(AppCopy.language(for: Locale(identifier: "es-MX")) == .spanish)
        #expect(AppCopy.language(for: Locale(identifier: "en_US")) == .english)
    }

    @Test
    func countLabelUsesLocalizedPluralization() {
        let english = AppCopy.countLabel(
            Locale(identifier: "en_US"),
            count: 1,
            singularEn: "card",
            pluralEn: "cards",
            singularEs: "tarjeta",
            pluralEs: "tarjetas"
        )

        let spanish = AppCopy.countLabel(
            Locale(identifier: "es_ES"),
            count: 3,
            singularEn: "card",
            pluralEn: "cards",
            singularEs: "tarjeta",
            pluralEs: "tarjetas"
        )

        #expect(english == "1 card")
        #expect(spanish == "3 tarjetas")
    }
}
