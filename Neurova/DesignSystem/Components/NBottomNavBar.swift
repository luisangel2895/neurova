import SwiftUI

enum NBottomNavItem: CaseIterable, Identifiable {
    case home
    case library
    case insights
    case profile

    var id: Self { self }

    func title(for locale: Locale) -> String {
        switch self {
        case .home:
            return AppCopy.text(locale, en: "Home", es: "Inicio")
        case .library:
            return AppCopy.text(locale, en: "Library", es: "Biblioteca")
        case .insights:
            return AppCopy.text(locale, en: "Insights", es: "Insights")
        case .profile:
            return AppCopy.text(locale, en: "Profile", es: "Perfil")
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .library:
            return "books.vertical"
        case .insights:
            return "chart.bar"
        case .profile:
            return "person"
        }
    }
}

struct NBottomNavBar: View {
    @Binding var selectedTab: NBottomNavItem
    let onSelect: (NBottomNavItem) -> Void
    let onScanTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private enum Metrics {
        static let barHeight: CGFloat = 88
        static let fabSize: CGFloat = 60
        static let fabLift: CGFloat = 39
        static let iconSize: CGFloat = 23
        static let tabHitSize: CGFloat = 44
        static let activeScale: CGFloat = 1.04
    }

    var body: some View {
        ZStack(alignment: .top) {
            NotchedTabBarShape()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .light ? 0.84 : 0.78)
                .overlay(
                    NotchedTabBarShape()
                        .fill(
                            NColors.Neutrals.surface.opacity(colorScheme == .light ? 0.26 : 0.18)
                        )
                )
                .overlay(
                    NotchedTabBarShape()
                        .stroke(NColors.Neutrals.border.opacity(colorScheme == .light ? 0.68 : 0.58), lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .light
                        ? NColors.Text.textTertiary.opacity(0.14)
                        : NColors.Brand.neuroBlueDeep.opacity(0.18),
                    radius: colorScheme == .light ? NSpacing.md : NSpacing.sm,
                    x: 0,
                    y: colorScheme == .light ? NSpacing.sm : NSpacing.xs
                )

            HStack(alignment: .top, spacing: 0) {
                tabButton(.home)
                tabButton(.library)

                Spacer(minLength: Metrics.fabSize + NSpacing.lg)

                tabButton(.insights)
                tabButton(.profile)
            }
            .padding(.horizontal, NSpacing.lg)
            .padding(.top, NSpacing.lg)
            .padding(.bottom, NSpacing.sm)
            .zIndex(1)

            scanButton
                .offset(y: -Metrics.fabLift)
                .zIndex(2)
        }
        .frame(height: Metrics.barHeight)
        .padding(.horizontal, NSpacing.sm)
        .padding(.bottom, NSpacing.xs - 5)
    }

    private func tabButton(_ item: NBottomNavItem) -> some View {
        let isActive = selectedTab == item

        return Button {
            guard selectedTab != item else { return }
            selectedTab = item
            onSelect(item)
        } label: {
            VStack(spacing: NSpacing.xs) {
                Image(systemName: item.systemImage)
                    .font(.system(size: Metrics.iconSize, weight: .regular))
                    .foregroundStyle(isActive ? NColors.Brand.neuroBlue : NColors.Text.textTertiary)

                Text(item.title(for: locale))
                    .font(NTypography.micro)
                    .foregroundStyle(isActive ? NColors.Brand.neuroBlue : NColors.Text.textTertiary)
            }
            .frame(maxWidth: .infinity, minHeight: Metrics.tabHitSize)
            .offset(y: -NSpacing.sm)
            .scaleEffect(isActive ? Metrics.activeScale : 1)
            .opacity(isActive ? 1 : 0.88)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: selectedTab)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title(for: locale))
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    private var scanButton: some View {
        Button(action: onScanTap) {
            Image(systemName: "viewfinder")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(NColors.Neutrals.background)
                .frame(width: Metrics.fabSize, height: Metrics.fabSize)
                .background(
                    Circle()
                        .fill(NColors.neuroGradient)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan")
        .shadow(
            color: colorScheme == .light
                ? NColors.Brand.neuroBlue.opacity(0.22)
                : NColors.Brand.neuralMint.opacity(0.18),
            radius: colorScheme == .light ? NSpacing.md : NSpacing.sm + NSpacing.xs,
            x: 0,
            y: colorScheme == .light ? NSpacing.sm : 0
        )
    }
}
