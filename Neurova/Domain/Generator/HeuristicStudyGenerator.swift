import Foundation

struct HeuristicStudyGenerator {
    private let maxFlashcards = 200

    func generate(from cleanedText: String, language: AppLanguage) -> GeneratedStudyContent {
        let normalized = cleanedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let sections = splitIntoSections(normalized)
        let flashcards = buildFlashcards(from: sections, language: language)

        return GeneratedStudyContent(
            flashcards: flashcards,
            mindMapRoot: MindMapNode(
                title: language == .spanish ? "Mapa mental" : "Mind Map",
                children: []
            ),
            studyGuide: StudyGuide(
                title: language == .spanish ? "Guía de estudio" : "Study Guide",
                summary: language == .spanish
                    ? "Generación de guía deshabilitada temporalmente."
                    : "Study guide generation is temporarily disabled.",
                sections: []
            )
        )
    }

    private func splitIntoSections(_ text: String) -> [(title: String, lines: [String])] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard lines.isEmpty == false else {
            return [(title: "Overview", lines: [])]
        }

        var sections: [(title: String, lines: [String])] = []
        var currentTitle = "Overview"
        var currentLines: [String] = []

        for line in lines {
            if isLikelyTitle(line) {
                if currentLines.isEmpty == false || sections.isEmpty {
                    sections.append((title: currentTitle, lines: currentLines))
                }
                currentTitle = normalizeTitle(line)
                currentLines = []
            } else {
                currentLines.append(line)
            }
        }

        sections.append((title: currentTitle, lines: currentLines))

        return sections.filter { $0.lines.isEmpty == false || $0.title != "Overview" }
    }

    private func buildFlashcards(
        from sections: [(title: String, lines: [String])],
        language: AppLanguage
    ) -> [CardDraft] {
        var drafts: [CardDraft] = []
        var seen = Set<String>()

        for section in sections {
            for rawLine in section.lines {
                let cleanedLine = stripListPrefix(from: rawLine)

                if let (left, right) = parseDefinition(cleanedLine) {
                    appendDraft(
                        front: left,
                        back: right,
                        drafts: &drafts,
                        seen: &seen
                    )
                    continue
                }

                if isListLike(rawLine) {
                    if let (left, right) = parsePairFromList(cleanedLine) {
                        appendDraft(
                            front: left,
                            back: right,
                            drafts: &drafts,
                            seen: &seen
                        )
                        continue
                    }

                    let normalizedSection = normalizedSectionTitle(section.title, language: language)
                    appendDraft(
                        front: cleanedLine,
                        back: normalizedSection,
                        drafts: &drafts,
                        seen: &seen
                    )
                }
            }
        }

        return Array(drafts.prefix(maxFlashcards))
    }

    private func buildMindMap(
        from sections: [(title: String, lines: [String])],
        language: AppLanguage
    ) -> MindMapNode {
        let rootTitle = language == .spanish ? "Mapa mental" : "Mind Map"

        let children = sections.map { section in
            let keywords = topKeywords(from: section.lines, max: 5)
            return MindMapNode(
                title: section.title,
                children: keywords.map { MindMapNode(title: $0, children: []) }
            )
        }

        return MindMapNode(title: rootTitle, children: children)
    }

    private func buildStudyGuide(
        from sections: [(title: String, lines: [String])],
        language: AppLanguage
    ) -> StudyGuide {
        let title = language == .spanish ? "Guía de estudio" : "Study Guide"
        let summary = buildSummary(from: sections, language: language)
        let guideSections = sections.map { section in
            StudyGuideSection(
                title: section.title,
                bullets: Array(section.lines.prefix(6))
            )
        }

        return StudyGuide(
            title: title,
            summary: summary,
            sections: guideSections
        )
    }

    private func buildSummary(from sections: [(title: String, lines: [String])], language: AppLanguage) -> String {
        let sentenceLimit = 3
        var sentences: [String] = []

        for section in sections {
            for line in section.lines {
                let split = line
                    .split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" })
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
                sentences.append(contentsOf: split)
                if sentences.count >= sentenceLimit {
                    break
                }
            }
            if sentences.count >= sentenceLimit {
                break
            }
        }

        if sentences.isEmpty {
            return language == .spanish
                ? "No se encontró suficiente contenido para resumir."
                : "Not enough content to summarize."
        }

        return sentences.prefix(sentenceLimit).joined(separator: ". ") + "."
    }

    private func parseDefinition(_ line: String) -> (String, String)? {
        let normalizedLine = line
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let parenthesisPair = parseParenthesisPair(normalizedLine) {
            return parenthesisPair
        }

        if let columnPair = parseTwoColumnPair(line) {
            return columnPair
        }

        let separators = [":", " - ", " – ", " — "]

        for separator in separators {
            guard let separatorRange = normalizedLine.range(of: separator) else { continue }

            let left = normalizeDefinitionFragment(String(normalizedLine[normalizedLine.startIndex..<separatorRange.lowerBound]))
            let right = normalizeDefinitionFragment(String(normalizedLine[separatorRange.upperBound...]))

            guard left.isEmpty == false, right.isEmpty == false else { continue }
            guard left.count <= 80, right.count >= 3 else { continue }

            return (left, right)
        }

        return nil
    }

    private func parseParenthesisPair(_ line: String) -> (String, String)? {
        guard let range = line.range(of: #"^(.+?)\s*\(([^()]+)\)\s*$"#, options: .regularExpression) else {
            return nil
        }

        let matched = String(line[range])
        guard let openIndex = matched.lastIndex(of: "("),
              let closeIndex = matched.lastIndex(of: ")"),
              openIndex < closeIndex else {
            return nil
        }

        let leftPart = String(matched[..<openIndex])
        let rightPart = String(matched[matched.index(after: openIndex)..<closeIndex])

        let left = normalizeDefinitionFragment(leftPart)
        let right = normalizeDefinitionFragment(rightPart)
        guard left.isEmpty == false, right.isEmpty == false else { return nil }

        return (left, right)
    }

    private func parseTwoColumnPair(_ originalLine: String) -> (String, String)? {
        let trimmed = originalLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if trimmed.hasPrefix("|"), trimmed.hasSuffix("|") {
            let parts = trimmed
                .split(separator: "|")
                .map { normalizeDefinitionFragment(String($0)) }
                .filter { $0.isEmpty == false }
            if parts.count == 2 {
                return (parts[0], parts[1])
            }
        }

        let tabParts = trimmed
            .components(separatedBy: "\t")
            .map(normalizeDefinitionFragment)
            .filter { $0.isEmpty == false }
        if tabParts.count == 2 {
            return (tabParts[0], tabParts[1])
        }

        let normalizedColumns = trimmed.replacingOccurrences(
            of: #"\s{2,}"#,
            with: "\t",
            options: .regularExpression
        )
        let multiSpaceParts = normalizedColumns
            .components(separatedBy: "\t")
            .map(normalizeDefinitionFragment)
            .filter { $0.isEmpty == false }
        if multiSpaceParts.count == 2 {
            return (multiSpaceParts[0], multiSpaceParts[1])
        }

        return nil
    }

    private func topKeywords(from lines: [String], max: Int) -> [String] {
        let stopWords: Set<String> = [
            "the", "and", "for", "with", "from", "that", "this", "are", "was", "were", "have", "has",
            "una", "unas", "unos", "para", "con", "por", "que", "los", "las", "del", "como", "esta", "este"
        ]

        var frequency: [String: Int] = [:]

        for line in lines {
            let words = line
                .lowercased()
                .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
                .map(String.init)
                .filter { $0.count > 3 && stopWords.contains($0) == false }

            for word in words {
                frequency[word, default: 0] += 1
            }
        }

        return frequency
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(max)
            .map { $0.key.capitalized }
    }

    private func appendDraft(
        front: String,
        back: String,
        drafts: inout [CardDraft],
        seen: inout Set<String>
    ) {
        let normalizedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedFront.isEmpty == false, normalizedBack.isEmpty == false else { return }

        let key = "\(normalizedFront.lowercased())|\(normalizedBack.lowercased())"
        guard seen.contains(key) == false else { return }
        seen.insert(key)

        drafts.append(CardDraft(front: normalizedFront, back: normalizedBack))
    }

    private func isLikelyTitle(_ line: String) -> Bool {
        if line.hasSuffix(":") { return true }
        let words = line.split(separator: " ")
        guard words.count <= 7 else { return false }
        let uppercase = line.filter(\.isLetter).filter(\.isUppercase).count
        let letters = line.filter(\.isLetter).count
        guard letters > 0 else { return false }
        return Double(uppercase) / Double(letters) >= 0.65
    }

    private func normalizeTitle(_ line: String) -> String {
        line
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parsePairFromList(_ line: String) -> (String, String)? {
        if let parsed = parseDefinition(line) {
            return parsed
        }

        let separators = [" = ", " -> ", " → "]
        for separator in separators {
            let parts = line.components(separatedBy: separator)
            guard parts.count == 2 else { continue }
            let left = normalizeDefinitionFragment(parts[0])
            let right = normalizeDefinitionFragment(parts[1])
            guard left.isEmpty == false, right.isEmpty == false else { continue }
            return (left, right)
        }

        return nil
    }

    private func isListLike(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }

        if ["-", "*", "•", "‣", "◦", "▪", "▫"].contains(where: { trimmed.hasPrefix($0) }) {
            return true
        }

        let patterns = [
            #"^\d+[\.\):\-]\s+.*"#,               // 1. Item / 1) Item / 1- Item / 1: Item
            #"^\(\d+\)\s+.*"#,                    // (1) Item
            #"^[A-Za-z][\.\)]\s+.*"#,             // a) Item / A. Item
            #"^\([A-Za-z]\)\s+.*"#,               // (a) Item
            #"^(?i:[ivxlcdm]+)[\.\)]\s+.*"#,      // iv) Item / IV. Item
            #"^\[[xX\s]\]\s+.*"#                  // [ ] Item / [x] Item
        ]

        return patterns.contains { pattern in
            trimmed.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func stripListPrefix(from line: String) -> String {
        var output = line.trimmingCharacters(in: .whitespacesAndNewlines)

        let prefixPatterns = [
            #"^[-*•‣◦▪▫]+\s+"#,
            #"^\d+[\.\):\-]\s+"#,
            #"^\(\d+\)\s+"#,
            #"^[A-Za-z][\.\)]\s+"#,
            #"^\([A-Za-z]\)\s+"#,
            #"^(?i:[ivxlcdm]+)[\.\)]\s+"#,
            #"^\[[xX\s]\]\s+"#
        ]

        var didStrip = true
        while didStrip {
            didStrip = false
            for pattern in prefixPatterns {
                if let range = output.range(of: pattern, options: .regularExpression) {
                    output.removeSubrange(range)
                    output = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    didStrip = true
                }
            }
        }

        return output
    }

    private func normalizeDefinitionFragment(_ fragment: String) -> String {
        fragment
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^[\-\•\*\(\)\[\]\.:;\s]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[\s\.:;,\-]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedSectionTitle(_ title: String, language: AppLanguage) -> String {
        let normalized = normalizeTitle(title)
        if normalized == "Overview" {
            return language == .spanish ? "Tema general" : "General topic"
        }
        return normalized
    }
}
