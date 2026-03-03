import SwiftUI

struct NCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(NSpacing.md)
            .background(NColors.Neutrals.surface)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                    .stroke(NColors.Neutrals.border, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
            )
            .shadow(
                color: colorScheme == .light ? NColors.Text.textTertiary.opacity(0.08) : NColors.Text.textTertiary.opacity(0),
                radius: colorScheme == .light ? NSpacing.sm : 0,
                x: 0,
                y: colorScheme == .light ? NSpacing.xs : 0
            )
    }
}
