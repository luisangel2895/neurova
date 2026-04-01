import SwiftUI

struct HomeRecentDeckCard: View {
    let locale: Locale
    let deck: RecentDeck
    let isFeatured: Bool
    let colorScheme: ColorScheme
    let showFeaturedBadge: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: isFeatured ? 1.2 : 1)
                )
                .overlay(alignment: .leading) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: deck.subjectIconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(deck.accentColor)
                            .frame(width: 26, height: 26)
                            .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(deck.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textPrimary)

                                Text(deck.subjectPathText)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textSecondary)
                                    .lineLimit(1)
                            }

                            HStack(alignment: .center, spacing: 12) {
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule(style: .continuous)
                                            .fill(progressTrackColor)
                                            .frame(height: 3)

                                        Capsule(style: .continuous)
                                            .fill(deck.accentColor)
                                            .frame(
                                                width: showFeaturedBadge
                                                    ? max(proxy.size.width * deck.completionProgress, deck.completionProgress > 0 ? 18 : 0)
                                                    : 0,
                                                height: 3
                                            )
                                            .animation(.homeExpo(duration: 1.0, delay: 0.6), value: showFeaturedBadge)
                                    }
                                }
                                .frame(height: 3)

                                Text(deck.completionPercentText)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(NColors.Text.textSecondary.opacity(0.95))
                            }
                        }

                        VStack(spacing: 3) {
                            Text("\(deck.readyCount)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.96))
                                .frame(width: 33, height: 33)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(deck.accentColor)
                                )

                            Text(AppCopy.text(locale, en: "PEND.", es: "PEND."))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(NColors.Text.textTertiary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 17)
                }
                .frame(minHeight: 106)

            if isFeatured {
                HomeFeaturedBadge(locale: locale)
                    .padding(.top, -8)
                    .padding(.trailing, 20)
                    .offset(y: showFeaturedBadge ? 0 : -5)
                    .scaleEffect(showFeaturedBadge ? 1 : 0.8)
                    .opacity(showFeaturedBadge ? 1 : 0)
                    .animation(.homeSpring(delay: 0.6, stiffness: 300, damping: 24), value: showFeaturedBadge)
            }
        }
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [NColors.Surface.base.opacity(0.89), NColors.Surface.raised.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if isFeatured {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.90), NColors.Surface.accentSoft.opacity(0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.white.opacity(0.72))
    }

    private var cardBorderColor: Color {
        if isFeatured {
            return deck.accentColor.opacity(colorScheme == .dark ? 0.46 : 0.58)
        }
        return colorScheme == .dark ? Color.white.opacity(0.045) : NColors.Stroke.standard.opacity(0.42)
    }

    private var progressTrackColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.06)
    }
}

struct HomeFeaturedBadge: View {
    let locale: Locale

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .bold))
            Text(AppCopy.text(locale, en: "FOR YOU", es: "PARA TI"))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
        }
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, 11)
        .frame(height: 20)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [NColors.Brand.accentBlueStrong, NColors.Brand.neuroBlueDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
        )
        .shadow(color: NColors.Brand.neuroBlue.opacity(0.24), radius: 10, x: 0, y: 4)
    }
}
