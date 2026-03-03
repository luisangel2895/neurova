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
                .font(NTypography.caption.weight(.medium))
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
    }
}
