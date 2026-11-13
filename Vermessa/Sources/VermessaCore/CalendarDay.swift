import Foundation

/// A civil calendar date with no clock time. Wear history is stored as days,
/// so a lipstick logged twice on the same morning and evening counts once.
public struct CalendarDay: Codable, Hashable, Comparable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    /// Gregorian calendar pinned to UTC so day math does not depend on the host zone.
    public static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    public static func capturing(_ date: Date, calendar: Calendar) -> CalendarDay? {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else {
            return nil
        }
        return CalendarDay(year: year, month: month, day: day)
    }

    /// True only when the year, month, and day name a real Gregorian date.
    /// February 31 is rejected instead of rolling into March.
    public var isValid: Bool {
        guard let noon = unvalidatedNoon() else { return false }
        guard let captured = CalendarDay.capturing(noon, calendar: CalendarDay.utcCalendar()) else { return false }
        return captured == self
    }

    /// Noon on this civil day in the UTC Gregorian calendar, if the day exists.
    public func utcNoon() -> Date? {
        guard isValid else { return nil }
        return unvalidatedNoon()
    }

    /// Whole days from `self` to `other`. Negative when `other` is earlier.
    public func daysUntil(_ other: CalendarDay) -> Int? {
        guard isValid, other.isValid, let start = unvalidatedNoon(), let end = other.unvalidatedNoon() else { return nil }
        return CalendarDay.utcCalendar().dateComponents([.day], from: start, to: end).day
    }

    private func unvalidatedNoon() -> Date? {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return CalendarDay.utcCalendar().date(from: parts)
    }

    public func adding(days: Int) -> CalendarDay? {
        guard let start = utcNoon(),
              let shifted = CalendarDay.utcCalendar().date(byAdding: .day, value: days, to: start),
              let captured = CalendarDay.capturing(shifted, calendar: CalendarDay.utcCalendar())
        else { return nil }
        return captured
    }

    public var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
