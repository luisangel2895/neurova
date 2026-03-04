import SwiftUI

struct StudyOptionsSheetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let counts: [StudyCardFilter: Int]
    let onSelect: (StudyCardFilter) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NSpacing.md) {
                    Text(AppCopy.text(locale, en: "Study Options", es: "Opciones de Estudio"))
                        .font(NTypography.title)
                        .foregroundStyle(NColors.Text.textPrimary)

                    VStack(spacing: NSpacing.sm) {
                        ForEach(StudyCardFilter.allCases) { filter in
                            optionRow(for: filter)
                        }
                    }
                }
                .padding(.horizontal, NSpacing.md)
                .padding(.top, NSpacing.lg)
                .padding(.bottom, NSpacing.lg)
            }
            .background(backgroundView.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func optionRow(for filter: StudyCardFilter) -> some View {
        let count = counts[filter, default: 0]
        let isEnabled = count > 0

        return Button {
            guard isEnabled else { return }
            onSelect(filter)
        } label: {
            NCard {
                HStack(alignment: .center, spacing: NSpacing.sm) {
                    VStack(alignment: .leading, spacing: NSpacing.xs) {
                        Text(filter.title(for: locale))
                            .font(NTypography.bodyEmphasis.weight(.semibold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text(isEnabled ? filter.subtitle(for: locale) : AppCopy.text(locale, en: "No cards available", es: "No hay tarjetas disponibles"))
                            .font(NTypography.caption)
                            .foregroundStyle(secondaryTextColor)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Text("\(count)")
                        .font(NTypography.bodyEmphasis.weight(.semibold))
                        .foregroundStyle(isEnabled ? NColors.Brand.neuroBlue : secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isEnabled ? 1 : 0.6)
            }
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Study Options Light") {
    StudyOptionsSheetView(
        counts: [.due: 4, .new: 2, .review: 5, .all: 9],
        onSelect: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Study Options Dark") {
    StudyOptionsSheetView(
        counts: [.due: 4, .new: 0, .review: 5, .all: 9],
        onSelect: { _ in }
    )
    .preferredColorScheme(.dark)
}
