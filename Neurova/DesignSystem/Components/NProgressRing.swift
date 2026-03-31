import SwiftUI

struct NProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let centerText: String?
    private let animationDuration: Double

    init(
        progress: Double,
        lineWidth: CGFloat = NSpacing.sm,
        centerText: String? = nil,
        animationDuration: Double = 0.35
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.centerText = centerText
        self.animationDuration = max(animationDuration, 0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(NColors.Neutrals.border, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    NColors.neuroGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: animationDuration), value: progress)

            if let centerText {
                Text(centerText)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Text.textPrimary)
            }
        }
        .frame(width: 92, height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(centerText ?? "\(Int(progress * 100))%")
    }
}
