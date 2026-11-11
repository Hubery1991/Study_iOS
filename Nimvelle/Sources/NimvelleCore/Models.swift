import Foundation

/// A calendar day without a time of day. Stored as year, month, and day so a
/// routine file does not shift when the device time zone changes.
public struct DayKey: Codable, Hashable, Comparable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    public func date(calendar: Calendar) -> Date {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        guard let date = calendar.date(from: parts) else {
            preconditionFailure("Invalid day \(year)-\(month)-\(day)")
        }
        return date
    }

    public static func from(_ date: Date, calendar: Calendar) -> DayKey {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    public func adding(days: Int, calendar: Calendar) -> DayKey {
        guard let next = calendar.date(byAdding: .day, value: days, to: date(calendar: calendar)) else {
            preconditionFailure("Could not add \(days) days")
        }
        return DayKey.from(next, calendar: calendar)
    }

    public func adding(months: Int, calendar: Calendar) -> DayKey {
        guard let next = calendar.date(byAdding: .month, value: months, to: date(calendar: calendar)) else {
            preconditionFailure("Could not add \(months) months")
        }
        return DayKey.from(next, calendar: calendar)
    }

    /// Whole days from this day to `other`. Negative when `other` is earlier.
    public func distance(to other: DayKey, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date(calendar: calendar))
        let end = calendar.startOfDay(for: other.date(calendar: calendar))
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    public var iso: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

public enum DayCalendar {
    public static func gregorian(secondsFromGMT: Int = 0, firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: secondsFromGMT) ?? TimeZone(identifier: "GMT")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}

public enum StepKind: String, Codable, CaseIterable, Sendable {
    case cleanser
    case toner
    case serum
    case moisturizer
    case sunscreen
    case mask
    case exfoliant
    case eyeCream
    case oil
    case mist
    case treatment
    case lipCare
    case other

    public var title: String {
        switch self {
        case .cleanser: return "Cleanser"
        case .toner: return "Toner"
        case .serum: return "Serum"
        case .moisturizer: return "Moisturizer"
        case .sunscreen: return "Sunscreen"
        case .mask: return "Mask"
        case .exfoliant: return "Exfoliant"
        case .eyeCream: return "Eye cream"
        case .oil: return "Face oil"
        case .mist: return "Mist"
        case .treatment: return "Treatment"
        case .lipCare: return "Lip care"
        case .other: return "Other"
        }
    }
}

public enum DayPart: String, Codable, CaseIterable, Sendable {
    case morning
    case evening

    public var title: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        }
    }
}

public enum FillLevel: String, Codable, CaseIterable, Sendable {
    case full
    case threeQuarters
    case half
    case quarter
    case low
    case empty

    public var title: String {
        switch self {
        case .full: return "Full"
        case .threeQuarters: return "About three quarters"
        case .half: return "About half"
        case .quarter: return "About a quarter"
        case .low: return "Almost empty"
        case .empty: return "Empty"
        }
    }

    public var fraction: Double {
        switch self {
        case .full: return 1
        case .threeQuarters: return 0.75
        case .half: return 0.5
        case .quarter: return 0.25
        case .low: return 0.12
        case .empty: return 0
        }
    }
}

public enum Scale {
    public static func dryness(_ value: Int) -> Int { min(5, max(1, value)) }
    public static func breakouts(_ value: Int) -> Int { min(3, max(0, value)) }
    public static func mood(_ value: Int) -> Int { min(5, max(1, value)) }
    public static func sleep(_ value: Int) -> Int { min(5, max(1, value)) }
}

public struct Product: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var brand: String
    public var kind: StepKind
    /// Nil while the jar is still sealed.
    public var openedOn: DayKey?
    /// Months printed as the period after opening. Zero means the jar does not show one.
    public var paoMonths: Int
    public var fill: FillLevel
    public var note: String
    public var isSample: Bool

    public init(
        id: UUID,
        name: String,
        brand: String,
        kind: StepKind,
        openedOn: DayKey?,
        paoMonths: Int,
        fill: FillLevel,
        note: String = "",
        isSample: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.kind = kind
        self.openedOn = openedOn
        self.paoMonths = paoMonths
        self.fill = fill
        self.note = note
        self.isSample = isSample
    }
}

public struct RoutineStep: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var kind: StepKind
    public var part: DayPart
    public var productID: UUID?
    public var position: Int
    public var isActive: Bool
    public var isSample: Bool

    public init(
        id: UUID,
        title: String,
        kind: StepKind,
        part: DayPart,
        productID: UUID?,
        position: Int,
        isActive: Bool = true,
        isSample: Bool = false
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.part = part
        self.productID = productID
        self.position = position
        self.isActive = isActive
        self.isSample = isSample
    }
}

public struct CheckIn: Codable, Equatable, Hashable, Sendable {
    public var day: DayKey
    public var stepID: UUID

    public init(day: DayKey, stepID: UUID) {
        self.day = day
        self.stepID = stepID
    }
}

public struct SkinNote: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: DayKey
    /// 1 comfortable … 5 very dry.
    public var dryness: Int
    /// 0 none … 3 a lot. A personal count, not a diagnosis.
    public var breakouts: Int
    /// 1 low … 5 bright.
    public var mood: Int
    /// 1 restless … 5 rested.
    public var sleep: Int
    public var text: String
    public var isSample: Bool

    public init(
        id: UUID,
        day: DayKey,
        dryness: Int,
        breakouts: Int,
        mood: Int,
        sleep: Int,
        text: String = "",
        isSample: Bool = false
    ) {
        self.id = id
        self.day = day
        self.dryness = Scale.dryness(dryness)
        self.breakouts = Scale.breakouts(breakouts)
        self.mood = Scale.mood(mood)
        self.sleep = Scale.sleep(sleep)
        self.text = text
        self.isSample = isSample
    }

    public func clamped() -> SkinNote {
        var copy = self
        copy.dryness = Scale.dryness(dryness)
        copy.breakouts = Scale.breakouts(breakouts)
        copy.mood = Scale.mood(mood)
        copy.sleep = Scale.sleep(sleep)
        return copy
    }
}

public struct ProgressPhoto: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var day: DayKey
    public var fileName: String
    public var isSample: Bool

    public init(id: UUID, day: DayKey, fileName: String, isSample: Bool = false) {
        self.id = id
        self.day = day
        self.fileName = fileName
        self.isSample = isSample
    }
}

public struct ReminderSettings: Codable, Equatable, Sendable {
    public var morningEnabled: Bool
    public var morningHour: Int
    public var morningMinute: Int
    public var eveningEnabled: Bool
    public var eveningHour: Int
    public var eveningMinute: Int

    public init(
        morningEnabled: Bool = false,
        morningHour: Int = 8,
        morningMinute: Int = 0,
        eveningEnabled: Bool = false,
        eveningHour: Int = 21,
        eveningMinute: Int = 0
    ) {
        self.morningEnabled = morningEnabled
        self.morningHour = morningHour
        self.morningMinute = morningMinute
        self.eveningEnabled = eveningEnabled
        self.eveningHour = eveningHour
        self.eveningMinute = eveningMinute
    }

    public static let off = ReminderSettings()
}

public struct Studio: Codable, Equatable, Sendable {
    public var products: [Product]
    public var steps: [RoutineStep]
    public var checks: [CheckIn]
    public var notes: [SkinNote]
    public var photos: [ProgressPhoto]
    public var reminders: ReminderSettings
    public var hapticsEnabled: Bool

    public init(
        products: [Product] = [],
        steps: [RoutineStep] = [],
        checks: [CheckIn] = [],
        notes: [SkinNote] = [],
        photos: [ProgressPhoto] = [],
        reminders: ReminderSettings = .off,
        hapticsEnabled: Bool = true
    ) {
        self.products = products
        self.steps = steps
        self.checks = checks
        self.notes = notes
        self.photos = photos
        self.reminders = reminders
        self.hapticsEnabled = hapticsEnabled
    }
}
