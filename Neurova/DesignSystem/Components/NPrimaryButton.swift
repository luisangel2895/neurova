import SwiftUI

struct NPrimaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        NGradientButton(
            title,
            animateEffects: true,
            font: NTypography.bodyEmphasis.weight(.bold),
            height: 44,
            cornerRadius: NRadius.button,
            action: action
        )
    }
}
