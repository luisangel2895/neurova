import SwiftUI

struct NDeckCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let accentColor: Color
    let title: String
    let cardCountText: String

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 28, height: 28)

                Spacer(minLength: 0)

                Text(title)
                    .font(NTypography.caption.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(2)

                Text(cardCountText)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(width: 104, height: 78, alignment: .leading)
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NDeckCard Light") {
    NDeckCard(accentColor: NColors.Brand.neuroBlue, title: "Anatomía", cardCountText: "58 cards")
        .padding()
        .background(NColors.Home.backgroundLightTop)
        .preferredColorScheme(.light)
}

#Preview("NDeckCard Dark") {
    NDeckCard(accentColor: NColors.Brand.neuroBlue, title: "Anatomía", cardCountText: "58 cards")
        .padding()
        .background(
            LinearGradient(
                colors: [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.dark)
}
