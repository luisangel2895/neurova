import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ScanCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    let onFlashcardsSaved: (String) -> Void

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var cleanedText = ""
    @State private var isRecognizing = false
    @State private var infoMessage: String?
    @State private var errorMessage: String?
    @State private var isShowingGeneratorPreview = false
    @State private var selectedMode: ScanInputMode = .capture
    @State private var csvTextInput = ""
    @State private var isShowingCSVImporter = false
    @State private var importedCSVFileName: String?

    private let ocrService = VisionOCRService()

    init(onFlashcardsSaved: @escaping (String) -> Void) {
        self.onFlashcardsSaved = onFlashcardsSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    modePicker
                    if selectedMode == .capture {
                        sourceCard
                        previewCard
                    } else {
                        csvImportCard
                    }
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.vertical, NSpacing.md)
            }
            .background(NColors.Neutrals.background.ignoresSafeArea())
            .navigationTitle(AppCopy.text(locale, en: "Scan", es: "Escanear"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppCopy.text(locale, en: "Close", es: "Cerrar")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraImagePicker { image in
                    selectedImage = image
                    cleanedText = ""
                    infoMessage = nil
                    errorMessage = nil
                }
            }
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                loadImage(from: newItem)
            }
            .fileImporter(
                isPresented: $isShowingCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleCSVImport(result: result)
            }
            .fullScreenCover(isPresented: $isShowingGeneratorPreview) {
                GeneratorPreviewView(cleanedText: cleanedText) { message in
                    onFlashcardsSaved(message)
                    dismiss()
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("", selection: $selectedMode) {
            Text(AppCopy.text(locale, en: "Capture", es: "Captura"))
                .tag(ScanInputMode.capture)
            Text(AppCopy.text(locale, en: "CSV tables", es: "Tablas CSV"))
                .tag(ScanInputMode.csv)
        }
        .pickerStyle(.segmented)
    }

    private var sourceCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Capture source", es: "Fuente de captura"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                HStack(spacing: NSpacing.sm) {
                    Button {
                        isShowingCamera = true
                    } label: {
                        Label(
                            AppCopy.text(locale, en: "Camera", es: "Camara"),
                            systemImage: "camera.fill"
                        )
                        .font(NTypography.caption.weight(.semibold))
                        .foregroundStyle(NColors.Brand.neuroBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                .fill(NColors.Home.surfaceL2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                .stroke(NColors.Home.layeredStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Label(
                            AppCopy.text(locale, en: "Library", es: "Fotos"),
                            systemImage: "photo.on.rectangle.angled"
                        )
                        .font(NTypography.caption.weight(.semibold))
                        .foregroundStyle(NColors.Brand.neuroBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                .fill(NColors.Home.surfaceL2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                .stroke(NColors.Home.layeredStroke, lineWidth: 1)
                        )
                    }
                }

                NPrimaryButton(
                    isRecognizing
                        ? AppCopy.text(locale, en: "Processing...", es: "Procesando...")
                        : AppCopy.text(locale, en: "Create from image", es: "Crear desde imagen")
                ) {
                    runOCR()
                }
                .disabled(selectedImage == nil || isRecognizing)
            }
        }
    }

    private var previewCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(AppCopy.text(locale, en: "Preview", es: "Vista previa"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                } else {
                    Text(AppCopy.text(locale, en: "No image selected yet.", es: "Aun no seleccionaste imagen."))
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Text.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Feedback.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let infoMessage {
                    Text(infoMessage)
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var csvImportCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Import CSV for flashcards", es: "Importar CSV para flashcards"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                NSecondaryButton(AppCopy.text(locale, en: "Attach CSV file", es: "Adjuntar archivo CSV")) {
                    isShowingCSVImporter = true
                }

                if let importedCSVFileName {
                    Text(
                        AppCopy.text(
                            locale,
                            en: "Loaded file: \(importedCSVFileName)",
                            es: "Archivo cargado: \(importedCSVFileName)"
                        )
                    )
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Brand.neuroBlue)
                }

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Or paste CSV content", es: "O pega contenido CSV"))
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Text.textSecondary)

                    TextEditor(text: $csvTextInput)
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .scrollContentBackground(.hidden)
                        .frame(height: 320)
                        .padding(NSpacing.sm)
                        .background(NColors.Home.surfaceL1)
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                .stroke(NColors.Home.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                }

                NPrimaryButton(AppCopy.text(locale, en: "Convert CSV", es: "Convertir CSV")) {
                    convertCSVAndContinue()
                }
                .disabled(csvTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let errorMessage {
                    Text(errorMessage)
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Feedback.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let infoMessage {
                    Text(infoMessage)
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        cleanedText = ""
                        infoMessage = nil
                        errorMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = AppCopy.text(locale, en: "Unable to load image.", es: "No se pudo cargar la imagen.")
                }
            }
        }
    }

    private func runOCR() {
        guard isRecognizing == false else { return }
        guard let cgImage = selectedImage?.cgImage else {
            errorMessage = AppCopy.text(locale, en: "Select an image first.", es: "Selecciona una imagen primero.")
            return
        }

        isRecognizing = true
        errorMessage = nil
        infoMessage = nil

        Task {
            do {
                let result = try await ocrService.recognizeText(from: cgImage, preferredLanguage: selectedLanguage)
                await MainActor.run {
                    if result.tablePairs.count >= 3 {
                        let tableReconstructedText = result.tablePairs
                            .map { "\($0.front): \($0.back)" }
                            .joined(separator: "\n")
                        cleanedText = ScanTextCleaner.cleanedText(from: tableReconstructedText)
                    } else {
                        cleanedText = ScanTextCleaner.cleanedText(from: result.fullText)
                    }
                    isRecognizing = false
                    if cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errorMessage = AppCopy.text(
                            locale,
                            en: "No readable text found. Try a clearer image.",
                            es: "No se encontró texto legible. Prueba con una imagen más clara."
                        )
                    } else {
                        infoMessage = AppCopy.text(
                            locale,
                            en: "Done. Choose where to save your flashcards.",
                            es: "Listo. Elige dónde guardar tus flashcards."
                        )
                        isShowingGeneratorPreview = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = AppCopy.text(locale, en: "OCR failed. Please try another image.", es: "OCR falló. Prueba con otra imagen.")
                    isRecognizing = false
                }
            }
        }
    }

    private func handleCSVImport(result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                guard let fileText = String(data: data, encoding: .utf8) ??
                    String(data: data, encoding: .isoLatin1) else {
                    errorMessage = AppCopy.text(locale, en: "Could not decode CSV file.", es: "No se pudo leer el archivo CSV.")
                    return
                }
                csvTextInput = fileText
                importedCSVFileName = url.lastPathComponent
                infoMessage = AppCopy.text(locale, en: "CSV loaded. Ready to convert.", es: "CSV cargado. Listo para convertir.")
                errorMessage = nil
            } catch {
                errorMessage = AppCopy.text(locale, en: "Could not read CSV file.", es: "No se pudo leer el archivo CSV.")
            }
        case .failure:
            errorMessage = AppCopy.text(locale, en: "CSV import was cancelled or failed.", es: "La importación CSV se canceló o falló.")
        }
    }

    private func convertCSVAndContinue() {
        errorMessage = nil
        infoMessage = nil

        let pairs = CSVFlashcardParser.extractPairs(from: csvTextInput)
        guard pairs.isEmpty == false else {
            errorMessage = AppCopy.text(
                locale,
                en: "No valid flashcard pairs were found in the CSV.",
                es: "No se encontraron pares válidos de flashcards en el CSV."
            )
            return
        }

        cleanedText = pairs
            .map { "\($0.front): \($0.back)" }
            .joined(separator: "\n")

        infoMessage = AppCopy.text(
            locale,
            en: "Converted \(pairs.count) pairs. Choose where to save.",
            es: "Se convirtieron \(pairs.count) pares. Elige dónde guardar."
        )
        isShowingGeneratorPreview = true
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
    }
}

private enum ScanInputMode {
    case capture
    case csv
}

private struct CSVFlashcardParser {
    struct Pair {
        let front: String
        let back: String
    }

    static func extractPairs(from csvText: String) -> [Pair] {
        let normalized = csvText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.isEmpty == false else { return [] }

        let delimiter = detectDelimiter(in: normalized)
        var rows = parseRows(from: normalized, delimiter: delimiter)
            .map { row in row.map(cleanCell) }
            .filter { row in row.contains(where: { $0.isEmpty == false }) }

        guard rows.isEmpty == false else { return [] }
        if shouldSkipHeader(rows[0]) {
            rows.removeFirst()
        }

        var pairs: [Pair] = []
        var seen = Set<String>()

        for row in rows {
            let values = row.filter { $0.isEmpty == false }
            guard values.count >= 2 else { continue }

            let front = values[0]
            let back = values[1]
            guard front.isEmpty == false, back.isEmpty == false else { continue }

            let key = "\(front.lowercased())|\(back.lowercased())"
            guard seen.contains(key) == false else { continue }
            seen.insert(key)
            pairs.append(Pair(front: front, back: back))
        }

        return pairs
    }

    private static func detectDelimiter(in text: String) -> Character {
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? text
        let commaCount = firstLine.filter { $0 == "," }.count
        let semicolonCount = firstLine.filter { $0 == ";" }.count
        let tabCount = firstLine.filter { $0 == "\t" }.count

        if tabCount >= commaCount && tabCount >= semicolonCount {
            return "\t"
        }
        return semicolonCount > commaCount ? ";" : ","
    }

    private static func parseRows(from text: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var cell = ""
        var insideQuotes = false

        for char in text {
            if char == "\"" {
                if insideQuotes {
                    insideQuotes = false
                } else {
                    insideQuotes = true
                }
                continue
            }

            if char == delimiter, insideQuotes == false {
                row.append(cell)
                cell = ""
                continue
            }

            if char == "\n", insideQuotes == false {
                row.append(cell)
                rows.append(row)
                row = []
                cell = ""
                continue
            }

            cell.append(char)
        }

        if cell.isEmpty == false || row.isEmpty == false {
            row.append(cell)
            rows.append(row)
        }

        return rows
    }

    private static func shouldSkipHeader(_ row: [String]) -> Bool {
        let headerKeywords: Set<String> = [
            "front", "back", "question", "answer", "term", "definition",
            "anverso", "reverso", "pregunta", "respuesta", "termino", "término", "definicion", "definición"
        ]
        let normalized = row
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard normalized.count >= 2 else { return false }
        return normalized.prefix(2).allSatisfy { headerKeywords.contains($0) }
    }

    private static func cleanCell(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }
    }
}

#Preview("Scan Capture") {
    ScanCaptureView(onFlashcardsSaved: { _ in })
        .modelContainer(
            for: [
                Subject.self,
                Deck.self,
                Card.self,
                XPEventEntity.self,
                XPStatsEntity.self,
                UserPreferences.self,
                ScanEntity.self
            ],
            inMemory: true
        )
}
