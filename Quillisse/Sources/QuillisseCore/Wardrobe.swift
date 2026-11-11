import Foundation

public enum GarmentCategory: String, Codable, CaseIterable, Equatable {
    case top
    case bottom
    case dress
    case outerwear
    case shoes
    case accessory

    public var displayName: String {
        switch self {
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .dress: return "Dress"
        case .outerwear: return "Outerwear"
        case .shoes: return "Shoes"
        case .accessory: return "Accessory"
        }
    }

    public var sortIndex: Int {
        switch self {
        case .top: return 0
        case .bottom: return 1
        case .dress: return 2
        case .outerwear: return 3
        case .shoes: return 4
        case .accessory: return 5
        }
    }
}

public enum GarmentColor: String, Codable, CaseIterable, Equatable {
    case ivory
    case cream
    case white
    case black
    case charcoal
    case navy
    case camel
    case blush
    case coral
    case lavender
    case blue
    case olive
    case gold
    case denim
    case grey

    public var displayName: String {
        switch self {
        case .ivory: return "Ivory"
        case .cream: return "Cream"
        case .white: return "White"
        case .black: return "Black"
        case .charcoal: return "Charcoal"
        case .navy: return "Navy"
        case .camel: return "Camel"
        case .blush: return "Blush"
        case .coral: return "Coral"
        case .lavender: return "Lavender"
        case .blue: return "Blue"
        case .olive: return "Olive"
        case .gold: return "Gold"
        case .denim: return "Denim"
        case .grey: return "Grey"
        }
    }

    /// sRGB components for a closet swatch. Not a dye formula.
    public var swatch: (red: Double, green: Double, blue: Double) {
        switch self {
        case .ivory: return (0.96, 0.94, 0.89)
        case .cream: return (0.93, 0.89, 0.80)
        case .white: return (0.97, 0.97, 0.96)
        case .black: return (0.12, 0.12, 0.13)
        case .charcoal: return (0.29, 0.29, 0.31)
        case .navy: return (0.14, 0.20, 0.34)
        case .camel: return (0.76, 0.61, 0.42)
        case .blush: return (0.91, 0.73, 0.71)
        case .coral: return (0.89, 0.45, 0.40)
        case .lavender: return (0.74, 0.68, 0.84)
        case .blue: return (0.55, 0.68, 0.82)
        case .olive: return (0.45, 0.48, 0.30)
        case .gold: return (0.76, 0.63, 0.38)
        case .denim: return (0.55, 0.66, 0.78)
        case .grey: return (0.62, 0.60, 0.57)
        }
    }

    public var isNeutral: Bool {
        switch self {
        case .blush, .coral, .lavender, .blue, .olive:
            return false
        case .ivory, .cream, .white, .black, .charcoal, .navy, .camel, .gold, .denim, .grey:
            return true
        }
    }
}

public enum Season: String, Codable, CaseIterable, Equatable {
    case spring
    case summer
    case autumn
    case winter
    case allSeason

    public var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        case .allSeason: return "All year"
        }
    }

    public static func from(month: Int) -> Season {
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .winter
        }
    }
}

public enum Formality: String, Codable, CaseIterable, Equatable {
    case casual
    case smart
    case formal

    public var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .smart: return "Smart"
        case .formal: return "Formal"
        }
    }
}

public enum GarmentWeight: String, Codable, CaseIterable, Equatable {
    case light
    case medium
    case heavy

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}

public enum Occasion: String, Codable, CaseIterable, Equatable {
    case work
    case casual
    case date
    case weekend
    case formal

    public var displayName: String {
        switch self {
        case .work: return "Work"
        case .casual: return "Casual"
        case .date: return "Date"
        case .weekend: return "Weekend"
        case .formal: return "Formal"
        }
    }
}

public enum WeatherBand: String, Codable, CaseIterable, Equatable {
    case hot
    case warm
    case mild
    case cool
    case cold
    case wet

    public var displayName: String {
        switch self {
        case .hot: return "Hot"
        case .warm: return "Warm"
        case .mild: return "Mild"
        case .cool: return "Cool"
        case .cold: return "Cold"
        case .wet: return "Wet"
        }
    }

    public static func band(celsius: Double) -> WeatherBand {
        if celsius >= 28 { return .hot }
        if celsius >= 21 { return .warm }
        if celsius >= 14 { return .mild }
        if celsius >= 7 { return .cool }
        return .cold
    }
}

public struct WeatherChoice: Codable, Equatable {
    public var band: WeatherBand
    public var isRaining: Bool

    public init(band: WeatherBand, isRaining: Bool = false) {
        self.band = band
        self.isRaining = isRaining
    }

    public var label: String {
        if isRaining && band != .wet {
            return "\(band.displayName), rain"
        }
        return band.displayName
    }
}

public enum LayerNeed: Equatable {
    case required
    case welcome
    case lightOnly
    case avoid

    public static func forWeather(_ weather: WeatherChoice) -> LayerNeed {
        if weather.isRaining || weather.band == .wet || weather.band == .cold || weather.band == .cool {
            return .required
        }
        if weather.band == .mild { return .welcome }
        if weather.band == .warm { return .lightOnly }
        return .avoid
    }
}

public struct DayStamp: Codable, Hashable, Comparable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    public static func from(_ date: Date, calendar: Calendar) -> DayStamp {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return DayStamp(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    public func date(calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    public func addingDays(_ days: Int, calendar: Calendar) -> DayStamp? {
        guard let start = date(calendar: calendar),
              let next = calendar.date(byAdding: .day, value: days, to: start) else {
            return nil
        }
        return DayStamp.from(next, calendar: calendar)
    }

    public func distance(to other: DayStamp, calendar: Calendar) -> Int? {
        guard let start = date(calendar: calendar), let end = other.date(calendar: calendar) else {
            return nil
        }
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    public var season: Season {
        Season.from(month: month)
    }
}

public enum CivilDate {
    public static func utc() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        calendar.firstWeekday = 1
        return calendar
    }
}

public struct Garment: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: GarmentCategory
    public var colors: [GarmentColor]
    public var seasons: [Season]
    public var formality: Formality
    public var weight: GarmentWeight
    public var imageToken: String
    public var isFavorite: Bool
    public var isSample: Bool
    public var createdAt: Date
    public var note: String

    public init(
        id: UUID,
        name: String,
        category: GarmentCategory,
        colors: [GarmentColor],
        seasons: [Season],
        formality: Formality,
        weight: GarmentWeight,
        imageToken: String,
        isFavorite: Bool = false,
        isSample: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        note: String = ""
    ) {
        self.id = id
        self.name = ClosetText.name(name, fallback: category.displayName)
        self.category = category
        self.colors = colors.isEmpty ? [.ivory] : colors
        self.seasons = seasons.isEmpty ? [.allSeason] : seasons
        self.formality = formality
        self.weight = weight
        self.imageToken = imageToken
        self.isFavorite = isFavorite
        self.isSample = isSample
        self.createdAt = createdAt
        self.note = note
    }

    public var primaryColor: GarmentColor {
        colors[0]
    }

    public func suits(season: Season) -> Bool {
        seasons.contains(.allSeason) || seasons.contains(season)
    }
}

public struct SavedLook: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var pieceIDs: [UUID]
    public var occasion: Occasion?
    public var isFavorite: Bool
    public var handbuilt: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        pieceIDs: [UUID],
        occasion: Occasion?,
        isFavorite: Bool = false,
        handbuilt: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = ClosetText.name(name, fallback: "Saved look")
        self.pieceIDs = pieceIDs
        self.occasion = occasion
        self.isFavorite = isFavorite
        self.handbuilt = handbuilt
        self.createdAt = createdAt
    }
}

public struct WearEntry: Codable, Equatable, Identifiable {
    public var id: UUID
    public var day: DayStamp
    public var pieceIDs: [UUID]
    public var occasion: Occasion
    public var lookID: UUID?
    public var note: String

    public init(
        id: UUID = UUID(),
        day: DayStamp,
        pieceIDs: [UUID],
        occasion: Occasion,
        lookID: UUID? = nil,
        note: String = ""
    ) {
        self.id = id
        self.day = day
        self.pieceIDs = pieceIDs
        self.occasion = occasion
        self.lookID = lookID
        self.note = note
    }
}

public struct LookSlots: Codable, Equatable {
    public var top: UUID?
    public var bottom: UUID?
    public var dress: UUID?
    public var outerwear: UUID?
    public var shoes: UUID?
    public var accessory: UUID?

    public init(
        top: UUID? = nil,
        bottom: UUID? = nil,
        dress: UUID? = nil,
        outerwear: UUID? = nil,
        shoes: UUID? = nil,
        accessory: UUID? = nil
    ) {
        self.top = top
        self.bottom = bottom
        self.dress = dress
        self.outerwear = outerwear
        self.shoes = shoes
        self.accessory = accessory
    }

    public static let empty = LookSlots()

    public var pieceIDs: [UUID] {
        [top, bottom, dress, outerwear, shoes, accessory].compactMap { $0 }
    }

    public static func from(pieces: [Garment]) -> LookSlots {
        var slots = LookSlots()
        for piece in pieces {
            switch piece.category {
            case .top: slots.top = piece.id
            case .bottom: slots.bottom = piece.id
            case .dress: slots.dress = piece.id
            case .outerwear: slots.outerwear = piece.id
            case .shoes: slots.shoes = piece.id
            case .accessory: slots.accessory = piece.id
            }
        }
        return slots
    }
}

public enum LookIssue: Equatable {
    case empty
    case dressWithTop
    case dressWithBottom
    case missingTop
    case missingBottom
    case missingShoes

    public var isBlocking: Bool {
        switch self {
        case .missingShoes: return false
        case .empty, .dressWithTop, .dressWithBottom, .missingTop, .missingBottom: return true
        }
    }

    public var message: String {
        switch self {
        case .empty:
            return "Choose at least a dress, or a top and a bottom."
        case .dressWithTop:
            return "A dress replaces the top. Clear one of them."
        case .dressWithBottom:
            return "A dress replaces the bottom. Clear one of them."
        case .missingTop:
            return "Add a top, or switch to a dress."
        case .missingBottom:
            return "Add a bottom, or switch to a dress."
        case .missingShoes:
            return "Shoes are still open. You can wear it anyway."
        }
    }
}

public struct ClosetPreferences: Codable, Equatable {
    public var hapticsEnabled: Bool
    public var repeatWindowDays: Int
    public var weather: WeatherChoice
    public var seasonOverride: Season?
    public var useAppleWeather: Bool
    public var weatherIsFromDevice: Bool
    public var weatherNote: String
    public var hasDismissedSampleNote: Bool

    public init(
        hapticsEnabled: Bool = true,
        repeatWindowDays: Int = 7,
        weather: WeatherChoice = WeatherChoice(band: .mild),
        seasonOverride: Season? = nil,
        useAppleWeather: Bool = false,
        weatherIsFromDevice: Bool = false,
        weatherNote: String = "",
        hasDismissedSampleNote: Bool = false
    ) {
        self.hapticsEnabled = hapticsEnabled
        self.repeatWindowDays = repeatWindowDays
        self.weather = weather
        self.seasonOverride = seasonOverride
        self.useAppleWeather = useAppleWeather
        self.weatherIsFromDevice = weatherIsFromDevice
        self.weatherNote = weatherNote
        self.hasDismissedSampleNote = hasDismissedSampleNote
    }

    public static let standard = ClosetPreferences()

    public var clampedWindow: Int {
        min(21, max(3, repeatWindowDays))
    }

    public func season(on day: DayStamp) -> Season {
        if let seasonOverride, seasonOverride != .allSeason {
            return seasonOverride
        }
        return day.season
    }
}

public enum ClosetText {
    public static let maxNameLength = 48

    public static func name(_ raw: String, fallback: String) -> String {
        let collapsed = raw
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if collapsed.isEmpty { return fallback }
        return String(collapsed.prefix(maxNameLength))
    }
}

public enum MonthGrid {
    /// Sunday-or-locale padded cells for one month. `nil` is an empty leading or trailing cell.
    public static func cells(year: Int, month: Int, calendar: Calendar) -> [DayStamp?] {
        guard (1...12).contains(month) else { return [] }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 12
        guard let first = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: first) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [DayStamp?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(DayStamp(year: year, month: month, day: day))
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }
}
