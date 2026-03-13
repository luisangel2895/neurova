import Testing
@testable import Neurova

struct ScanTextCleanerTests {
    @Test
    func cleanerNormalizesWhitespaceAndKeepsSectionSpacing() {
        let raw = "TITLE:\\r\\n  First    line  \\r\\n\\r\\nSECOND SECTION\\nItem   one"

        let cleaned = ScanTextCleaner.cleanedText(from: raw)

        #expect(cleaned == "TITLE:\n\nFirst line\n\nSECOND SECTION\n\nItem one")
    }

    @Test
    func cleanerReturnsEmptyStringForEmptyInput() {
        let cleaned = ScanTextCleaner.cleanedText(from: " \n \r\n ")

        #expect(cleaned.isEmpty)
    }
}
