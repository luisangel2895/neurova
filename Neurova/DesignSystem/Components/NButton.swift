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
        .disabled(isDisabled)
        .allowsHitTesting(!isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(NColors.neuroGradient)
        case .secondary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(NColors.Neutrals.surface)
        case .ghost:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(NColors.Neutrals.background)
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(NColors.Brand.neuroBlue, lineWidth: 0)
        case .secondary:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(NColors.Neutrals.border, lineWidth: 1)
        case .ghost:
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .strokeBorder(NColors.Neutrals.border, lineWidth: 0)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return NColors.Neutrals.background
        case .secondary:
            return NColors.Text.textPrimary
        case .ghost:
            return NColors.Brand.neuroBlue
        }
    }
}
