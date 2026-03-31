import SwiftUI

struct NTipCard<LeadingContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let bodyText: String
    private let showsTypewriter: Bool
    @ViewBuilder let leadingContent: () -> LeadingContent

    @State private var visibleCharacterCount: Int = 0

    init(
        title: String,
        bodyText: String,
        showsTypewriter: Bool = false,
        @ViewBuilder leadingContent: @escaping () -> LeadingContent
    ) {
        self.title = title
        self.bodyText = bodyText
        self.showsTypewriter = showsTypewriter
        self.leadingContent = leadingContent
    }

    var body: some View {
        NCard {
            HStack(alignment: .center, spacing: NSpacing.sm + NSpacing.xs) {
                leadingContent()

                VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                    Text(title)
                        .font(NTypography.caption.weight(.bold))
                        .foregroundStyle(NColors.Text.textPrimary)

                    Text(displayedBodyText)
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title): \(bodyText)")
        }
        .task(id: bodyText) {
            await animateBodyText()
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var displayedBodyText: String {
        guard showsTypewriter else { return bodyText }
        guard visibleCharacterCount > 0 else { return "" }
        return String(bodyText.prefix(visibleCharacterCount))
    }

    private func animateBodyText() async {
        guard showsTypewriter else {
            visibleCharacterCount = bodyText.count
            return
        }

        visibleCharacterCount = 0
        let characters = Array(bodyText)
        guard characters.isEmpty == false else { return }

        for index in characters.indices {
            if Task.isCancelled { return }
            visibleCharacterCount = index + 1

            let current = characters[index]
            let nanos: UInt64
            switch current {
            case ".", "!", "?", ",":
                nanos = 260_000_000
            case " ":
                nanos = 70_000_000
            default:
                nanos = 95_000_000
            }
            try? await Task.sleep(nanoseconds: nanos)
        }
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
