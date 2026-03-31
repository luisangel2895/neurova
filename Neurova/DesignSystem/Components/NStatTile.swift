import SwiftUI

struct NStatTile: View {
    private let value: String
    private let label: String
    private let systemImage: String?

    init(value: String, label: String, systemImage: String? = nil) {
        self.value = value
        self.label = label
        self.systemImage = systemImage
    }

    var body: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(NTypography.caption)
                        .foregroundStyle(NColors.Brand.neuroBlue)
                }

                Text(value)
                    .font(NTypography.title)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(label)
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label): \(value)")
        }
    }
}
