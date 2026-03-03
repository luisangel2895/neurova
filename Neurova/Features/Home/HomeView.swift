import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let onSettingsTap: () -> Void
    private let onOpenBootstrap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    init(
        viewModel: HomeViewModel = HomeViewModel(),
        onSettingsTap: @escaping () -> Void = {},
        onOpenBootstrap: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSettingsTap = onSettingsTap
        self.onOpenBootstrap = onOpenBootstrap
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                headerSection
                studyCardSection
                statsGridSection
                recommendationSection
                recentDecksSection
                dailyGoalSummarySection
                tipSection
            }
            .padding(.horizontal, NSpacing.md + NSpacing.xs)
            .padding(.top, NSpacing.md)
            .padding(.bottom, NSpacing.xxl)
        }
        .background(homeBackground.ignoresSafeArea())
    }

    private var state: HomeState {
        viewModel.state
    }

    private var homeBackground: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [NColors.Home.backgroundLightTop, NColors.Home.backgroundLightBottom]
                : [NColors.Home.backgroundDarkTop, NColors.Home.backgroundDarkBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var secondaryTextColor: Color {
        colorScheme == .light ? NColors.Home.secondaryTextLight : NColors.Home.secondaryTextDark
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: NSpacing.xs) {
                Text("Hola, \(state.greetingName)\(state.greetingEmoji)")
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(state.subtitle)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.bottom, NSpacing.sm + 2)

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: state.settingsSymbolName)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(secondaryTextColor)
                    .frame(width: 36, height: 36)
                    .background(NColors.Neutrals.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(NColors.Neutrals.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0.7, perform: onOpenBootstrap)
        }
    }

    private var studyCardSection: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(state.studySectionTitle)
                    .font(NTypography.micro.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(NColors.Text.textTertiary)

                HStack(alignment: .center, spacing: NSpacing.md) {
                    ZStack {
                        NProgressRing(
                            progress: state.progress,
                            lineWidth: NSpacing.xs + 3,
                            centerText: nil
                        )
                        .frame(width: 68, height: 68)

                        Text(state.progressPercentText)
                            .font(NTypography.headline.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)
                    }
                    .padding(.top, NSpacing.md - 1)
                    .padding(.leading, NSpacing.md - 1)
                    .padding(.trailing, NSpacing.md - 1)
                    .padding(.bottom, 0)

                    VStack(alignment: .leading, spacing: NSpacing.sm) {
                        Text(state.studyTitle)
                            .font(NTypography.bodyEmphasis.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Text(state.progressDetailText)
                            .font(NTypography.caption)
                            .foregroundStyle(secondaryTextColor)

                        Spacer(minLength: 0)

                        NPrimaryButton(state.primaryActionTitle, action: {})
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 72)
                }

                NSecondaryButton(state.secondaryActionTitle, action: {})
                    .padding(.top, NSpacing.sm + 1)
            }
        }
    }

    private var statsGridSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs), GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs)],
            spacing: NSpacing.sm + NSpacing.xs
        ) {
            ForEach(state.quickStats) { stat in
                statTile(stat)
            }
        }
    }

    private func statTile(_ stat: QuickStat) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                Image(systemName: stat.systemImage)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(stat.iconColor)

                Spacer(minLength: 0)

                Text(stat.value)
                    .font(NTypography.title.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(stat.label)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        }
    }

    private var recommendationSection: some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.md) {
                Text(state.recommendationSectionTitle)
                    .font(NTypography.micro.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(NColors.Text.textTertiary)

                HStack(spacing: NSpacing.xs) {
                    ForEach(state.recommendation.tags, id: \.self) { tag in
                        NChip(tag, isSelected: false)
                            .scaleEffect(0.9)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(state.recommendation.title)
                    .font(NTypography.caption.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)

                Text(state.recommendation.message)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
                    .padding(.top, -2)
                    .fixedSize(horizontal: false, vertical: true)

                NSecondaryButton(state.recommendation.actionTitle, action: {})
                    .padding(.top, NSpacing.xs)
            }
        }
    }

    private var recentDecksSection: some View {
        VStack(alignment: .leading, spacing: NSpacing.sm) {
            Text(state.recentsSectionTitle)
                .font(NTypography.micro.weight(.bold))
                .tracking(0.6)
                .foregroundStyle(NColors.Text.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NSpacing.sm) {
                    ForEach(state.recentDecks) { deck in
                        recentDeckCard(deck)
                    }
                }
                .padding(.trailing, NSpacing.xs)
            }
        }
    }

    private func recentDeckCard(_ deck: RecentDeck) -> some View {
        NCard {
            VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(deck.accentColor)
                    .frame(width: 28, height: 28)

                Spacer(minLength: 0)

                Text(deck.title)
                    .font(NTypography.caption.weight(.bold))
                    .foregroundStyle(NColors.Text.textPrimary)
                    .lineLimit(2)

                Text(deck.cardCountText)
                    .font(NTypography.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(width: 104, height: 78, alignment: .leading)
        }
    }

    private var dailyGoalSummarySection: some View {
        NCard {
            HStack(spacing: NSpacing.sm + NSpacing.xs) {
                Image(systemName: state.dailyGoalSummarySymbolName)
                    .font(NTypography.bodyEmphasis)
                    .foregroundStyle(NColors.Brand.neuroBlue)
                    .frame(width: 32, height: 32)
                    .background(NColors.Neutrals.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: NRadius.button, style: .continuous))

                VStack(alignment: .leading, spacing: NSpacing.sm) {
                    HStack {
                        Text(state.dailyGoalSummaryTitle)
                            .font(NTypography.caption.weight(.bold))
                            .foregroundStyle(NColors.Text.textPrimary)

                        Spacer()

                        Text(state.dailyGoalSummaryTrailingText)
                            .font(NTypography.caption.weight(.bold))
                            .foregroundStyle(secondaryTextColor)
                    }

                    NProgressBar(progress: state.dailyGoalSummaryProgress)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var tipSection: some View {
        NCard {
            HStack(alignment: .center, spacing: NSpacing.sm + NSpacing.xs) {
                NImages.Brand.logoMark
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: NSpacing.xs + 2) {
                    Text(state.tipTitle)
                        .font(NTypography.caption.weight(.bold))
                        .foregroundStyle(NColors.Text.textPrimary)

                    Text(state.tipMessage)
                        .font(NTypography.caption)
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Light") {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
}
