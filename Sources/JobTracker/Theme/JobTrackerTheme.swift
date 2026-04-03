import SwiftUI

// MARK: - Light / dark (app-controlled, not system appearance)

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Theme presets (accent families; light/dark chosen separately)

enum ThemePreset: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case sequoia = "Sequoia"
    case ocean = "Ocean"
    case slate = "Slate"

    var id: String { rawValue }

    func themeColors(for mode: AppearanceMode) -> ThemeColors {
        switch (self, mode) {
        case (.midnight, .dark):
            return ThemeColors(
                background: Color(red: 0.11, green: 0.12, blue: 0.14),
                surface: Color(red: 0.14, green: 0.15, blue: 0.18),
                elevated: Color(red: 0.17, green: 0.18, blue: 0.22),
                accent: Color(red: 0.35, green: 0.55, blue: 0.95),
                muted: Color(red: 0.55, green: 0.58, blue: 0.62),
                textPrimary: Color(red: 0.92, green: 0.93, blue: 0.95),
                border: Color(red: 0.28, green: 0.30, blue: 0.35)
            )
        case (.midnight, .light):
            return ThemeColors(
                background: Color(red: 0.94, green: 0.95, blue: 0.97),
                surface: Color(red: 1.0, green: 1.0, blue: 1.0),
                elevated: Color(red: 0.96, green: 0.97, blue: 0.99),
                accent: Color(red: 0.22, green: 0.45, blue: 0.88),
                muted: Color(red: 0.45, green: 0.48, blue: 0.52),
                textPrimary: Color(red: 0.12, green: 0.13, blue: 0.16),
                border: Color(red: 0.82, green: 0.84, blue: 0.88)
            )
        case (.sequoia, .dark):
            return ThemeColors(
                background: Color(red: 0.08, green: 0.10, blue: 0.06),
                surface: Color(red: 0.12, green: 0.14, blue: 0.09),
                elevated: Color(red: 0.16, green: 0.19, blue: 0.12),
                accent: Color(red: 0.55, green: 0.75, blue: 0.40),
                muted: Color(red: 0.50, green: 0.55, blue: 0.45),
                textPrimary: Color(red: 0.90, green: 0.92, blue: 0.88),
                border: Color(red: 0.22, green: 0.26, blue: 0.18)
            )
        case (.sequoia, .light):
            return ThemeColors(
                background: Color(red: 0.95, green: 0.97, blue: 0.93),
                surface: Color(red: 1.0, green: 1.0, blue: 1.0),
                elevated: Color(red: 0.93, green: 0.96, blue: 0.90),
                accent: Color(red: 0.28, green: 0.55, blue: 0.22),
                muted: Color(red: 0.42, green: 0.48, blue: 0.40),
                textPrimary: Color(red: 0.10, green: 0.14, blue: 0.09),
                border: Color(red: 0.80, green: 0.86, blue: 0.76)
            )
        case (.ocean, .dark):
            return ThemeColors(
                background: Color(red: 0.08, green: 0.11, blue: 0.16),
                surface: Color(red: 0.10, green: 0.14, blue: 0.20),
                elevated: Color(red: 0.13, green: 0.17, blue: 0.24),
                accent: Color(red: 0.30, green: 0.65, blue: 0.85),
                muted: Color(red: 0.45, green: 0.55, blue: 0.65),
                textPrimary: Color(red: 0.90, green: 0.93, blue: 0.96),
                border: Color(red: 0.20, green: 0.28, blue: 0.38)
            )
        case (.ocean, .light):
            return ThemeColors(
                background: Color(red: 0.93, green: 0.96, blue: 0.99),
                surface: Color(red: 1.0, green: 1.0, blue: 1.0),
                elevated: Color(red: 0.90, green: 0.95, blue: 0.99),
                accent: Color(red: 0.12, green: 0.52, blue: 0.78),
                muted: Color(red: 0.40, green: 0.50, blue: 0.58),
                textPrimary: Color(red: 0.08, green: 0.12, blue: 0.18),
                border: Color(red: 0.78, green: 0.86, blue: 0.94)
            )
        case (.slate, .dark):
            return ThemeColors(
                background: Color(red: 0.15, green: 0.15, blue: 0.17),
                surface: Color(red: 0.19, green: 0.19, blue: 0.22),
                elevated: Color(red: 0.23, green: 0.23, blue: 0.27),
                accent: Color(red: 0.70, green: 0.50, blue: 0.85),
                muted: Color(red: 0.55, green: 0.55, blue: 0.60),
                textPrimary: Color(red: 0.92, green: 0.92, blue: 0.94),
                border: Color(red: 0.32, green: 0.32, blue: 0.38)
            )
        case (.slate, .light):
            return ThemeColors(
                background: Color(red: 0.96, green: 0.94, blue: 0.98),
                surface: Color(red: 1.0, green: 1.0, blue: 1.0),
                elevated: Color(red: 0.94, green: 0.92, blue: 0.97),
                accent: Color(red: 0.52, green: 0.32, blue: 0.72),
                muted: Color(red: 0.48, green: 0.45, blue: 0.52),
                textPrimary: Color(red: 0.14, green: 0.12, blue: 0.18),
                border: Color(red: 0.84, green: 0.80, blue: 0.90)
            )
        }
    }
}

struct ThemeColors {
    let background: Color
    let surface: Color
    let elevated: Color
    let accent: Color
    let muted: Color
    let textPrimary: Color
    let border: Color
}

// MARK: - Global theme accessor (computed from active preset + appearance mode)

enum JobTrackerTheme {
    @MainActor static var activePreset: ThemePreset = .midnight
    @MainActor static var appearanceMode: AppearanceMode = .dark

    @MainActor private static var current: ThemeColors {
        activePreset.themeColors(for: appearanceMode)
    }

    @MainActor static var background: Color { current.background }
    @MainActor static var surface: Color { current.surface }
    @MainActor static var elevated: Color { current.elevated }
    @MainActor static var accent: Color { current.accent }
    @MainActor static var muted: Color { current.muted }
    @MainActor static var textPrimary: Color { current.textPrimary }
    @MainActor static var border: Color { current.border }

    @MainActor static func tierColor(_ tier: String) -> Color {
        switch tier {
        case "Critical": return Color(red: 0.95, green: 0.45, blue: 0.4)
        case "High": return Color(red: 0.95, green: 0.7, blue: 0.35)
        case "Medium": return Color(red: 0.5, green: 0.75, blue: 0.95)
        default: return muted
        }
    }
}
