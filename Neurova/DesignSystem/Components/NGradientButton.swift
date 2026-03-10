import SwiftUI

struct NGradientButton: View {
    @Environment(\.colorScheme) private var colorScheme

    private let title: String
    private let leadingSymbolName: String?
    private let showsChevron: Bool
    private let animateEffects: Bool
    private let font: Font
    private let height: CGFloat
    private let cornerRadius: CGFloat
    private let action: () -> Void

    init(
        _ title: String,
        leadingSymbolName: String? = nil,
        showsChevron: Bool = false,
        animateEffects: Bool = true,
        font: Font = .system(size: 18, weight: .semibold, design: .rounded),
        height: CGFloat = 58,
        cornerRadius: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.leadingSymbolName = leadingSymbolName
        self.showsChevron = showsChevron
        self.animateEffects = animateEffects
        self.font = font
        self.height = height
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leadingSymbolName {
                    Image(systemName: leadingSymbolName)
                        .font(.system(size: 14, weight: .regular))
                }

                Text(title)
                    .font(font)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .regular))
                }
            }
            .foregroundStyle(NColors.Button.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: NColors.Brand.primaryButtonColors(for: colorScheme),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if animateEffects {
                    TimelineView(.animation) { timeline in
                        GeometryReader { proxy in
                            let width = proxy.size.width
                            let tickTime = timeline.date.timeIntervalSinceReferenceDate
                            let phase = (tickTime / 2.15).truncatingRemainder(dividingBy: 1.0)
                            let shinePhase = -1.45 + (2.9 * phase)
                            let xOffset = width * shinePhase

                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(.clear)
                                .overlay(
                                    Ellipse()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .clear,
                                                    Color.white.opacity(0.10),
                                                    Color.white.opacity(0.30),
                                                    Color.white.opacity(0.10),
                                                    .clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 188, height: 126)
                                        .rotationEffect(.degrees(20))
                                        .blur(radius: 9)
                                        .offset(x: xOffset)
                                )
                                .blendMode(.screen)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
    }
}
