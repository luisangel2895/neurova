import SwiftUI

struct NEmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String
    private let ctaTitle: String?
    private let ctaAction: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaAction: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaAction = ctaAction
    }

    var body: some View {
        VStack(spacing: NSpacing.md) {
            Image(systemName: systemImage)
                .font(NTypography.title)
                .foregroundStyle(NColors.Brand.neuroBlue)

            Text(title)
                .font(NTypography.headline)
                .foregroundStyle(NColors.Text.textPrimary)

            Text(message)
                .font(NTypography.body)
                .foregroundStyle(NColors.Text.textSecondary)
                .multilineTextAlignment(.center)

            if let ctaTitle, let ctaAction {
                NButton(ctaTitle, style: .primary, action: ctaAction)
                    .frame(maxWidth: 220)
            }
        }
        .padding(NSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}
