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
                    .stroke(NColors.Home.cardBorder, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                    .inset(by: 1)
                    .stroke(colorScheme == .dark ? NColors.Home.cardInnerBorder : .clear, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [NColors.Home.cardTopHighlight, .clear]
                                : [.clear, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
            )
            .shadow(
                color: colorScheme == .light ? NColors.Text.textTertiary.opacity(0.1) : NColors.Text.textTertiary.opacity(0),
                radius: colorScheme == .light ? NSpacing.sm + 2 : 0,
                x: 0,
                y: colorScheme == .light ? NSpacing.xs + 1 : 0
            )
    }
}
