import Foundation

enum ScanTextCleaner {
    static func cleanedText(from rawText: String) -> String {
        let normalizedLines = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { line in
                line
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { $0.isEmpty == false }

        guard normalizedLines.isEmpty == false else {
            return ""
        }

        var output: [String] = []
        for line in normalizedLines {
            if isLikelySectionTitle(line) {
                if output.last?.isEmpty == false {
                    output.append("")
                }
                output.append(line)
                output.append("")
            } else {
                output.append(line)
            }
        }

        return output
            .joined(separator: "\n")
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isLikelySectionTitle(_ line: String) -> Bool {
        if line.hasSuffix(":") {
            return true
        }

        let words = line.split(separator: " ")
        guard words.count > 0, words.count <= 8 else {
            return false
        }

        let uppercasedLetters = line.filter(\.isLetter).filter(\.isUppercase).count
        let allLetters = line.filter(\.isLetter).count
        if allLetters == 0 {
            return false
        }

        let uppercaseRatio = Double(uppercasedLetters) / Double(allLetters)
        return uppercaseRatio > 0.7
    }
}
