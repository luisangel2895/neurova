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
            .font(NTypography.caption.weight(.semibold))
            .foregroundStyle(isSelected ? NColors.Brand.accentBlue : NColors.Text.textSecondary)
            .padding(.horizontal, NSpacing.md)
            .frame(height: 32)
            .background(isSelected ? NColors.Button.chipSelectedBackground : NColors.Button.chipBackground)
            .overlay(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
                    .stroke(isSelected ? NColors.Button.chipSelectedBorder : NColors.Button.secondaryBorder, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: NRadius.chip, style: .continuous)
            )
    }
}
