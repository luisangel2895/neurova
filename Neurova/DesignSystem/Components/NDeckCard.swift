import SwiftUI

struct NDeckCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let accentColor: Color
    let iconName: String
    let contextText: String?
    let title: String
    let cardCountText: String

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor.opacity(0.2))
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 28, height: 28)

                Spacer(minLength: 0)

                if let contextText, contextText.isEmpty == false {
                    Text(contextText)
                        .font(NTypography.micro.weight(.semibold))
                        .foregroundStyle(NColors.Text.textTertiary)
                        .lineLimit(1)
                }

                Text(title)
                    .font(NTypography.caption.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(2)

                Text(cardCountText)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(width: 122, height: 92, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title), \(cardCountText)")
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NDeckCard Light") {
    NDeckCard(
        accentColor: NColors.Brand.neuroBlue,
        iconName: "book.closed",
        contextText: "Biología",
        title: "Anatomía",
        cardCountText: "58 cards"
    )
        .padding()
        .background(NColors.Home.backgroundLightTop)
        .preferredColorScheme(.light)
}

#Preview("NDeckCard Dark") {
    NDeckCard(
        accentColor: NColors.Brand.neuroBlue,
        iconName: "book.closed",
        contextText: "Biología",
        title: "Anatomía",
        cardCountText: "58 cards"
    )
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
