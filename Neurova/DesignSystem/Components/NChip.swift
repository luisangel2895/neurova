import SwiftUI

struct NChip: View {
    private let title: String
    private let isSelected: Bool

    init(_ title: String, isSelected: Bool) {
        self.title = title
        self.isSelected = isSelected
    }

    var body: some View {
        Text(title)
            .font(NTypography.caption)
            .foregroundStyle(isSelected ? NColors.Neutrals.background : NColors.Text.textSecondary)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 32)
            .background(isSelected ? NColors.Brand.neuroBlue : NColors.Neutrals.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
                    .stroke(isSelected ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
            )
    }
}
