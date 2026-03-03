import SwiftUI

struct DesignSystemShowcaseView: View {
    @State private var inputValue = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSpacing.lg) {
                typographySection
                buttonsSection
                cardsSection
                chipsSection
                textFieldSection
                progressSection
                statsSection
                emptyStateSection
            }
            .padding(NSpacing.md)
        }
        .background(NColors.Neutrals.background.ignoresSafeArea())
        .navigationTitle("Design Showcase")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var typographySection: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.sm) {
                Text("Display").font(NTypography.display)
                Text("Title").font(NTypography.title)
                Text("Headline").font(NTypography.headline)
                Text("Body").font(NTypography.body)
                Text("Caption").font(NTypography.caption)
            }
            .foregroundStyle(NColors.Text.textPrimary)
        }
    }

    private var buttonsSection: some View {
        NCard {
            VStack(spacing: NSpacing.sm) {
                NButton("Primary", style: .primary) {}
                NButton("Secondary", style: .secondary) {}
                NButton("Ghost", style: .ghost) {}
                NButton("Disabled", style: .primary, isDisabled: true) {}
            }
        }
    }

    private var cardsSection: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                Text("Card")
                    .font(NTypography.headline)
                    .foregroundStyle(NColors.Text.textPrimary)
                Text("Contenedor base del sistema de diseno.")
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textSecondary)
            }
        }
    }

    private var chipsSection: some View {
        NCard {
            HStack(spacing: NSpacing.sm) {
                NChip("Focus", isSelected: true)
                NChip("Calm", isSelected: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var textFieldSection: some View {
        NCard {
            NTextField(title: "Email", text: $inputValue)
        }
    }

    private var progressSection: some View {
        NCard {
            HStack(spacing: NSpacing.md) {
                NProgressRing(progress: 0.24, centerText: "24%")
                NProgressRing(progress: 0.72, centerText: "72%")
                NProgressRing(progress: 1.0, centerText: "100%")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NSpacing.md) {
            NStatTile(value: "7", label: "Streak", systemImage: "flame.fill")
            NStatTile(value: "82%", label: "Focus", systemImage: "brain.head.profile")
        }
    }

    private var emptyStateSection: some View {
        NCard {
            NEmptyState(
                systemImage: "sparkles",
                title: "Nada por ahora",
                message: "Este estado vacio sirve para validar composicion y jerarquia visual.",
                ctaTitle: "Create"
            ) {}
        }
    }
}

#Preview {
    NavigationStack {
        DesignSystemShowcaseView()
    }
}
