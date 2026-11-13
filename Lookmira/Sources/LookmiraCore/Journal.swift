import Foundation

public enum JournalError: Error, Equatable, Sendable {
    case invalid(LookDraftError)
    case missingLook
    case duplicateLook

    public var message: String {
        switch self {
        case .invalid(let error):
            return error.message
        case .missingLook:
            return "That look is no longer in the diary."
        case .duplicateLook:
            return "That look is already saved."
        }
    }
}

public enum LibraryState: Equatable, Sendable {
    case emptyDiary
    case noMatches
    case matches([MakeupLook])
}

public struct LookJournal: Equatable, Codable, Sendable {
    public private(set) var looks: [MakeupLook]

    public init(looks: [MakeupLook] = []) {
        self.looks = looks
    }

    private enum CodingKeys: String, CodingKey {
        case looks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        looks = try container.decodeIfPresent([MakeupLook].self, forKey: .looks) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(looks, forKey: .looks)
    }

    public func look(_ id: UUID) -> MakeupLook? {
        looks.first { $0.id == id }
    }

    @discardableResult
    public mutating func add(
        _ draft: LookDraft,
        id: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws -> MakeupLook {
        if looks.contains(where: { $0.id == id }) {
            throw JournalError.duplicateLook
        }
        let validated = try validate(draft)
        let look = MakeupLook(
            id: id,
            title: validated.title,
            wornOn: calendar.startOfDay(for: validated.wornOn),
            styleTags: validated.styleTags,
            products: validated.products,
            notes: validated.notes,
            isFavorite: validated.isFavorite,
            photoFileName: validated.photoFileName,
            recreatedFrom: nil,
            createdAt: now,
            updatedAt: now
        )
        looks.append(look)
        return look
    }

    @discardableResult
    public mutating func update(
        _ id: UUID,
        with draft: LookDraft,
        now: Date,
        calendar: Calendar
    ) throws -> MakeupLook {
        guard let index = looks.firstIndex(where: { $0.id == id }) else {
            throw JournalError.missingLook
        }
        let validated = try validate(draft)
        let existing = looks[index]
        let updated = MakeupLook(
            id: existing.id,
            title: validated.title,
            wornOn: calendar.startOfDay(for: validated.wornOn),
            styleTags: validated.styleTags,
            products: validated.products,
            notes: validated.notes,
            isFavorite: validated.isFavorite,
            photoFileName: validated.photoFileName,
            recreatedFrom: existing.recreatedFrom,
            createdAt: existing.createdAt,
            updatedAt: now
        )
        looks[index] = updated
        return updated
    }

    @discardableResult
    public mutating func delete(_ id: UUID) throws -> MakeupLook {
        guard let index = looks.firstIndex(where: { $0.id == id }) else {
            throw JournalError.missingLook
        }
        return looks.remove(at: index)
    }

    @discardableResult
    public mutating func setFavorite(_ id: UUID, _ favorite: Bool, now: Date) throws -> MakeupLook {
        guard let index = looks.firstIndex(where: { $0.id == id }) else {
            throw JournalError.missingLook
        }
        looks[index].isFavorite = favorite
        looks[index].updatedAt = now
        return looks[index]
    }

    @discardableResult
    public mutating func recreate(
        _ id: UUID,
        on day: Date,
        now: Date,
        calendar: Calendar,
        newID: UUID = UUID()
    ) throws -> MakeupLook {
        guard let source = look(id) else {
            throw JournalError.missingLook
        }
        if looks.contains(where: { $0.id == newID }) {
            throw JournalError.duplicateLook
        }
        let copiedProducts = source.products.map {
            UsedProduct(id: UUID(), name: $0.name, kind: $0.kind)
        }
        let look = MakeupLook(
            id: newID,
            title: source.title,
            wornOn: calendar.startOfDay(for: day),
            styleTags: source.styleTags,
            products: copiedProducts,
            notes: source.notes,
            isFavorite: false,
            photoFileName: source.photoFileName,
            recreatedFrom: source.id,
            createdAt: now,
            updatedAt: now
        )
        looks.append(look)
        return look
    }

    public func looks(on day: Date, calendar: Calendar) -> [MakeupLook] {
        looks
            .filter { calendar.isDate($0.wornOn, inSameDayAs: day) }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    public func favorites() -> [MakeupLook] {
        looks.filter(\.isFavorite).sorted(by: Self.recentlyWorn)
    }

    public func recents(limit: Int) -> [MakeupLook] {
        let capped = max(0, limit)
        return looks.sorted(by: Self.recentlyWorn).prefix(capped).map { $0 }
    }

    public func library(text: String, tag: StyleTag?) -> LibraryState {
        LibraryQuery.state(allLooks: looks, text: text, tag: tag)
    }

    public func photoFileNamesInUse() -> Set<String> {
        Set(looks.compactMap(\.photoFileName))
    }

    private func validate(_ draft: LookDraft) throws -> ValidatedLook {
        do {
            return try draft.validate()
        } catch let error as LookDraftError {
            throw JournalError.invalid(error)
        }
    }

    static func recentlyWorn(_ lhs: MakeupLook, _ rhs: MakeupLook) -> Bool {
        if lhs.wornOn != rhs.wornOn { return lhs.wornOn > rhs.wornOn }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}

public enum LibraryQuery {
    public static func matches(in looks: [MakeupLook], text: String, tag: StyleTag?) -> [MakeupLook] {
        let tokens = text
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        return looks
            .filter { look in
                if let tag, !look.styleTags.contains(tag) {
                    return false
                }
                if tokens.isEmpty {
                    return true
                }
                let haystack = haystack(for: look)
                return tokens.allSatisfy { haystack.contains($0) }
            }
            .sorted(by: LookJournal.recentlyWorn)
    }

    public static func state(allLooks: [MakeupLook], text: String, tag: StyleTag?) -> LibraryState {
        if allLooks.isEmpty {
            return .emptyDiary
        }
        let found = matches(in: allLooks, text: text, tag: tag)
        if found.isEmpty {
            return .noMatches
        }
        return .matches(found)
    }

    static func haystack(for look: MakeupLook) -> String {
        var parts = [look.title, look.notes]
        for tag in look.styleTags {
            parts.append(tag.title)
            parts.append(tag.rawValue)
        }
        for product in look.products {
            parts.append(product.name)
            parts.append(product.kind.title)
            parts.append(product.kind.rawValue)
        }
        return parts.joined(separator: "\n").lowercased()
    }
}

public struct MonthCell: Equatable, Sendable {
    public var date: Date
    public var dayNumber: Int
    public var isInMonth: Bool
    public var lookCount: Int
}

public struct MonthPage: Equatable, Sendable {
    public var monthStart: Date
    public var title: String
    public var weekdaySymbols: [String]
    public var cells: [MonthCell]
}

public enum DiaryDates {
    public static func monthTitle(_ date: Date, calendar: Calendar) -> String {
        formatted(date, "LLLL yyyy", calendar: calendar)
    }

    public static func dayTitle(_ date: Date, calendar: Calendar) -> String {
        formatted(date, "EEEE, MMMM d", calendar: calendar)
    }

    public static func page(containing day: Date, looks: [MakeupLook], calendar: Calendar) -> MonthPage {
        let parts = calendar.dateComponents([.year, .month], from: day)
        let monthStart = calendar.date(from: parts) ?? calendar.startOfDay(for: day)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) ?? monthStart
        let occupied = leading + dayCount
        let rows = Int((Double(occupied) / 7.0).rounded(.up))
        let total = max(rows, 1) * 7

        var counts: [Date: Int] = [:]
        for look in looks {
            let key = calendar.startOfDay(for: look.wornOn)
            guard calendar.isDate(key, equalTo: monthStart, toGranularity: .month) else { continue }
            counts[key, default: 0] += 1
        }

        var cells: [MonthCell] = []
        cells.reserveCapacity(total)
        for offset in 0..<total {
            let date = calendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
            let inMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            let key = calendar.startOfDay(for: date)
            cells.append(
                MonthCell(
                    date: date,
                    dayNumber: calendar.component(.day, from: date),
                    isInMonth: inMonth,
                    lookCount: inMonth ? (counts[key] ?? 0) : 0
                )
            )
        }

        return MonthPage(
            monthStart: monthStart,
            title: monthTitle(monthStart, calendar: calendar),
            weekdaySymbols: weekdayLabels(calendar: calendar),
            cells: cells
        )
    }

    static func weekdayLabels(calendar: Calendar) -> [String] {
        let english = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let start = max(1, min(7, calendar.firstWeekday)) - 1
        return (0..<7).map { english[($0 + start) % 7] }
    }

    private static func formatted(_ date: Date, _ format: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

public enum ReminderError: Error, Equatable, Sendable {
    case hourOutOfRange
    case minuteOutOfRange

    public var message: String {
        switch self {
        case .hourOutOfRange:
            return "Choose an hour from 12 AM through 11 PM."
        case .minuteOutOfRange:
            return "Choose a minute from 0 through 59."
        }
    }
}

public struct ReminderPreference: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int

    public static let off = ReminderPreference(isEnabled: false, hour: 20, minute: 0)

    public init(isEnabled: Bool, hour: Int, minute: Int) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
    }

    public func validated() throws -> ReminderPreference {
        if !(0...23).contains(hour) {
            throw ReminderError.hourOutOfRange
        }
        if !(0...59).contains(minute) {
            throw ReminderError.minuteOutOfRange
        }
        return self
    }

    public func nextFireDate(after now: Date, calendar: Calendar) -> Date? {
        guard isEnabled, (try? validated()) != nil else { return nil }
        var parts = calendar.dateComponents([.year, .month, .day], from: now)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        guard let today = calendar.date(from: parts) else { return nil }
        if today > now {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }
}
