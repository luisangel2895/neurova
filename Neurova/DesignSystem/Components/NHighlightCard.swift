import SwiftUI

struct NHighlightCard<LeadingContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let sectionLabel: String
    let title: String
    let recommendationText: String?
    let subtitle: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    @ViewBuilder let leadingContent: () -> LeadingContent

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(sectionLabel)
                    .font(NTypography.micro.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(NColors.Text.textTertiary)

                HStack(alignment: .center, spacing: NSpacing.md) {
                    leadingContent()

                    VStack(alignment: .leading, spacing: NSpacing.sm) {
                        Text(title)
                            .font(NTypography.bodyEmphasis.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        if let recommendationText, recommendationText.isEmpty == false {
                            Text(recommendationText)
                                .font(NTypography.caption.weight(.semibold))
                                .foregroundStyle(NColors.Brand.neuroBlue)
                        }

                        Text(subtitle)
                            .font(NTypography.caption)
                            .foregroundStyle(secondaryTextColor)

                        Spacer(minLength: 0)

                        NPrimaryButton(primaryActionTitle, action: onPrimaryAction)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 72)
                }

                NSecondaryButton(secondaryActionTitle, action: onSecondaryAction)
                    .padding(.top, NSpacing.sm + 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(sectionLabel), \(title)")
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NHighlightCard Light") {
    NHighlightCard(
        sectionLabel: "ESTUDIA HOY",
        title: "Meta diaria",
        recommendationText: "Deck recomendado: Biología",
        subtitle: "16 / 25 cards completadas",
        primaryActionTitle: "Continuar",
        secondaryActionTitle: "Elegir deck",
        onPrimaryAction: {},
        onSecondaryAction: {}
    ) {
        NProgressRing(progress: 0.64, lineWidth: NSpacing.xs + 3)
            .frame(width: 68, height: 68)
    }
    .padding()
    .background(NColors.Home.backgroundLightTop)
    .preferredColorScheme(.light)
}

#Preview("NHighlightCard Dark") {
    NHighlightCard(
        sectionLabel: "ESTUDIA HOY",
        title: "Meta diaria",
        recommendationText: "Deck recomendado: Biología",
        subtitle: "16 / 25 cards completadas",
        primaryActionTitle: "Continuar",
        secondaryActionTitle: "Elegir deck",
        onPrimaryAction: {},
        onSecondaryAction: {}
    ) {
        NProgressRing(progress: 0.64, lineWidth: NSpacing.xs + 3)
            .frame(width: 68, height: 68)
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
