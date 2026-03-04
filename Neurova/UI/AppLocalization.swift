import Foundation

enum AppCopy {
    static func language(for locale: Locale) -> AppLanguage {
        locale.identifier.lowercased().hasPrefix("es") ? .spanish : .english
    }

    static func text(_ locale: Locale, en: String, es: String) -> String {
        language(for: locale) == .spanish ? es : en
    }

    static func countLabel(
        _ locale: Locale,
        count: Int,
        singularEn: String,
        pluralEn: String,
        singularEs: String,
        pluralEs: String
    ) -> String {
        let isSingular = count == 1
        let label = if language(for: locale) == .spanish {
            isSingular ? singularEs : pluralEs
        } else {
            isSingular ? singularEn : pluralEn
        }

        return "\(count) \(label)"
    }
}
