import SwiftUI

struct NStatCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                Image(systemName: systemImage)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(iconColor)

                Spacer(minLength: 0)

                Text(value)
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(label)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NStatCard Light") {
    NStatCard(systemImage: "flame", iconColor: NColors.Feedback.warning, value: "7", label: "Racha")
        .padding()
        .background(NColors.Home.backgroundLightTop)
        .preferredColorScheme(.light)
}

#Preview("NStatCard Dark") {
    NStatCard(systemImage: "flame", iconColor: NColors.Feedback.warning, value: "7", label: "Racha")
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
