import SwiftUI

struct NProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let centerText: String?

    init(
        progress: Double,
        lineWidth: CGFloat = NSpacing.sm,
        centerText: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.centerText = centerText
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
                .animation(.easeInOut(duration: 0.35), value: progress)

            if let centerText {
                Text(centerText)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Text.textPrimary)
            }
        }
        .frame(width: 92, height: 92)
    }
}
