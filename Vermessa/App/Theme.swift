import SwiftUI

enum VermessaColor {
    static let paper = Color(red: 0.953, green: 0.902, blue: 0.863)
    static let card = Color(red: 1.0, green: 0.973, blue: 0.953)
    static let ink = Color(red: 0.173, green: 0.078, blue: 0.094)
    static let merlot = Color(red: 0.486, green: 0.141, blue: 0.212)
    static let merlotDeep = Color(red: 0.290, green: 0.082, blue: 0.133)
    static let line = Color(red: 0.831, green: 0.710, blue: 0.675)
    static let mist = Color(red: 0.420, green: 0.275, blue: 0.290)
}

enum VermessaFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

extension ShadeColor {
    var swiftUIColor: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}

enum StudioPortrait {
    static func assetName(for family: ColorFamily) -> String? {
        switch family {
        case .wine: return "PortraitMerlot"
        case .nude: return "PortraitNude"
        case .coral: return "PortraitCoral"
        default: return nil
        }
    }
}

enum DayText {
    static func title(for day: CalendarDay, today: CalendarDay) -> String {
        if day == today { return "Today" }
        if day == today.adding(days: -1) { return "Yesterday" }
        guard let date = day.utcNoon() else { return day.isoString }
        let formatter = DateFormatter()
        formatter.calendar = CalendarDay.utcCalendar()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}
