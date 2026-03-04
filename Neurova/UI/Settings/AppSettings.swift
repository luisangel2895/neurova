import Foundation
import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.system, .english):
            return "System"
        case (.system, .spanish):
            return "Sistema"
        case (.light, .english):
            return "Light"
        case (.light, .spanish):
            return "Claro"
        case (.dark, .english):
            return "Dark"
        case (.dark, .spanish):
            return "Oscuro"
        }
    }
}

private struct AppThemeApplier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .onAppear {
                applyTheme()
            }
            .onChange(of: theme.rawValue) { _, _ in
                applyTheme()
            }
    }

    private func applyTheme() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = theme.interfaceStyle
            }
        }
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        modifier(AppThemeApplier(theme: theme))
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.english, .english):
            return "English"
        case (.english, .spanish):
            return "Ingles"
        case (.spanish, .english):
            return "Spanish"
        case (.spanish, .spanish):
            return "Espanol"
        }
    }
}
