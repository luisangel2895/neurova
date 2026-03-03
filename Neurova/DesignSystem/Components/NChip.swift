import SwiftUI

struct NChip: View {
    @Environment(\.colorScheme) private var colorScheme

    private let title: String
    private let isSelected: Bool

    init(_ title: String, isSelected: Bool) {
        self.title = title
        self.isSelected = isSelected
    }

    var body: some View {
        Text(title)
            .font(NTypography.caption)
            .foregroundStyle(isSelected ? NColors.Neutrals.background : secondaryTextColor)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 32)
            .background(isSelected ? NColors.Brand.neuroBlue : NColors.Home.surfaceL2)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
                    .stroke(isSelected ? NColors.Brand.neuroBlue : NColors.Home.layeredStroke, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
            )
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }
}
