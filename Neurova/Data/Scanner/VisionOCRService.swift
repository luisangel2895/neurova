import Foundation
import CoreGraphics
import Vision

struct OCRTablePair: Identifiable, Hashable {
    let id = UUID()
    let front: String
    let back: String
}

struct OCRTextBox: Hashable {
    let text: String
    let minX: CGFloat
    let maxX: CGFloat
    let minY: CGFloat
    let maxY: CGFloat

    var midY: CGFloat {
        (minY + maxY) / 2
    }

    var midX: CGFloat {
        (minX + maxX) / 2
    }

    var height: CGFloat {
        maxY - minY
    }
}

struct OCRResult {
    let fullText: String
    let lines: [String]
    let tablePairs: [OCRTablePair]
}

enum VisionOCRServiceError: Error {
    case noTextRecognized
}

struct VisionOCRService {
    func recognizeText(from cgImage: CGImage, preferredLanguage: AppLanguage) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let boxes = observations
                    .compactMap { observation -> OCRTextBox? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard text.isEmpty == false else { return nil }
                        let bbox = observation.boundingBox
                        return OCRTextBox(
                            text: text,
                            minX: bbox.minX,
                            maxX: bbox.maxX,
                            minY: bbox.minY,
                            maxY: bbox.maxY
                        )
                    }

                let lines = boxes.map(\.text)

                guard lines.isEmpty == false else {
                    continuation.resume(throwing: VisionOCRServiceError.noTextRecognized)
                    return
                }

                let languages = recognitionLanguages(for: preferredLanguage)
                let tablePairs = TablePairExtractor.extract(
                    from: boxes,
                    cgImage: cgImage,
                    recognitionLanguages: languages
                )

                continuation.resume(returning: OCRResult(
                    fullText: lines.joined(separator: "\n"),
                    lines: lines,
                    tablePairs: tablePairs
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = recognitionLanguages(for: preferredLanguage)

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func recognitionLanguages(for language: AppLanguage) -> [String] {
        switch language {
        case .spanish:
            return ["es-ES", "en-US"]
        case .english:
            return ["en-US", "es-ES"]
        }
    }
}

private enum TablePairExtractor {
    static func extract(
        from boxes: [OCRTextBox],
        cgImage: CGImage,
        recognitionLanguages: [String]
    ) -> [OCRTablePair] {
        let directPairs = extractFromDetectedRows(from: boxes)
        let cellPairs = extractByCellOCR(
            from: boxes,
            cgImage: cgImage,
            recognitionLanguages: recognitionLanguages
        )

        let bestPairs: [OCRTablePair]
        if cellPairs.count >= max(3, directPairs.count) {
            bestPairs = cellPairs
        } else {
            bestPairs = directPairs
        }

        return dedupe(bestPairs)
    }

    private static func extractFromDetectedRows(from boxes: [OCRTextBox]) -> [OCRTablePair] {
        guard boxes.isEmpty == false else { return [] }

        let sorted = boxes.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) < 0.002 {
                return lhs.minX < rhs.minX
            }
            return lhs.midY > rhs.midY
        }

        let avgHeight = sorted.map(\.height).reduce(0, +) / CGFloat(max(sorted.count, 1))
        let rowTolerance = max(0.012, avgHeight * 0.8)

        var rows: [[OCRTextBox]] = []
        for box in sorted {
            if let rowIndex = rows.firstIndex(where: { row in
                guard let anchor = row.first else { return false }
                return abs(anchor.midY - box.midY) <= rowTolerance
            }) {
                rows[rowIndex].append(box)
            } else {
                rows.append([box])
            }
        }

        var pairs: [OCRTablePair] = []

        for row in rows {
            let ordered = row.sorted { $0.minX < $1.minX }
            guard ordered.count >= 2 else { continue }

            // Use leftmost and rightmost cell to be robust when OCR creates intermediate fragments.
            let left = cleanCellText(ordered.first?.text ?? "")
            let right = cleanCellText(ordered.last?.text ?? "")
            guard left.isEmpty == false, right.isEmpty == false else { continue }
            guard left.lowercased() != right.lowercased() else { continue }

            pairs.append(OCRTablePair(front: left, back: right))
        }

        return pairs
    }

    private static func extractByCellOCR(
        from boxes: [OCRTextBox],
        cgImage: CGImage,
        recognitionLanguages: [String]
    ) -> [OCRTablePair] {
        guard boxes.count >= 4 else { return [] }
        let rowClusters = clusterRows(from: boxes)
        guard rowClusters.count >= 2 else { return [] }

        guard let splitX = estimateColumnSplitX(from: boxes) else { return [] }
        let globalMinX = boxes.map(\.minX).min() ?? 0
        let globalMaxX = boxes.map(\.maxX).max() ?? 1
        guard splitX > globalMinX + 0.05, splitX < globalMaxX - 0.05 else { return [] }

        var pairs: [OCRTablePair] = []
        for row in rowClusters {
            let minY = max(0, row.minY - 0.005)
            let maxY = min(1, row.maxY + 0.005)
            guard maxY > minY else { continue }

            let leftRect = CGRect(
                x: globalMinX,
                y: minY,
                width: max(0, splitX - globalMinX),
                height: maxY - minY
            )
            let rightRect = CGRect(
                x: splitX,
                y: minY,
                width: max(0, globalMaxX - splitX),
                height: maxY - minY
            )

            let leftText = recognizeCellText(
                in: leftRect,
                from: cgImage,
                recognitionLanguages: recognitionLanguages
            )
            let rightText = recognizeCellText(
                in: rightRect,
                from: cgImage,
                recognitionLanguages: recognitionLanguages
            )

            let cleanLeft = cleanCellText(leftText)
            let cleanRight = cleanCellText(rightText)
            guard cleanLeft.isEmpty == false, cleanRight.isEmpty == false else { continue }
            guard cleanLeft.lowercased() != cleanRight.lowercased() else { continue }

            pairs.append(OCRTablePair(front: cleanLeft, back: cleanRight))
        }

        return pairs
    }

    private static func clusterRows(from boxes: [OCRTextBox]) -> [RowCluster] {
        let sorted = boxes.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) < 0.002 {
                return lhs.minX < rhs.minX
            }
            return lhs.midY > rhs.midY
        }

        let avgHeight = sorted.map(\.height).reduce(0, +) / CGFloat(max(sorted.count, 1))
        let rowTolerance = max(0.012, avgHeight * 0.8)

        var rows: [RowCluster] = []
        for box in sorted {
            if let index = rows.firstIndex(where: { abs($0.anchorY - box.midY) <= rowTolerance }) {
                rows[index].boxes.append(box)
                rows[index].minY = min(rows[index].minY, box.minY)
                rows[index].maxY = max(rows[index].maxY, box.maxY)
            } else {
                rows.append(RowCluster(anchorY: box.midY, minY: box.minY, maxY: box.maxY, boxes: [box]))
            }
        }

        return rows
    }

    private static func estimateColumnSplitX(from boxes: [OCRTextBox]) -> CGFloat? {
        let centers = boxes
            .map(\.midX)
            .sorted()
        guard centers.count >= 4 else { return nil }

        var bestGap: CGFloat = 0
        var split: CGFloat?

        for index in 0..<(centers.count - 1) {
            let gap = centers[index + 1] - centers[index]
            if gap > bestGap {
                bestGap = gap
                split = (centers[index] + centers[index + 1]) / 2
            }
        }

        guard bestGap >= 0.08 else { return nil }
        return split
    }

    private static func recognizeCellText(
        in normalizedRect: CGRect,
        from cgImage: CGImage,
        recognitionLanguages: [String]
    ) -> String {
        guard let pixelRect = pixelRect(from: normalizedRect, imageWidth: cgImage.width, imageHeight: cgImage.height) else {
            return ""
        }
        guard let cropped = cgImage.cropping(to: pixelRect) else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = recognitionLanguages

        let handler = VNImageRequestHandler(cgImage: cropped, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }

    private static func pixelRect(from normalizedRect: CGRect, imageWidth: Int, imageHeight: Int) -> CGRect? {
        guard normalizedRect.width > 0, normalizedRect.height > 0 else { return nil }

        let width = CGFloat(imageWidth)
        let height = CGFloat(imageHeight)

        let x = normalizedRect.minX * width
        let y = (1 - normalizedRect.maxY) * height
        let w = normalizedRect.width * width
        let h = normalizedRect.height * height

        let rect = CGRect(x: x, y: y, width: w, height: h).integral
        let imageBounds = CGRect(x: 0, y: 0, width: width, height: height)
        let clipped = rect.intersection(imageBounds)
        guard clipped.width > 1, clipped.height > 1 else { return nil }
        return clipped
    }

    private static func dedupe(_ pairs: [OCRTablePair]) -> [OCRTablePair] {
        var seen = Set<String>()
        var output: [OCRTablePair] = []

        for pair in pairs {
            let key = "\(pair.front.lowercased())|\(pair.back.lowercased())"
            guard seen.contains(key) == false else { continue }
            seen.insert(key)
            output.append(pair)
        }

        return output
    }

    private static func cleanCellText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^\d+[\.\)\:\-]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[-*•‣◦▪▫]+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct RowCluster {
        let anchorY: CGFloat
        var minY: CGFloat
        var maxY: CGFloat
        var boxes: [OCRTextBox]
    }
}
