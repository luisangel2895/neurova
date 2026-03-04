import SwiftUI

struct InsightsSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            Text(title)
                .font(NTypography.bodyEmphasis.weight(.semibold))
                .foregroundStyle(NColors.Text.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(NTypography.caption)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
