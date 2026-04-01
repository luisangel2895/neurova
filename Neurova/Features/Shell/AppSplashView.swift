//
//  AppSplashView.swift
//  Neurova
//

import SwiftUI

struct AppSplashView: View {
    let isDark: Bool
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    var body: some View {
        Group {
            if isDark {
                darkSplash
            } else {
                LightSplashView(
                    logoVisible: logoVisible,
                    pulsing: pulsing,
                    exiting: exiting
                )
            }
        }
        .ignoresSafeArea()
    }

    private var darkSplash: some View {
        DarkSplashView(
            logoVisible: logoVisible,
            pulsing: pulsing,
            exiting: exiting
        )
    }
}

private struct LightSplashView: View {
    @Environment(\.locale) private var locale
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    @State private var loadingVisible = false
    @State private var progress: CGFloat = 0.0

    private let barWidth: CGFloat = 170
    private let particleVectors: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-1.0, 0.0, 7, 0.00),
        (1.0, 0.0, 6, 0.22),
        (0.0, 1.0, 7, 0.34),
        (0.0, -1.0, 5, 0.12)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: NColors.Splash.lightBackground,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.lightGlow,
                        center: .center,
                        startRadius: 20,
                        endRadius: 230
                    )
                )
                .frame(width: 330, height: 330)

            VStack(spacing: 22) {
                ZStack {
                    ForEach(Array(particleVectors.enumerated()), id: \.offset) { _, vector in
                        LightSplashParticle(
                            dx: vector.0,
                            dy: vector.1,
                            size: vector.2,
                            delay: vector.3,
                            active: logoVisible && exiting == false
                        )
                    }

                    NImages.Brand.logoMark
                        .resizable()
                        .scaledToFit()
                        .frame(width: 124)
                        .shadow(color: NColors.Splash.lightLogoShadow, radius: 16, x: 0, y: 8)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NColors.Splash.lightTrack)
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: NColors.Splash.lightParticleGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: NColors.Splash.lightProgressShadow, radius: 5, x: 0, y: 2)
                    }

                    Text(AppCopy.text(locale, en: "LOADING", es: "CARGANDO"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(NColors.Splash.lightLabel)
                }
                .offset(y: loadingVisible ? 0 : 16)
                .opacity(loadingVisible ? (exiting ? 0.0 : 1.0) : 0.0)
            }
            .offset(y: -8)
        }
        .task {
            guard loadingVisible == false else { return }
            withAnimation(.easeOut(duration: 0.55).delay(0.08)) {
                loadingVisible = true
            }
            withAnimation(.easeOut(duration: 1.42).delay(0.22)) {
                progress = 1.0
            }
        }
    }
}

private struct LightSplashParticle: View {
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let delay: Double
    let active: Bool

    @State private var phase = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: NColors.Splash.lightParticleGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .opacity(active ? (phase ? 0.0 : 0.92) : 0.0)
            .scaleEffect(phase ? 1.25 : 0.45)
            .offset(x: dx * (phase ? 104 : 40), y: dy * (phase ? 104 : 40))
            .task(id: active) {
                guard active else {
                    phase = false
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                while Task.isCancelled == false {
                    phase = false
                    withAnimation(.easeOut(duration: 1.08)) {
                        phase = true
                    }
                    try? await Task.sleep(nanoseconds: 1_120_000_000)
                }
            }
    }
}

private struct DarkSplashView: View {
    @Environment(\.locale) private var locale
    let logoVisible: Bool
    let pulsing: Bool
    let exiting: Bool

    @State private var loadingVisible = false
    @State private var progress: CGFloat = 0.0

    private let barWidth: CGFloat = 170
    private let particleVectors: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-1.0, 0.0, 7, 0.00),
        (1.0, 0.0, 6, 0.22),
        (0.0, 1.0, 7, 0.34),
        (0.0, -1.0, 5, 0.12)
    ]

    var body: some View {
        ZStack {
            NColors.Splash.darkBase

            LinearGradient(
                colors: NColors.Splash.darkOverlay,
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.darkPrimaryGlow,
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 360, height: 320)
                .blur(radius: 14)
                .offset(y: -10)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: NColors.Splash.darkSecondaryGlow,
                        center: .center,
                        startRadius: 0,
                        endRadius: 210
                    )
                )
                .frame(width: 320, height: 280)
                .blur(radius: 18)
                .offset(y: 10)

            VStack(spacing: 22) {
                ZStack {
                    ForEach(Array(particleVectors.enumerated()), id: \.offset) { _, vector in
                        DarkSplashParticle(
                            dx: vector.0,
                            dy: vector.1,
                            size: vector.2,
                            delay: vector.3,
                            active: logoVisible && exiting == false
                        )
                    }

                    NImages.Brand.logoOutline
                        .resizable()
                        .scaledToFit()
                        .frame(width: 124)
                        .shadow(color: NColors.Splash.darkLogoShadow, radius: 12, x: 0, y: 6)
                        .scaleEffect(logoVisible ? (pulsing ? 1.045 : 1.0) : 0.82)
                        .opacity(logoVisible ? (exiting ? 0.0 : 1.0) : 0.0)
                }

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NColors.Splash.darkTrack)
                            .frame(width: barWidth, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: NColors.Splash.darkParticleGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, barWidth * progress), height: 4)
                            .shadow(color: NColors.Splash.darkProgressShadow, radius: 7, x: 0, y: 2)
                    }

                    Text(AppCopy.text(locale, en: "LOADING", es: "CARGANDO"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(4.8)
                        .foregroundStyle(NColors.Splash.darkLabel)
                }
                .offset(y: loadingVisible ? 0 : 16)
                .opacity(loadingVisible ? (exiting ? 0.0 : 1.0) : 0.0)
            }
            .offset(y: -8)
        }
        .task {
            guard loadingVisible == false else { return }
            withAnimation(.easeOut(duration: 0.55).delay(0.08)) {
                loadingVisible = true
            }
            withAnimation(.easeOut(duration: 1.42).delay(0.22)) {
                progress = 1.0
            }
        }
    }
}

private struct DarkSplashParticle: View {
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let delay: Double
    let active: Bool

    @State private var phase = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: NColors.Splash.darkParticleGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .opacity(active ? (phase ? 0.0 : 0.90) : 0.0)
            .scaleEffect(phase ? 1.25 : 0.45)
            .offset(x: dx * (phase ? 104 : 40), y: dy * (phase ? 104 : 40))
            .task(id: active) {
                guard active else {
                    phase = false
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                while Task.isCancelled == false {
                    phase = false
                    withAnimation(.easeOut(duration: 1.08)) {
                        phase = true
                    }
                    try? await Task.sleep(nanoseconds: 1_120_000_000)
                }
            }
    }
}
