import SwiftUI
import PolquetteCore

enum SalonTheme {
    static let ivory = Color(red: 0.965, green: 0.937, blue: 0.910)
    static let paper = Color(red: 1.0, green: 0.976, blue: 0.957)
    static let ink = Color(red: 0.173, green: 0.141, blue: 0.133)
    static let rose = Color(red: 0.769, green: 0.357, blue: 0.416)
    static let roseDeep = Color(red: 0.545, green: 0.227, blue: 0.286)
    static let gold = Color(red: 0.776, green: 0.631, blue: 0.357)
    static let blush = Color(red: 0.953, green: 0.839, blue: 0.816)
    static let line = Color(red: 0.173, green: 0.141, blue: 0.133).opacity(0.12)
    static let muted = Color(red: 0.42, green: 0.35, blue: 0.33)

    static let skinLight = Color(red: 0.973, green: 0.843, blue: 0.796)
    static let skinMid = Color(red: 0.941, green: 0.761, blue: 0.690)
    static let skinShadow = Color(red: 0.886, green: 0.682, blue: 0.612)

    static func polish(_ id: String) -> Color {
        let rgba = (Palette.color(id: id) ?? Palette.colors[0]).rgba
        return Color(red: rgba.red, green: rgba.green, blue: rgba.blue)
    }

    static let titleFont = Font.system(.title, design: .serif).weight(.semibold)
    static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let headline = Font.system(.headline, design: .serif)
}

enum SalonRoute: Hashable {
    case studio
    case looks
    case gallery
    case challenge
    case about
}

enum BriefSource: Equatable {
    case daily(dayKey: String)
    case career(index: Int)
}
