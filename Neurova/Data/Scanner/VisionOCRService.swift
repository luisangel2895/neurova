import Foundation
import Vision

struct OCRResult {
    let fullText: String
    let lines: [String]
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
                let lines = observations
                    .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }

                guard lines.isEmpty == false else {
                    continuation.resume(throwing: VisionOCRServiceError.noTextRecognized)
                    return
                }

                continuation.resume(returning: OCRResult(
                    fullText: lines.joined(separator: "\n"),
                    lines: lines
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
