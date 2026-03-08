import SwiftUI
import UIKit

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let deck: Deck?
    private let onSave: (String, String?) -> Void

    private enum Field: Hashable {
        case title
        case description
    }

    @FocusState private var focusedField: Field?
    @State private var title: String
    @State private var descriptionText: String
    @State private var isSaving = false

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
                    titleField
                    descriptionField
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(deck == nil ? AppCopy.text(locale, en: "Create Deck", es: "Crear Mazo") : AppCopy.text(locale, en: "Edit Deck", es: "Editar Mazo"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.text(locale, en: "Cancel", es: "Cancelar")) {
                        dismiss()
                    }
                    .foregroundStyle(NColors.Text.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.text(locale, en: "Save", es: "Guardar")) {
                        handleSave()
                    }
                    .disabled(canSave == false)
                    .foregroundStyle(canSave ? NColors.Brand.neuroBlue : NColors.Text.textSecondary)
                }
            }
            .onAppear {
                focusedField = .title
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

    private var titleField: some View {
        NOptimizedTextField(
            placeholder: AppCopy.text(locale, en: "Deck title", es: "Titulo del mazo"),
            text: $title,
            isFocused: titleFocusBinding,
            returnKeyType: .next,
            autocapitalization: .sentences,
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: UIColor(NColors.Text.textPrimary),
            tintColor: UIColor(NColors.Brand.neuroBlue),
            onSubmit: { focusedField = .description }
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(focusedField == .title ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
        )
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(AppCopy.text(locale, en: "Description (optional)", es: "Descripcion (opcional)"))
                .font(NTypography.caption)
                .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)

            NOptimizedTextField(
                placeholder: AppCopy.text(locale, en: "Add a short description", es: "Agrega una descripcion corta"),
                text: $descriptionText,
                isFocused: descriptionFocusBinding,
                returnKeyType: .done,
                autocapitalization: .sentences,
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: UIColor(NColors.Text.textPrimary),
                tintColor: UIColor(NColors.Brand.neuroBlue),
                onSubmit: { focusedField = nil }
            )
            .font(NTypography.body)
            .foregroundStyle(NColors.Text.textPrimary)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 48)
            .background(NColors.Neutrals.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(focusedField == .description ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
            )
        }
    }

    private var titleFocusBinding: Binding<Bool> {
        Binding(
            get: { focusedField == .title },
            set: { isFocused in
                focusedField = isFocused ? .title : (focusedField == .title ? nil : focusedField)
            }
        )
    }

    private var descriptionFocusBinding: Binding<Bool> {
        Binding(
            get: { focusedField == .description },
            set: { isFocused in
                focusedField = isFocused ? .description : (focusedField == .description ? nil : focusedField)
            }
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
        isSaving = true
        focusedField = nil
        onSave(trimmedTitle, trimmedDescription)
        dismiss()
    }
}
