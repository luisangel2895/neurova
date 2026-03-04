import SwiftUI
import UIKit

struct CreateSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let subject: Subject?
    private let onSave: (String, String?) -> Void

    @FocusState private var focusedField: Field?
    @State private var name: String
    @State private var systemImageName: String
    @State private var isSaving = false

    private enum Field {
        case name
        case symbol
    }

    init(
        subject: Subject? = nil,
        onSave: @escaping (String, String?) -> Void
    ) {
        self.subject = subject
        self.onSave = onSave
        _name = State(initialValue: subject?.name ?? "")
        _systemImageName = State(initialValue: subject?.systemImageName ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    inputField(
                        title: "Subject name",
                        text: $name,
                        field: .name,
                        submitLabel: .next
                    )

                    VStack(alignment: .leading, spacing: NSpacing.xs) {
                        inputField(
                            title: "SF Symbol (optional)",
                            text: $systemImageName,
                            field: .symbol,
                            submitLabel: .done
                        )

                        Text("Example: book, leaf, brain, graduationcap")
                            .font(NTypography.caption)
                            .foregroundStyle(secondaryTextColor)

                        if let previewSymbolName {
                            HStack(spacing: NSpacing.sm) {
                                Image(systemName: previewSymbolName)
                                    .font(NTypography.bodyEmphasis)
                                    .foregroundStyle(NColors.Brand.neuroBlue)

                                Text("Preview")
                                    .font(NTypography.caption)
                                    .foregroundStyle(secondaryTextColor)
                            }
                            .padding(NSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                                    .fill(NColors.Home.surfaceL1)
                            )
                        }
                    }
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(subject == nil ? "Create Subject" : "Edit Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NColors.Text.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(canSave == false)
                    .foregroundStyle(canSave ? NColors.Brand.neuroBlue : NColors.Text.textSecondary)
                }
            }
            .onAppear {
                focusedField = .name
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedIconName: String? {
        let trimmed = systemImageName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var canSave: Bool {
        trimmedName.isEmpty == false && isSaving == false
    }

    private var previewSymbolName: String? {
        guard let trimmedIconName else { return nil }
        return UIImage(systemName: trimmedIconName) == nil ? nil : trimmedIconName
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        field: Field,
        submitLabel: SubmitLabel
    ) -> some View {
        TextField(title, text: text)
            .font(NTypography.body)
            .foregroundStyle(NColors.Text.textPrimary)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 48)
            .background(NColors.Neutrals.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(
                        focusedField == field ? NColors.Brand.neuroBlue : NColors.Neutrals.border,
                        lineWidth: 1
                    )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
            )
            .focused($focusedField, equals: field)
            .submitLabel(submitLabel)
            .tint(NColors.Brand.neuroBlue)
            .onSubmit {
                switch field {
                case .name:
                    focusedField = .symbol
                case .symbol:
                    handleSave()
                }
            }
    }

    private func handleSave() {
        guard canSave else { return }
        isSaving = true
        focusedField = nil
        onSave(trimmedName, trimmedIconName)
        dismiss()
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
