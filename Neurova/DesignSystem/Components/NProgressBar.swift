import SwiftUI

struct NProgressBar: View {
    private let progress: Double
    private let height: CGFloat
    private let animationDuration: Double
    private let showsShimmer: Bool
    private let shimmerDuration: Double

    @State private var displayedProgress: Double = 0
    @State private var shimmerPhase: CGFloat = -0.4

    init(
        progress: Double,
        height: CGFloat = 6,
        animationDuration: Double = 0.85,
        showsShimmer: Bool = false,
        shimmerDuration: Double = 1.55
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.animationDuration = max(animationDuration, 0)
        self.showsShimmer = showsShimmer
        self.shimmerDuration = max(shimmerDuration, 0.1)
    }

    var body: some View {
        GeometryReader { proxy in
            let fillWidth = proxy.size.width * displayedProgress

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(NColors.Home.progressTrack)

                Capsule(style: .continuous)
                    .fill(NColors.neuroGradient)
                    .frame(width: fillWidth)
                    .overlay {
                        if showsShimmer, fillWidth > 0 {
                            let highlightWidth = max(20, fillWidth * 0.32)

                            LinearGradient(
                                colors: [
                                    .white.opacity(0),
                                    .white.opacity(0.34),
                                    .white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: highlightWidth)
                            .offset(x: shimmerPhase * (fillWidth + highlightWidth) - highlightWidth)
                            .blendMode(.plusLighter)
                            .mask(
                                Capsule(style: .continuous)
                                    .frame(width: fillWidth)
                            )
                        }
                    }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100))%")
        .onAppear {
            displayedProgress = 0
            withAnimation(.easeInOut(duration: animationDuration)) {
                displayedProgress = progress
            }

            guard showsShimmer else { return }
            shimmerPhase = -0.4
            withAnimation(.linear(duration: shimmerDuration).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.25
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: animationDuration)) {
                displayedProgress = newValue
            }
        }
    }
}
