import SwiftUI

struct NTipCard<LeadingContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let bodyText: String
    @ViewBuilder let leadingContent: () -> LeadingContent

    var body: some View {
        NCard {
            HStack(alignment: .center, spacing: NSpacing.sm + NSpacing.xs) {
                leadingContent()

                VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                    Text(title)
                        .font(NTypography.caption.weight(.bold))
                        .foregroundStyle(NColors.Text.textPrimary)

                    Text(bodyText)
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NTipCard Light") {
    NTipCard(title: "Tip de Neurova", bodyText: "Estudiar en sesiones de 25 minutos con pausas mejora la retención.") {
        NImages.Brand.logoMark
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
    }
    .padding()
    .background(NColors.Home.backgroundLightTop)
    .preferredColorScheme(.light)
}

#Preview("NTipCard Dark") {
    NTipCard(title: "Tip de Neurova", bodyText: "Estudiar en sesiones de 25 minutos con pausas mejora la retención.") {
        NImages.Brand.logoMark
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
    }
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
