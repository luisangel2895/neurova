import SwiftUI
import UIKit

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let deck: Deck?
    private let onSave: (String, String?) -> Void

    @State private var title: String
    @State private var descriptionText: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var pendingSaveRequest = false
    @State private var isTitleFocused = false
    @State private var isDescriptionFocused = false

    init(
        deck: Deck? = nil,
        onSave: @escaping (String, String?) -> Void
    ) {
        self.deck = deck
        self.onSave = onSave
        _title = State(initialValue: deck?.title ?? "")
        _descriptionText = State(initialValue: deck?.description ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(NTypography.caption)
                            .foregroundStyle(NColors.Feedback.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    previewCard
                    titleField
                    descriptionField
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
                .padding(.bottom, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(
                        deck == nil
                            ? AppCopy.text(locale, en: "Create Deck", es: "Crear Mazo")
                            : AppCopy.text(locale, en: "Edit Deck", es: "Editar Mazo")
                    )
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(NColors.Text.textPrimary)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(NColors.Text.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        handleSave()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .disabled(canSave == false)
                    .foregroundStyle(canSave ? NColors.Brand.neuroBlue : NColors.Text.textSecondary)
                }
            }
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(120))
                    isTitleFocused = true
                }
            }
            .onChange(of: isTitleFocused) { _, _ in
                handlePendingSaveIfNeeded()
            }
            .onChange(of: isDescriptionFocused) { _, _ in
                handlePendingSaveIfNeeded()
            }
            .onDisappear {
                pendingSaveRequest = false
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String? {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var canSave: Bool {
        trimmedTitle.isEmpty == false && isSaving == false
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var previewCard: some View {
        NCard {
            HStack(spacing: NSpacing.sm) {
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .fill(NColors.Brand.neuroBlue.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(NColors.Brand.neuroBlue)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(trimmedTitle.isEmpty ? AppCopy.text(locale, en: "Deck Preview", es: "Vista previa del mazo") : trimmedTitle)
                        .font(NTypography.bodyEmphasis.weight(.semibold))
                        .foregroundStyle(NColors.Text.textPrimary)

                    Text(
                        trimmedDescription ?? AppCopy.text(locale, en: "Title + description", es: "Titulo + descripcion")
                    )
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var titleField: some View {
        NOptimizedTextField(
            placeholder: AppCopy.text(locale, en: "Deck title", es: "Titulo del mazo"),
            text: $title,
            isFocused: $isTitleFocused,
            returnKeyType: .next,
            autocapitalization: .sentences,
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: UIColor(NColors.Text.textPrimary),
            tintColor: UIColor(NColors.Brand.neuroBlue),
            onSubmit: {
                isTitleFocused = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(80))
                    isDescriptionFocused = true
                }
            }
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isTitleFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
        )
    }

    private var descriptionField: some View {
        NOptimizedTextField(
            placeholder: AppCopy.text(locale, en: "Short description (optional)", es: "Descripcion corta (opcional)"),
            text: $descriptionText,
            isFocused: $isDescriptionFocused,
            returnKeyType: .done,
            autocapitalization: .sentences,
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: UIColor(NColors.Text.textPrimary),
            tintColor: UIColor(NColors.Brand.neuroBlue),
            onSubmit: { isDescriptionFocused = false }
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isDescriptionFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
        )
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleSave() {
        guard canSave else { return }
        pendingSaveRequest = true
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        if isTitleFocused || isDescriptionFocused {
            isTitleFocused = false
            isDescriptionFocused = false
            return
        }

        pendingSaveRequest = false
        performSaveAfterKeyboardDismiss()
    }

    private func handlePendingSaveIfNeeded() {
        guard pendingSaveRequest, isTitleFocused == false, isDescriptionFocused == false else { return }
        pendingSaveRequest = false
        performSaveAfterKeyboardDismiss()
    }

    @MainActor
    private func performSaveAfterKeyboardDismiss() {
        let finalTitle = trimmedTitle
        let finalDescription = trimmedDescription

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))

            isSaving = true
            errorMessage = nil

            onSave(finalTitle, finalDescription)
            isSaving = false

            try? await Task.sleep(for: .milliseconds(80))
            dismiss()
        }
    }
}
