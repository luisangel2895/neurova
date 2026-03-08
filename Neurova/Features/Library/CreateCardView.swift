import SwiftUI

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let onSave: (String, String) -> Void

    private enum Field: Hashable {
        case front
        case back
    }

    @FocusState private var focusedField: Field?
    @State private var frontText: String = ""
    @State private var backText: String = ""

    init(onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    multilineField(
                        title: AppCopy.text(locale, en: "Front", es: "Frente"),
                        text: $frontText,
                        field: .front
                    )
                    multilineField(
                        title: AppCopy.text(locale, en: "Back", es: "Reverso"),
                        text: $backText,
                        field: .back
                    )
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(AppCopy.text(locale, en: "Add Card", es: "Agregar Tarjeta"))
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
                        onSave(trimmedFront, trimmedBack)
                        dismiss()
                    }
                    .disabled(trimmedFront.isEmpty || trimmedBack.isEmpty)
                    .foregroundStyle(saveButtonColor)
                }
            }
            .onAppear {
                focusedField = .front
            }
        }
    }

    private var trimmedFront: String {
        frontText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBack: String {
        backText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var saveButtonColor: Color {
        trimmedFront.isEmpty || trimmedBack.isEmpty ? NColors.Text.textSecondary : NColors.Brand.neuroBlue
    }

    private func multilineField(title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(title)
                .font(NTypography.caption)
                .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)

            TextEditor(text: text)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textPrimary)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.sentences)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .focused($focusedField, equals: field)
                .padding(NSpacing.sm)
                .background(NColors.Home.surfaceL1)
                .overlay(
                    RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                        .stroke(NColors.Home.cardBorder, lineWidth: 1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                )
        }
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
}
