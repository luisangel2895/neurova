//
//  RecoveredCloudSessionView.swift
//  Neurova
//

import Combine
import SwiftUI

struct RecoveredCloudSession {
    let appleUserID: String
    let displayName: String
    let email: String?
}

struct RecoveredCloudSessionView: View {
    @Environment(\.colorScheme) private var colorScheme
    let locale: Locale
    let recoveredCloudSession: RecoveredCloudSession
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDark ? NColors.Recovery.backgroundDark : NColors.Recovery.backgroundLight,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 54)

                (isDark ? NImages.Brand.logoOutline : NImages.Brand.logoMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66, height: 66)
                    .shadow(color: logoShadowColor, radius: 18, x: 0, y: 8)
                    .modifier(FloatingLogoEffect(period: 2.1, amplitude: 2))
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: "icloud")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NColors.Recovery.iconTint)
                            .frame(width: 30, height: 30)
                            .background(NColors.Recovery.iconBackground)
                            .clipShape(Circle())

                        Text(AppCopy.text(locale, en: "ICLOUD SYNCED", es: "ICLOUD SINCRONIZADO"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(NColors.Recovery.eyebrow)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(AppCopy.text(locale, en: "Account found", es: "Cuenta encontrada"))
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                            .foregroundStyle(NColors.Recovery.title)

                        Text(
                            AppCopy.text(
                                locale,
                                en: "We found your Neurova profile in iCloud. You can continue without signing in again.",
                                es: "Encontramos tu perfil de Neurova en iCloud. Puedes continuar sin iniciar sesión otra vez."
                            )
                        )
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(NColors.Recovery.body)
                    }

                    profilePill
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    NColors.Recovery.cardBackgroundTop,
                                    NColors.Recovery.cardBackgroundBottom
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(NColors.Recovery.cardBorder, lineWidth: 1)
                )

                NGradientButton(
                    AppCopy.text(locale, en: "Go to app", es: "Ir a la app"),
                    showsChevron: true,
                    animateEffects: true,
                    foregroundColor: NColors.Recovery.buttonText,
                    gradientColors: NColors.Recovery.buttonGradient(for: colorScheme)
                ) {
                    onContinue()
                }
                .shadow(color: NColors.Recovery.buttonShadow, radius: 14, x: 0, y: 8)
                .modifier(PressScaleEffect())

                Text(AppCopy.text(locale, en: "Your data is protected with end-to-end encryption", es: "Tus datos están protegidos con cifrado de extremo a extremo"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(NColors.Recovery.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
        }
    }

    private var profilePill: some View {
        HStack(spacing: 12) {
            AnimatedGradientAvatar(initial: avatarInitial)

            VStack(alignment: .leading, spacing: 2) {
                Text(recoveredCloudSession.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(NColors.Recovery.name)

                if let email = recoveredCloudSession.email, email.isEmpty == false {
                    Text(email)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(NColors.Recovery.email)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(NColors.Recovery.pillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(NColors.Recovery.pillBorder, lineWidth: 1)
        )
    }

    private var isDark: Bool { colorScheme == .dark }
    private var logoShadowColor: Color {
        NColors.Recovery.logoShadow
    }

    private var avatarInitial: String {
        let trimmed = recoveredCloudSession.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "N" }
        return String(first).uppercased()
    }
}

private struct AnimatedGradientAvatar: View {
    let initial: String
    @State private var tickTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(initial)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(NColors.Recovery.avatarText)
            .frame(width: 46, height: 46)
            .background(
                LinearGradient(
                    colors: NColors.Recovery.avatarGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let phase = (tickTime / 2.15).truncatingRemainder(dividingBy: 1.0)
                    let shinePhase = -1.4 + (2.8 * phase)
                    let xOffset = width * shinePhase

                    Circle()
                        .fill(.clear)
                        .overlay(
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            Color.white.opacity(0.10),
                                            Color.white.opacity(0.24),
                                            Color.white.opacity(0.10),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .rotationEffect(.degrees(20))
                                .blur(radius: 2.4)
                                .offset(x: xOffset)
                        )
                        .blendMode(.screen)
                }
                .clipShape(Circle())
            }
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
            }
            .overlay(alignment: .top) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 42, height: 18)
                    .blur(radius: 0.5)
                    .offset(y: -2)
                    .allowsHitTesting(false)
            }
            .clipShape(Circle())
            .onReceive(tick) { date in
                tickTime = date.timeIntervalSinceReferenceDate
            }
    }
}

struct FloatingLogoEffect: ViewModifier {
    let period: Double
    let amplitude: CGFloat
    @State private var tickTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        let phase = (tickTime / period) * 2.0 * Double.pi
        let y = CGFloat(sin(phase)) * amplitude

        content
            .offset(y: y)
            .onReceive(tick) { date in
                tickTime = date.timeIntervalSinceReferenceDate
            }
    }
}

struct PressScaleEffect: ViewModifier {
    @GestureState private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.98 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($pressed) { _, state, _ in
                        state = true
                    }
            )
    }
}
