import SwiftUI

struct NPrimaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NTypography.bodyEmphasis.weight(.bold))
                .foregroundStyle(NColors.Neutrals.background)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                        .fill(NColors.neuroGradient)
                )
        }
        .buttonStyle(.plain)
    }
}
