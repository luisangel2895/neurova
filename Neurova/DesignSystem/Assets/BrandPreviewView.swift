import SwiftUI

struct BrandPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSpacing.lg) {
                colorSection
                textSection
                buttonSection
                logosSection
                mascotSection
            }
            .padding(NSpacing.md)
        }
        .background(NColors.Neutrals.background.ignoresSafeArea())
        .navigationTitle("Brand Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            sectionTitle("Color Tokens")

            HStack(spacing: NSpacing.sm) {
                colorSwatch("Background", color: NColors.Neutrals.background)
                colorSwatch("Surface", color: NColors.Neutrals.surface)
            }

            HStack(spacing: NSpacing.sm) {
                colorSwatch("SurfaceAlt", color: NColors.Neutrals.surfaceAlt)
                colorSwatch("Border", color: NColors.Neutrals.border)
            }
        }
    }

    private var textSection: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                Text("TextPrimary")
                    .font(NTypography.headline)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text("TextSecondary")
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
        }
    }

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            sectionTitle("CTA")
            NButton("Primary Action", style: .primary) {}
        }
    }

    private var logosSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            sectionTitle("Brand")

            NCard {
                VStack(spacing: NSpacing.md) {
                    NImages.Brand.logoMark
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)

                    NImages.Brand.logoPrimary
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)

                    NImages.Brand.logoOutline
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var mascotSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            sectionTitle("Mascot")

            NCard {
                HStack(alignment: .bottom, spacing: NSpacing.lg) {
                    NImages.Mascot.neruDefault
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    NImages.Mascot.neruHappy
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: NSpacing.xs) {
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .fill(color)
                .frame(height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                        .stroke(NColors.Neutrals.border, lineWidth: 1)
                )

            Text(name)
                .font(NTypography.caption)
                .foregroundStyle(NColors.Text.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(NTypography.headline)
            .foregroundStyle(NColors.Text.textPrimary)
    }
}

#Preview("Light") {
    NavigationStack {
        BrandPreviewView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        BrandPreviewView()
    }
    .preferredColorScheme(.dark)
}
