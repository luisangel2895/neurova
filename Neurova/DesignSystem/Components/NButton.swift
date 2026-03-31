import SwiftUI

struct NButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
    }

    private let title: String
    private let style: Style
    private let isDisabled: Bool
    private let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Group {
            if style == .primary {
                NGradientButton(
                    title,
                    animateEffects: true,
                    font: NTypography.bodyEmphasis.weight(.semibold),
                    height: 52,
                    cornerRadius: NRadius.button,
                    action: action
                )
            } else {
                Button(action: action) {
                    Text(title)
                        .font(NTypography.bodyEmphasis)
                        .foregroundStyle(foregroundColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(backgroundView)
                        .overlay(borderView)
                        .clipShape(
                            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .disabled(isDisabled)
        .allowsHitTesting(!isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(Color.clear)
        case .secondary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(NColors.Button.secondaryBackground)
        case .ghost:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(Color.clear)
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(Color.clear, lineWidth: 0)
        case .secondary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(NColors.Button.secondaryBorder, lineWidth: 1)
        case .ghost:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(Color.clear, lineWidth: 0)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return NColors.Button.primaryText
        case .secondary:
            return NColors.Text.textPrimary
        case .ghost:
            return NColors.Brand.neuroBlue
        }
    }
}
