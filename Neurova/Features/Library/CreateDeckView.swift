import SwiftUI

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let deck: Deck?
    private let onSave: (String, String?, Bool) -> Void

    @FocusState private var isTitleFocused: Bool
    @State private var title: String
    @State private var descriptionText: String
    @State private var isArchived: Bool
    @State private var isSaving = false

    init(
        deck: Deck? = nil,
        onSave: @escaping (String, String?, Bool) -> Void
    ) {
        self.deck = deck
        self.onSave = onSave
        _title = State(initialValue: deck?.title ?? "")
        _descriptionText = State(initialValue: deck?.description ?? "")
        _isArchived = State(initialValue: deck?.isArchived ?? false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    titleField
                    multilineField(title: "Description (optional)", text: $descriptionText)

                    Toggle(isOn: $isArchived) {
                        Text("Archived")
                            .font(NTypography.body)
                            .foregroundStyle(NColors.Text.textPrimary)
                    }
                    .tint(NColors.Brand.neuroBlue)
                    .padding(NSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                            .fill(NColors.Home.surfaceL1)
                    )
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationTitle(deck == nil ? "Create Deck" : "Edit Deck")
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
                isTitleFocused = true
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
        TextField("Deck title", text: $title)
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
            .focused($isTitleFocused)
            .submitLabel(.done)
            .tint(NColors.Brand.neuroBlue)
            .onSubmit {
                handleSave()
            }
    }

    private func multilineField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(title)
                .font(NTypography.caption)
                .foregroundStyle(colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark)

            TextEditor(text: text)
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

    private func handleSave() {
        guard canSave else { return }
        isSaving = true
        isTitleFocused = false
        onSave(trimmedTitle, trimmedDescription, isArchived)
        dismiss()
    }
}
