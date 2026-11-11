import SwiftUI
import UIKit

enum Theme {
    static let plum = Color(red: 0.173, green: 0.102, blue: 0.133)
    static let ink = Color(red: 0.145, green: 0.086, blue: 0.110)
    static let rose = Color(red: 0.788, green: 0.420, blue: 0.471)
    static let blush = Color(red: 0.910, green: 0.706, blue: 0.722)
    static let gold = Color(red: 0.722, green: 0.537, blue: 0.416)
    static let ivory = Color(red: 0.984, green: 0.965, blue: 0.949)
    static let champagne = Color(red: 0.953, green: 0.894, blue: 0.831)
    static let line = Color(red: 0.902, green: 0.835, blue: 0.812)
    static let card = Color.white.opacity(0.94)

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func uiColor(_ color: RGBA, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b), alpha: alpha)
    }
}

extension RGBA {
    var swiftUI: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }
}
