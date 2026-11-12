import SwiftUI

enum Theme {
    static let paper = Color(red: 0.953, green: 0.933, blue: 0.902)
    static let card = Color(red: 0.988, green: 0.976, blue: 0.957)
    static let ink = Color(red: 0.102, green: 0.090, blue: 0.078)
    static let muted = Color(red: 0.478, green: 0.443, blue: 0.408)
    static let line = Color(red: 0.839, green: 0.800, blue: 0.745)
    static let oxblood = Color(red: 0.557, green: 0.231, blue: 0.227)
    static let oxbloodDeep = Color(red: 0.420, green: 0.165, blue: 0.165)

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func swatch(_ color: GarmentColor) -> Color {
        let parts = color.swatch
        return Color(red: parts.red, green: parts.green, blue: parts.blue)
    }
}

enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
