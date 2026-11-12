import Foundation

public struct ReminderDraft: Equatable, Sendable {
    public var identifier: String
    public var title: String
    public var body: String
    public var hour: Int
    public var minute: Int
    public var fireDay: DayKey

    public init(
        identifier: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        fireDay: DayKey
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.hour = hour
        self.minute = minute
        self.fireDay = fireDay
    }

    public func fireDate(calendar: Calendar) -> Date {
        var parts = calendar.dateComponents([.year, .month, .day], from: fireDay.date(calendar: calendar))
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts) ?? fireDay.date(calendar: calendar)
    }
}

public enum ReminderPlanner {
    public static let morningPrefix = "nimvelle.reminder.morning"
    public static let eveningPrefix = "nimvelle.reminder.evening"
    /// How many upcoming mornings or evenings to place on the system calendar.
    /// The app refreshes this list whenever it opens.
    public static let horizonDays = 21

    public static func plan(
        settings: ReminderSettings,
        now: Date,
        morningComplete: Bool,
        eveningComplete: Bool,
        morningSteps: Int,
        eveningSteps: Int,
        calendar: Calendar,
        horizonDays: Int = ReminderPlanner.horizonDays
    ) -> [ReminderDraft] {
        let today = DayKey.from(now, calendar: calendar)
        let span = max(0, horizonDays)
        var drafts: [ReminderDraft] = []
        if settings.morningEnabled, morningSteps > 0,
           let clock = validClock(hour: settings.morningHour, minute: settings.morningMinute) {
            drafts.append(contentsOf: series(
                prefix: morningPrefix,
                title: "Morning routine",
                body: "Your morning steps are ready when you are.",
                hour: clock.hour,
                minute: clock.minute,
                today: today,
                now: now,
                alreadyComplete: morningComplete,
                calendar: calendar,
                horizonDays: span
            ))
        }
        if settings.eveningEnabled, eveningSteps > 0,
           let clock = validClock(hour: settings.eveningHour, minute: settings.eveningMinute) {
            drafts.append(contentsOf: series(
                prefix: eveningPrefix,
                title: "Evening routine",
                body: "A quiet reminder for your evening steps.",
                hour: clock.hour,
                minute: clock.minute,
                today: today,
                now: now,
                alreadyComplete: eveningComplete,
                calendar: calendar,
                horizonDays: span
            ))
        }
        return drafts.sorted { lhs, rhs in
            if lhs.fireDay != rhs.fireDay { return lhs.fireDay < rhs.fireDay }
            if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
            if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
            return lhs.identifier < rhs.identifier
        }
    }

    private static func validClock(hour: Int, minute: Int) -> (hour: Int, minute: Int)? {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    private static func series(
        prefix: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        today: DayKey,
        now: Date,
        alreadyComplete: Bool,
        calendar: Calendar,
        horizonDays: Int
    ) -> [ReminderDraft] {
        let first = firstFireDay(
            today: today,
            now: now,
            hour: hour,
            minute: minute,
            alreadyComplete: alreadyComplete,
            calendar: calendar
        )
        return (0..<horizonDays).map { offset in
            let day = first.adding(days: offset, calendar: calendar)
            return ReminderDraft(
                identifier: "\(prefix).\(day.iso)",
                title: title,
                body: body,
                hour: hour,
                minute: minute,
                fireDay: day
            )
        }
    }

    /// Today, when the clock time is still ahead and that routine is not finished.
    /// Tomorrow otherwise, so a finished morning does not get another nudge.
    static func firstFireDay(
        today: DayKey,
        now: Date,
        hour: Int,
        minute: Int,
        alreadyComplete: Bool,
        calendar: Calendar
    ) -> DayKey {
        var parts = calendar.dateComponents([.year, .month, .day], from: today.date(calendar: calendar))
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        let fire = calendar.date(from: parts) ?? now
        if now < fire && !alreadyComplete {
            return today
        }
        return today.adding(days: 1, calendar: calendar)
    }
}
