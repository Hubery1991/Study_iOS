import SwiftUI

enum Theme {
    static let ink = Color(hex: 0x120D1F)
    static let sky = Color(hex: 0x2A1B4A)
    static let shaft = Color(hex: 0x0C0A14)
    static let brass = Color(hex: 0xE8C16A)
    static let brassDeep = Color(hex: 0xB8883A)
    static let parchment = Color(hex: 0xF6F0E4)
    static let muted = Color(hex: 0xB5A9C4)
    static let card = Color.white.opacity(0.06)
    static let line = Color.white.opacity(0.08)

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func colors(for hue: Hue) -> (light: Color, deep: Color) {
        switch hue {
        case .amber: return (Color(hex: 0xFFC857), Color(hex: 0xE0922F))
        case .tide: return (Color(hex: 0x5FD0D0), Color(hex: 0x1E8E9E))
        case .moss: return (Color(hex: 0x8FCB6B), Color(hex: 0x3E8C45))
        case .violet: return (Color(hex: 0xC4B0FF), Color(hex: 0x6E56C8))
        case .rose: return (Color(hex: 0xFF9BB3), Color(hex: 0xE25B86))
        case .spark: return (Color(hex: 0xFFF4D2), Color(hex: 0xE0A020))
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

enum Format {
    static let scores: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func score(_ value: Int) -> String {
        scores.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func clock(_ time: TimeInterval) -> String {
        "\(max(0, Int(time.rounded(.up))))"
    }
}
