import SwiftUI

struct NSecondaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NTypography.caption.weight(.semibold))
                .foregroundStyle(NColors.Button.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                        .fill(NColors.Button.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                        .stroke(NColors.Button.secondaryBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
