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
        NHighlightCard(
            sectionLabel: state.studySectionTitle,
            title: state.studyTitle,
            subtitle: state.progressDetailText,
            primaryActionTitle: state.primaryActionTitle,
            secondaryActionTitle: state.secondaryActionTitle,
            onPrimaryAction: {},
            onSecondaryAction: {}
        ) {
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
        }
    }

    private var statsGridSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs), GridItem(.flexible(), spacing: NSpacing.sm + NSpacing.xs)],
            spacing: NSpacing.sm + NSpacing.xs
        ) {
            ForEach(state.quickStats) { stat in
                NStatCard(
                    systemImage: stat.systemImage,
                    iconColor: stat.iconColor,
                    value: stat.value,
                    label: stat.label
                )
            }
        }
    }

    private var recommendationSection: some View {
        NInfoCard(
            sectionLabel: state.recommendationSectionTitle,
            chips: state.recommendation.tags,
            title: state.recommendation.title,
            description: state.recommendation.message,
            actionTitle: state.recommendation.actionTitle,
            onAction: {}
        )
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
                        NDeckCard(
                            accentColor: deck.accentColor,
                            title: deck.title,
                            cardCountText: deck.cardCountText
                        )
                    }
                }
                .padding(.trailing, NSpacing.xs)
            }
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
        NTipCard(title: state.tipTitle, bodyText: state.tipMessage) {
            NImages.Brand.logoMark
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
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
