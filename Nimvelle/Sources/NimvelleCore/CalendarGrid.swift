import Foundation

public struct MonthCell: Equatable, Sendable {
    public var day: DayKey
    public var inMonth: Bool

    public init(day: DayKey, inMonth: Bool) {
        self.day = day
        self.inMonth = inMonth
    }
}

public enum MonthGrid {
    /// Full weeks covering the month. Leading and trailing cells belong to the neighboring months.
    public static func weeks(year: Int, month: Int, calendar: Calendar) -> [[MonthCell]] {
        let firstDay = DayKey(year: year, month: month, day: 1)
        let firstDate = firstDay.date(calendar: calendar)
        let weekday = calendar.component(.weekday, from: firstDate)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: firstDate)?.count ?? 30
        let cellsCount = ((leading + dayCount + 6) / 7) * 7
        let start = firstDay.adding(days: -leading, calendar: calendar)
        var cells: [MonthCell] = []
        cells.reserveCapacity(cellsCount)
        for offset in 0..<cellsCount {
            let day = start.adding(days: offset, calendar: calendar)
            cells.append(MonthCell(day: day, inMonth: day.year == year && day.month == month))
        }
        var rows: [[MonthCell]] = []
        var index = 0
        while index < cells.count {
            rows.append(Array(cells[index..<(index + 7)]))
            index += 7
        }
        return rows
    }

    public static func weekdayLabels(calendar: Calendar) -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        guard symbols.count == 7 else { return ["S", "M", "T", "W", "T", "F", "S"] }
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[($0 + start) % 7] }
    }
}
