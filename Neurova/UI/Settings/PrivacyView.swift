import SwiftUI

struct PrivacyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @State private var showHero = false
    @State private var visibleSectionCount = 0

    private var cards: [PrivacyCardModel] {
        [
            PrivacyCardModel(
                icon: "person.crop.circle.badge.checkmark",
                tint: Color(red: 0.35, green: 0.59, blue: 0.97),
                titleEN: "Account data",
                titleES: "Datos de cuenta",
                bodyEN: "If you sign in with Apple, Neurova may store your Apple user ID, display name, and email when Apple shares it with the app.",
                bodyES: "Si inicias sesión con Apple, Neurova puede guardar tu Apple user ID, nombre visible y correo cuando Apple los comparte con la app."
            ),
            PrivacyCardModel(
                icon: "square.stack.3d.up.fill",
                tint: Color(red: 0.56, green: 0.35, blue: 0.96),
                titleEN: "Study library",
                titleES: "Biblioteca de estudio",
                bodyEN: "Subjects, decks, flashcards, study progress, streaks, XP, and preferences are stored so your learning state stays consistent across sessions.",
                bodyES: "Materias, decks, flashcards, progreso, rachas, XP y preferencias se guardan para mantener tu estado de estudio consistente entre sesiones."
            ),
            PrivacyCardModel(
                icon: "camera.aperture",
                tint: Color(red: 0.33, green: 0.79, blue: 0.57),
                titleEN: "Camera and photos",
                titleES: "Cámara y fotos",
                bodyEN: "Camera or photo access is used only when you choose to scan study material. OCR runs with Apple Vision on device in the current build.",
                bodyES: "La cámara o fotos se usan solo cuando decides escanear material de estudio. El OCR se ejecuta con Apple Vision en el dispositivo en la versión actual."
            ),
            PrivacyCardModel(
                icon: "icloud.fill",
                tint: Color(red: 0.30, green: 0.53, blue: 0.96),
                titleEN: "iCloud sync",
                titleES: "Sincronización con iCloud",
                bodyEN: "When sync is enabled, Neurova uses CloudKit to keep your private study data available on your Apple devices signed into the same iCloud account.",
                bodyES: "Cuando la sincronización está activa, Neurova usa CloudKit para mantener tus datos privados de estudio disponibles en tus dispositivos Apple con la misma cuenta de iCloud."
            ),
            PrivacyCardModel(
                icon: "lock.shield.fill",
                tint: Color(red: 0.92, green: 0.73, blue: 0.20),
                titleEN: "What Neurova does not do",
                titleES: "Lo que Neurova no hace",
                bodyEN: "The current app build does not include third-party ads, cross-app tracking, or external analytics SDKs for marketing profiles.",
                bodyES: "La versión actual de la app no incluye anuncios de terceros, tracking entre apps ni SDKs externos de analítica para perfiles de marketing."
            ),
            PrivacyCardModel(
                icon: "slider.horizontal.3",
                tint: Color(red: 0.95, green: 0.58, blue: 0.23),
                titleEN: "Your controls",
                titleES: "Tus controles",
                bodyEN: "You can edit or delete study content inside the app, revoke camera or photo permissions in iOS Settings, and remove the local app copy at any time.",
                bodyES: "Puedes editar o eliminar contenido de estudio dentro de la app, revocar permisos de cámara o fotos en Ajustes de iOS y quitar la copia local de la app en cualquier momento."
            )
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    privacyCard(card)
                        .opacity(visibleSectionCount > index ? 1 : 0)
                        .offset(y: visibleSectionCount > index ? 0 : 18)
                        .scaleEffect(visibleSectionCount > index ? 1 : 0.985)
                        .animation(.privacyExpo(duration: 0.55), value: visibleSectionCount)
                }

                footnote
                    .opacity(visibleSectionCount >= cards.count ? 0.72 : 0)
                    .offset(y: visibleSectionCount >= cards.count ? 0 : 12)
                    .animation(.privacyExpo(duration: 0.45), value: visibleSectionCount)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(backgroundView.ignoresSafeArea())
        .navigationTitle(locale.identifier.hasPrefix("en") ? "Privacy" : "Privacidad")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await runAnimationsIfNeeded()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(heroIconFill)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(heroIconTint)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(locale.identifier.hasPrefix("en") ? "PRIVACY SUMMARY" : "RESUMEN DE PRIVACIDAD")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.9)
                        .foregroundStyle(heroEyebrow)

                    Text(locale.identifier.hasPrefix("en") ? "Your flashcards stay private by design." : "Tus flashcards se mantienen privadas por diseño.")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(heroTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(locale.identifier.hasPrefix("en")
                 ? "Neurova is built around local study data, optional private iCloud sync, and on-device scanning workflows."
                 : "Neurova está construida alrededor de datos locales de estudio, sincronización privada opcional con iCloud y flujos de escaneo en el dispositivo.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(heroBody)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                highlightPill(
                    icon: "iphone",
                    title: locale.identifier.hasPrefix("en") ? "On-device" : "En dispositivo"
                )
                highlightPill(
                    icon: "icloud",
                    title: locale.identifier.hasPrefix("en") ? "Private sync" : "Sync privada"
                )
                highlightPill(
                    icon: "hand.raised.fill",
                    title: locale.identifier.hasPrefix("en") ? "No tracking" : "Sin tracking"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(heroBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: heroShadow, radius: colorScheme == .dark ? 24 : 14, x: 0, y: 10)
        .opacity(showHero ? 1 : 0)
        .offset(y: showHero ? 0 : 24)
        .scaleEffect(showHero ? 1 : 0.985)
        .animation(.privacyExpo(duration: 0.62), value: showHero)
    }

    private func privacyCard(_ card: PrivacyCardModel) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(card.tint.opacity(colorScheme == .dark ? 0.18 : 0.14))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: card.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(card.tint)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(locale.identifier.hasPrefix("en") ? card.titleEN : card.titleES)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Text(locale.identifier.hasPrefix("en") ? card.bodyEN : card.bodyES)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionFill)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: sectionShadow, radius: colorScheme == .dark ? 16 : 8, x: 0, y: 6)
    }

    private var footnote: some View {
        Text(locale.identifier.hasPrefix("en")
             ? "Last updated: March 12, 2026. This in-app policy describes the current Neurova build and should match the public privacy policy you publish with the app."
             : "Última actualización: 12 de marzo de 2026. Esta política dentro de la app describe la versión actual de Neurova y debería coincidir con la política pública que publiques con la app.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
    }

    private func highlightPill(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(primaryText)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(
            Capsule(style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.68))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private func runAnimationsIfNeeded() async {
        guard showHero == false else { return }

        withAnimation(.privacyExpo(duration: 0.62)) {
            showHero = true
        }

        for index in cards.indices {
            try? await Task.sleep(for: .milliseconds(index == 0 ? 90 : 55))
            withAnimation(.privacyExpo(duration: 0.55)) {
                visibleSectionCount = index + 1
            }
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.03, green: 0.04, blue: 0.09),
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color(red: 0.03, green: 0.05, blue: 0.11)
                ]
                : [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.94, green: 0.94, blue: 0.96),
                    Color(red: 0.93, green: 0.93, blue: 0.95)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroBackground: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.09, green: 0.11, blue: 0.19), Color(red: 0.10, green: 0.12, blue: 0.22)]
                : [Color(red: 0.93, green: 0.95, blue: 0.99), Color(red: 0.90, green: 0.93, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var sectionFill: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.10, blue: 0.17), Color(red: 0.09, green: 0.11, blue: 0.18)]
                : [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.93, green: 0.93, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.81, green: 0.85, blue: 0.93)
    }

    private var sectionStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.83, green: 0.84, blue: 0.88)
    }

    private var heroShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.24) : Color.black.opacity(0.06)
    }

    private var sectionShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.18) : Color.black.opacity(0.05)
    }

    private var heroIconFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.78)
    }

    private var heroIconTint: Color {
        Color(red: 0.35, green: 0.59, blue: 0.97)
    }

    private var heroEyebrow: Color {
        colorScheme == .dark ? Color(red: 0.55, green: 0.61, blue: 0.78) : Color(red: 0.42, green: 0.47, blue: 0.64)
    }

    private var heroTitle: Color {
        colorScheme == .dark ? Color.white.opacity(0.97) : Color(red: 0.07, green: 0.08, blue: 0.14)
    }

    private var heroBody: Color {
        colorScheme == .dark ? Color(red: 0.73, green: 0.77, blue: 0.86) : Color(red: 0.37, green: 0.41, blue: 0.52)
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.97) : Color(red: 0.07, green: 0.08, blue: 0.14)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color(red: 0.66, green: 0.70, blue: 0.78) : Color(red: 0.42, green: 0.46, blue: 0.56)
    }
}

private struct PrivacyCardModel {
    let icon: String
    let tint: Color
    let titleEN: String
    let titleES: String
    let bodyEN: String
    let bodyES: String
}

private extension Animation {
    static func privacyExpo(duration: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}
