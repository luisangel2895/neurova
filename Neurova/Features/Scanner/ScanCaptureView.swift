import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ScanCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    let onFlashcardsSaved: (String) -> Void
    let onRequestFullHeight: () -> Void

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
    @FocusState private var isCSVInputFocused: Bool

    private let ocrService = VisionOCRService()

    init(
        onFlashcardsSaved: @escaping (String) -> Void,
        onRequestFullHeight: @escaping () -> Void = {}
    ) {
        self.onFlashcardsSaved = onFlashcardsSaved
        self.onRequestFullHeight = onRequestFullHeight
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppCopy.text(locale, en: "Scan", es: "Escanear"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(NColors.Text.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(NColors.Text.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(colorScheme == .light ? Color.white.opacity(0.92) : NColors.Neutrals.surfaceAlt)
                            )
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .onChange(of: selectedMode) { _, newMode in
                if newMode == .csv {
                    scheduleCSVAutofocus()
                } else {
                    isCSVInputFocused = false
                }
            }
            .onAppear {
                if selectedMode == .csv {
                    scheduleCSVAutofocus()
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView { image in
                    selectedImage = image
                    cleanedText = ""
                    infoMessage = nil
                    errorMessage = nil
                    onRequestFullHeight()
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
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .light ? Color.white.opacity(0.82) : NColors.Neutrals.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08), lineWidth: 1)
        )
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

                    csvTextEditor
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

    private var csvTextEditor: some View {
        ZStack(alignment: .topLeading) {
            if csvTextInput.isEmpty {
                Text(AppCopy.text(locale, en: "front,back", es: "frente,reverso"))
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textTertiary)
                    .padding(.horizontal, NSpacing.md + 1)
                    .padding(.top, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $csvTextInput)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textPrimary)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .scrollContentBackground(.hidden)
                .focused($isCSVInputFocused)
                .padding(.horizontal, NSpacing.sm)
                .padding(.vertical, 6)
                .frame(height: 72)
                .background(Color.clear)
        }
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                .stroke(isCSVInputFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
        )
    }

    private func scheduleCSVAutofocus() {
        isCSVInputFocused = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard selectedMode == .csv else { return }
            isCSVInputFocused = true
        }
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

    nonisolated static func extractPairs(from csvText: String) -> [Pair] {
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

    nonisolated private static func detectDelimiter(in text: String) -> Character {
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? text
        let commaCount = firstLine.filter { $0 == "," }.count
        let semicolonCount = firstLine.filter { $0 == ";" }.count
        let tabCount = firstLine.filter { $0 == "\t" }.count

        if tabCount >= commaCount && tabCount >= semicolonCount {
            return "\t"
        }
        return semicolonCount > commaCount ? ";" : ","
    }

    nonisolated private static func parseRows(from text: String, delimiter: Character) -> [[String]] {
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

    nonisolated private static func shouldSkipHeader(_ row: [String]) -> Bool {
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

    nonisolated private static func cleanCell(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

private struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var camera = CameraSessionModel()
    @State private var capturedImage: UIImage?

    let onImagePicked: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()

                if let capturedImage {
                    HStack(spacing: 16) {
                        Button {
                            self.capturedImage = nil
                            camera.startSession()
                        } label: {
                            Text(AppCopy.text(locale, en: "Retake", es: "Repetir"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        Button {
                            onImagePicked(capturedImage)
                            dismiss()
                        } label: {
                            Text(AppCopy.text(locale, en: "Use Photo", es: "Usar foto"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                } else {
                    Button {
                        camera.capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.22))
                                .frame(width: 84, height: 84)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 66, height: 66)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            camera.onImageCaptured = { image in
                capturedImage = image
            }
            camera.startSession()
            OrientationLock.forcePortrait()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

private final class CameraSessionModel: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()

    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.session.queue")
    private var isConfigured = false

    var onImageCaptured: ((UIImage) -> Void)?

    func startSession() {
        queue.async {
            self.configureIfNeeded()
            guard self.session.isRunning == false else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() {
        queue.async {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard
            error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else { return }

        DispatchQueue.main.async {
            self.onImageCaptured?(image)
        }
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() {
        guard isConfigured == false else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else { return }

        session.addInput(input)
        session.addOutput(output)
    }
}

private enum OrientationLock {
    static func forcePortrait() {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        if #available(iOS 16.0, *) {
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .requestGeometryUpdate(preferences)
        } else {
            UINavigationController.attemptRotationToDeviceOrientation()
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
