import SwiftUI

struct NProgressBar: View {
    private let progress: Double
    private let height: CGFloat

    init(progress: Double, height: CGFloat = 6) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(NColors.Home.progressTrack)

                Capsule(style: .continuous)
                    .fill(NColors.neuroGradient)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: height)
    }
}
