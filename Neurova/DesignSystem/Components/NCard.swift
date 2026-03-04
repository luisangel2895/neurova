import SwiftUI

struct NCard<Content: View>: View {
    enum SurfaceLevel {
        case l1
        case l2
    }

    enum PaddingStyle {
        case content
        case compact
        case none
    }

    @Environment(\.colorScheme) private var colorScheme

    private let surfaceLevel: SurfaceLevel
    private let paddingStyle: PaddingStyle
    private let showsStroke: Bool
    private let usesShadow: Bool
    private let content: Content

    init(
        surfaceLevel: SurfaceLevel = .l1,
        paddingStyle: PaddingStyle = .content,
        showsStroke: Bool = true,
        usesShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.surfaceLevel = surfaceLevel
        self.paddingStyle = paddingStyle
        self.showsStroke = showsStroke
        self.usesShadow = usesShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                    .stroke(showsStroke ? NColors.Home.cardBorder : .clear, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
                    .inset(by: 1)
                    .stroke(colorScheme == .dark && showsStroke ? NColors.Home.cardInnerBorder : .clear, lineWidth: 1)
                    .allowsHitTesting(false)
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
                    .allowsHitTesting(false)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.card, style: .continuous)
            )
            .shadow(
                color: colorScheme == .light && usesShadow ? NColors.Home.cardShadowLight : .clear,
                radius: colorScheme == .light && usesShadow ? NSpacing.sm + 2 : 0,
                x: 0,
                y: colorScheme == .light && usesShadow ? NSpacing.xs + 1 : 0
            )
    }

    private var backgroundColor: Color {
        switch surfaceLevel {
        case .l1:
            return NColors.Home.surfaceL1
        case .l2:
            return NColors.Home.surfaceL2
        }
    }

    private var contentPadding: CGFloat {
        switch paddingStyle {
        case .content:
            return NSpacing.md
        case .compact:
            return NSpacing.sm + NSpacing.xs
        case .none:
            return 0
        }
    }
}
