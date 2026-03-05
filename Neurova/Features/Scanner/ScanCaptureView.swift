import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ScanCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @AppStorage("app_language") private var appLanguageRawValue: String = AppLanguage.spanish.rawValue

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var rawText = ""
    @State private var cleanedText = ""
    @State private var isRecognizing = false
    @State private var isSaving = false
    @State private var infoMessage: String?
    @State private var errorMessage: String?
    @State private var resultAlertMessage = ""
    @State private var isShowingResultAlert = false

    private let ocrService = VisionOCRService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    sourceCard
                    previewCard
                    textEditorCard
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
                    rawText = ""
                    cleanedText = ""
                    infoMessage = nil
                    errorMessage = nil
                }
            }
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                loadImage(from: newItem)
            }
            .alert(
                AppCopy.text(locale, en: "Scan Result", es: "Resultado del escaneo"),
                isPresented: $isShowingResultAlert
            ) {
                Button(AppCopy.text(locale, en: "OK", es: "OK"), role: .cancel) {}
            } message: {
                Text(resultAlertMessage)
            }
        }
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
                        .frame(height: 38)
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
                        .frame(height: 38)
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
                        ? AppCopy.text(locale, en: "Reading...", es: "Leyendo...")
                        : AppCopy.text(locale, en: "Run OCR", es: "Ejecutar OCR")
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

    private var textEditorCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(AppCopy.text(locale, en: "Review text", es: "Revisar texto"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Raw OCR", es: "OCR bruto"))
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Text.textSecondary)
                    TextEditor(text: $rawText)
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(NSpacing.sm)
                        .background(NColors.Home.surfaceL1)
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                .stroke(NColors.Home.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                }

                VStack(alignment: .leading, spacing: NSpacing.xs) {
                    Text(AppCopy.text(locale, en: "Cleaned text", es: "Texto limpio"))
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Text.textSecondary)
                    TextEditor(text: $cleanedText)
                        .font(NTypography.body)
                        .foregroundStyle(NColors.Text.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160)
                        .padding(NSpacing.sm)
                        .background(NColors.Home.surfaceL1)
                        .overlay(
                            RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                .stroke(NColors.Home.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: NRadius.card, style: .continuous))
                }

                HStack(spacing: NSpacing.sm) {
                    NSecondaryButton(AppCopy.text(locale, en: "Clean again", es: "Limpiar de nuevo")) {
                        cleanedText = ScanTextCleaner.cleanedText(from: rawText)
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    NPrimaryButton(
                        isSaving
                            ? AppCopy.text(locale, en: "Saving...", es: "Guardando...")
                            : AppCopy.text(locale, en: "Save scan", es: "Guardar escaneo")
                    ) {
                        saveScan()
                    }
                    .disabled(cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
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
                        rawText = ""
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
                    rawText = result.fullText
                    cleanedText = ScanTextCleaner.cleanedText(from: result.fullText)
                    infoMessage = AppCopy.text(locale, en: "OCR completed successfully.", es: "OCR completado correctamente.")
                    isRecognizing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = AppCopy.text(locale, en: "OCR failed. Please try another image.", es: "OCR fallo. Prueba con otra imagen.")
                    isRecognizing = false
                }
            }
        }
    }

    private func saveScan() {
        guard isSaving == false else { return }

        let normalizedRaw = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCleaned = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedCleaned.isEmpty == false else { return }

        isSaving = true
        errorMessage = nil
        infoMessage = nil

        let scan = ScanEntity(
            imageData: selectedImage?.jpegData(compressionQuality: 0.82),
            rawText: normalizedRaw,
            cleanedText: normalizedCleaned,
            languageCode: selectedLanguage.rawValue
        )

        modelContext.insert(scan)

        do {
            try modelContext.save()
            let savedCount = (try? modelContext.fetch(FetchDescriptor<ScanEntity>()).count) ?? 0
            let successMessage = AppCopy.text(
                locale,
                en: "Scan saved locally. Total scans: \(savedCount).",
                es: "Escaneo guardado localmente. Total de escaneos: \(savedCount)."
            )
            infoMessage = successMessage
            resultAlertMessage = successMessage
            isShowingResultAlert = true
        } catch {
            let failureMessage = AppCopy.text(
                locale,
                en: "Could not save scan. Error: \(error.localizedDescription)",
                es: "No se pudo guardar el escaneo. Error: \(error.localizedDescription)"
            )
            errorMessage = failureMessage
            resultAlertMessage = failureMessage
            isShowingResultAlert = true
        }

        isSaving = false
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .spanish
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
    ScanCaptureView()
        .modelContainer(
            for: [Subject.self, Deck.self, Card.self, XPEventEntity.self, XPStatsEntity.self, UserPreferences.self, ScanEntity.self],
            inMemory: true
        )
}
