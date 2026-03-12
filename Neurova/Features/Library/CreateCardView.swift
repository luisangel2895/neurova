import SwiftUI
import UIKit

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let onSave: (String, String) -> Void

    @State private var frontText = ""
    @State private var backText = ""
    @State private var isSaving = false
    @State private var isFrontFocused = false
    @State private var isBackFocused = false
    @State private var pendingSaveRequest = false

    init(onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NSpacing.md) {
                    previewCard
                    frontField
                    backField
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.md)
                .padding(.bottom, NSpacing.md)
            }
            .scrollIndicators(.hidden)
            .background(backgroundView.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppCopy.text(locale, en: "Add Card", es: "Agregar Tarjeta"))
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
                    isFrontFocused = true
                }
            }
            .onChange(of: isFrontFocused) { _, _ in
                handlePendingSaveIfNeeded()
            }
            .onChange(of: isBackFocused) { _, _ in
                handlePendingSaveIfNeeded()
            }
            .onDisappear {
                pendingSaveRequest = false
            }
        }
    }

    private var trimmedFront: String {
        frontText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBack: String {
        backText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        trimmedFront.isEmpty == false && trimmedBack.isEmpty == false && isSaving == false
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
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(NColors.Brand.neuroBlue)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(trimmedFront.isEmpty ? AppCopy.text(locale, en: "Card Preview", es: "Vista previa") : trimmedFront)
                        .font(NTypography.bodyEmphasis.weight(.semibold))
                        .foregroundStyle(NColors.Text.textPrimary)
                        .lineLimit(1)

                    Text(trimmedBack.isEmpty ? AppCopy.text(locale, en: "Front + back answer", es: "Frente + respuesta") : trimmedBack)
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var frontField: some View {
        optimizedField(
            placeholder: AppCopy.text(locale, en: "Front", es: "Frente"),
            text: $frontText,
            isFocused: $isFrontFocused,
            isActive: isFrontFocused,
            returnKeyType: .next
        ) {
            isFrontFocused = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(80))
                isBackFocused = true
            }
        }
    }

    private var backField: some View {
        optimizedField(
            placeholder: AppCopy.text(locale, en: "Back", es: "Reverso"),
            text: $backText,
            isFocused: $isBackFocused,
            isActive: isBackFocused,
            returnKeyType: .done
        ) {
            isBackFocused = false
        }
    }

    private func optimizedField(
        placeholder: String,
        text: Binding<String>,
        isFocused: Binding<Bool>,
        isActive: Bool,
        returnKeyType: UIReturnKeyType,
        onSubmit: @escaping () -> Void
    ) -> some View {
        NOptimizedTextField(
            placeholder: placeholder,
            text: text,
            isFocused: isFocused,
            returnKeyType: returnKeyType,
            autocapitalization: .sentences,
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: UIColor(NColors.Text.textPrimary),
            tintColor: UIColor(NColors.Brand.neuroBlue),
            onSubmit: onSubmit
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isActive ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
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

        if isFrontFocused || isBackFocused {
            isFrontFocused = false
            isBackFocused = false
            return
        }

        pendingSaveRequest = false
        performSaveAfterKeyboardDismiss()
    }

    private func handlePendingSaveIfNeeded() {
        guard pendingSaveRequest, isFrontFocused == false, isBackFocused == false else { return }
        pendingSaveRequest = false
        performSaveAfterKeyboardDismiss()
    }

    @MainActor
    private func performSaveAfterKeyboardDismiss() {
        let finalFront = trimmedFront
        let finalBack = trimmedBack

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            isSaving = true
            onSave(finalFront, finalBack)
            isSaving = false
            try? await Task.sleep(for: .milliseconds(80))
            dismiss()
        }
    }
}
