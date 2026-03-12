import SwiftUI
import UIKit

struct CreateSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let subject: Subject?
    private let onSave: (String, String?, String?) throws -> Void

    @State private var isNameFocused = false
    @State private var name: String
    @State private var selectedSymbolName: String
    @State private var selectedColorToken: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let symbolColumns = Array(repeating: GridItem(.flexible(), spacing: NSpacing.xs), count: 5)

    init(
        subject: Subject? = nil,
        onSave: @escaping (String, String?, String?) throws -> Void
    ) {
        self.subject = subject
        self.onSave = onSave

        let fallbackSymbol = "book.closed"
        let fallbackColor = NColors.SubjectIcon.palette.first?.token ?? "NeuroBlue"
        _name = State(initialValue: subject?.name ?? "")
        _selectedSymbolName = State(initialValue: subject?.systemImageName ?? fallbackSymbol)
        _selectedColorToken = State(initialValue: subject?.colorTokenReference ?? fallbackColor)
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

                    nameField
                    previewCard
                    colorPickerCard
                    iconPickerCard
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
                        subject == nil
                            ? AppCopy.text(locale, en: "Create Subject", es: "Crear Materia")
                            : AppCopy.text(locale, en: "Edit Subject", es: "Editar Materia")
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
                isNameFocused = true
            }
        }
    }

    private var nameField: some View {
        NOptimizedTextField(
            placeholder: AppCopy.text(locale, en: "Subject name", es: "Nombre de la materia"),
            text: $name,
            isFocused: $isNameFocused,
            returnKeyType: .done,
            autocapitalization: .words,
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: UIColor(NColors.Text.textPrimary),
            tintColor: UIColor(NColors.Brand.neuroBlue),
            onSubmit: { isNameFocused = false }
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(
                    isNameFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))
    }

    private var previewCard: some View {
        NCard {
            HStack(spacing: NSpacing.sm) {
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .fill(NColors.SubjectIcon.color(for: selectedColorToken).opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: selectedSymbolName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(NColors.SubjectIcon.color(for: selectedColorToken))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(trimmedName.isEmpty ? AppCopy.text(locale, en: "Subject Preview", es: "Vista previa de materia") : trimmedName)
                        .font(NTypography.bodyEmphasis.weight(.semibold))
                        .foregroundStyle(NColors.Text.textPrimary)
                    Text(AppCopy.text(locale, en: "Icon + color selection", es: "Selección de icono + color"))
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                }

                Spacer()
            }
        }
    }

    private var colorPickerCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(AppCopy.text(locale, en: "Choose icon color", es: "Elige color del icono"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                ScrollView(.horizontal) {
                    HStack(spacing: NSpacing.sm) {
                        ForEach(NColors.SubjectIcon.palette) { option in
                            Button {
                                selectedColorToken = option.token
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColorToken == option.token ? NColors.Text.textPrimary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var iconPickerCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text(AppCopy.text(locale, en: "Choose icon", es: "Elige icono"))
                    .font(NTypography.bodyEmphasis.weight(.semibold))
                    .foregroundStyle(NColors.Text.textPrimary)

                ScrollView {
                    LazyVGrid(columns: symbolColumns, spacing: NSpacing.xs) {
                        ForEach(Self.topSubjectSymbols, id: \.self) { symbol in
                            Button {
                                selectedSymbolName = symbol
                            } label: {
                                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                    .fill(
                                        selectedSymbolName == symbol
                                            ? NColors.SubjectIcon.color(for: selectedColorToken).opacity(0.14)
                                            : NColors.Neutrals.surfaceAlt
                                    )
                                    .frame(height: 44)
                                    .overlay {
                                        Image(systemName: symbol)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(
                                                selectedSymbolName == symbol
                                                    ? NColors.SubjectIcon.color(for: selectedColorToken)
                                                    : NColors.Text.textSecondary
                                            )
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                                            .stroke(
                                                selectedSymbolName == symbol ? NColors.SubjectIcon.color(for: selectedColorToken) : NColors.Neutrals.border,
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 300)
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        trimmedName.isEmpty == false && isSaving == false
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private func handleSave() {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        isNameFocused = false

        do {
            try onSave(trimmedName, selectedSymbolName, selectedColorToken)
            isSaving = false
            DispatchQueue.main.async {
                dismiss()
            }
        } catch {
            isSaving = false
            errorMessage = AppCopy.text(
                locale,
                en: "Unable to save subject: \(error.localizedDescription)",
                es: "No se pudo guardar la materia: \(error.localizedDescription)"
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

private extension CreateSubjectView {
    static let topSubjectSymbols: [String] = [
        "book.closed", "books.vertical", "text.book.closed", "bookmark", "graduationcap",
        "studentdesk", "pencil", "pencil.and.ruler", "doc.text", "note.text",
        "list.bullet.rectangle", "folder", "tray.full", "archivebox", "paperclip",
        "brain", "lightbulb", "sparkles", "target", "scope",
        "flag", "star", "medal", "bolt", "flame",
        "clock", "calendar", "hourglass", "timer", "chart.bar",
        "chart.line.uptrend.xyaxis", "chart.pie", "waveform.path.ecg", "waveform", "cpu",
        "desktopcomputer", "laptopcomputer", "keyboard", "gamecontroller", "headphones",
        "music.note", "guitars", "mic", "camera", "video",
        "photo", "film", "tv", "newspaper", "globe",
        "globe.americas", "location", "map", "mappin", "airplane",
        "car", "bicycle", "tram", "shippingbox", "cart",
        "bag", "creditcard", "dollarsign.circle", "banknote", "building.2",
        "house", "bed.double", "fork.knife", "cup.and.saucer", "leaf",
        "tree", "drop", "sun.max", "moon", "cloud",
        "snowflake", "hare", "tortoise", "pawprint", "fish",
        "ant", "ladybug", "bird", "dog", "cat",
        "heart", "cross.case", "bandage", "stethoscope", "pills",
        "atom", "function", "sum", "percent", "infinity",
        "ruler", "compass.drawing", "paintpalette", "hammer", "wrench.and.screwdriver"
    ]
}
