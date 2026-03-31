import SwiftUI

struct NInfoCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let sectionLabel: String
    let chips: [String]
    let title: String
    let description: String
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(sectionLabel)
                    .font(NTypography.micro.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(NColors.Text.textTertiary)

                HStack(spacing: NSpacing.xs) {
                    ForEach(chips, id: \.self) { chip in
                        NChip(chip, isSelected: false)
                            .scaleEffect(0.9)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(NTypography.caption.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(description)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.top, -2)
                    .fixedSize(horizontal: false, vertical: true)

                NSecondaryButton(actionTitle, action: onAction)
                    .padding(.top, NSpacing.xs)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(sectionLabel), \(title)")
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}

#Preview("NInfoCard Light") {
    NInfoCard(
        sectionLabel: "RECOMENDADO PARA TI",
        chips: ["Repaso", "Débil", "Nuevo"],
        title: "Biología Celular – Mitosis",
        description: "12 cards débiles detectadas. Refuerza antes de tu examen.",
        actionTitle: "Comenzar repaso",
        onAction: {}
    )
    .padding()
    .background(NColors.Home.backgroundLightTop)
    .preferredColorScheme(.light)
}

#Preview("NInfoCard Dark") {
    NInfoCard(
        sectionLabel: "RECOMENDADO PARA TI",
        chips: ["Repaso", "Débil", "Nuevo"],
        title: "Biología Celular – Mitosis",
        description: "12 cards débiles detectadas. Refuerza antes de tu examen.",
        actionTitle: "Comenzar repaso",
        onAction: {}
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
