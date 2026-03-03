import SwiftUI

struct NTextField: View {
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    private let title: String

    init(title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }

    var body: some View {
        TextField(title, text: $text)
            .font(NTypography.body)
            .foregroundStyle(NColors.Text.textPrimary)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 48)
            .background(NColors.Neutrals.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                    .stroke(isFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
            )
            .focused($isFocused)
            .tint(NColors.Brand.neuroBlue)
    }
}
