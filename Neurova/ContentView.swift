//
//  ContentView.swift
//  Neurova
//
//  Created by Angel Orellana on 2/03/26.
//

import SwiftUI

struct ContentView: View {
    private let onOpenHome: (() -> Void)?

    init(onOpenHome: (() -> Void)? = nil) {
        self.onOpenHome = onOpenHome
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: NSpacing.md) {
                Text("Neurova")
                    .font(NTypography.display)
                    .foregroundStyle(NColors.Text.textPrimary)

                Text("Bootstrap build")
                    .font(NTypography.body)
                    .foregroundStyle(NColors.Text.textSecondary)

                NavigationLink {
                    BrandPreviewView()
                } label: {
                    NCard {
                        VStack(spacing: NSpacing.xs) {
                            Text("Open Brand Preview")
                                .font(NTypography.bodyEmphasis)
                                .foregroundStyle(NColors.Text.textPrimary)

                            Text("Validate colors, logos and mascot in light and dark.")
                                .font(NTypography.caption)
                                .foregroundStyle(NColors.Text.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DesignSystemShowcaseView()
                } label: {
                    NCard {
                        VStack(spacing: NSpacing.xs) {
                            Text("Open Design Showcase")
                                .font(NTypography.bodyEmphasis)
                                .foregroundStyle(NColors.Text.textPrimary)

                            Text("Review typography, controls and reusable components.")
                                .font(NTypography.caption)
                                .foregroundStyle(NColors.Text.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)

                if let onOpenHome {
                    Button {
                        onOpenHome()
                    } label: {
                        NCard {
                            VStack(spacing: NSpacing.xs) {
                                Text("Open Home")
                                    .font(NTypography.bodyEmphasis)
                                    .foregroundStyle(NColors.Text.textPrimary)

                                Text("Return to the app home vertical slice.")
                                    .font(NTypography.caption)
                                    .foregroundStyle(NColors.Text.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .multilineTextAlignment(.center)
            .padding(NSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NColors.Neutrals.background.ignoresSafeArea())
        }
    }
}

#Preview {
    ContentView()
}
