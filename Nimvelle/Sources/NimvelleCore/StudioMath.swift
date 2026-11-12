import Foundation

public enum DayMark: Equatable, Sendable {
    case none
    case partial
    case complete
}

public enum ShelfFreshness: Equatable, Sendable {
    case sealed
    case untracked
    /// Days remaining, including today when it is the last day. More than the warning window.
    case good(daysLeft: Int)
    /// Inside the warning window, including the last day (zero).
    case soon(daysLeft: Int)
    case past(daysOver: Int)
}

public enum ShelfMath {
    /// How many days before the open-jar window ends Nimvelle starts a gentle warning.
    public static let warningWindowDays = 30

    public static func freshness(
        openedOn: DayKey?,
        paoMonths: Int,
        today: DayKey,
        calendar: Calendar
    ) -> ShelfFreshness {
        guard let openedOn else { return .sealed }
        guard paoMonths > 0 else { return .untracked }
        let expiry = openedOn.adding(months: paoMonths, calendar: calendar)
        let daysLeft = today.distance(to: expiry, calendar: calendar)
        if daysLeft < 0 { return .past(daysOver: -daysLeft) }
        if daysLeft <= warningWindowDays { return .soon(daysLeft: daysLeft) }
        return .good(daysLeft: daysLeft)
    }

    public static func statusLine(_ freshness: ShelfFreshness) -> String {
        switch freshness {
        case .sealed:
            return "Sealed"
        case .untracked:
            return "Opened, no period printed"
        case .good(let days), .soon(let days):
            if days == 0 { return "Open-jar window ends today" }
            if days == 1 { return "1 day left in the open-jar window" }
            return "\(days) days left in the open-jar window"
        case .past(let days):
            if days == 1 { return "1 day past the open-jar window" }
            return "\(days) days past the open-jar window"
        }
    }
}

public extension Product {
    func freshness(today: DayKey, calendar: Calendar) -> ShelfFreshness {
        ShelfMath.freshness(openedOn: openedOn, paoMonths: paoMonths, today: today, calendar: calendar)
    }

    func statusLine(today: DayKey, calendar: Calendar) -> String {
        ShelfMath.statusLine(freshness(today: today, calendar: calendar))
    }
}

public enum RoutineMath {
    public static func activeSteps(_ steps: [RoutineStep], part: DayPart? = nil) -> [RoutineStep] {
        steps
            .filter { step in
                step.isActive && (part == nil || step.part == part)
            }
            .sorted { lhs, rhs in
                if lhs.part != rhs.part { return lhs.part == .morning }
                if lhs.position != rhs.position { return lhs.position < rhs.position }
                return lhs.title < rhs.title
            }
    }

    public static func mark(on day: DayKey, steps: [RoutineStep], checks: [CheckIn], part: DayPart? = nil) -> DayMark {
        let active = activeSteps(steps, part: part)
        guard !active.isEmpty else { return .none }
        let done = active.filter { step in
            checks.contains { $0.day == day && $0.stepID == step.id }
        }.count
        if done == 0 { return .none }
        if done == active.count { return .complete }
        return .partial
    }

    /// Consecutive complete days ending today, or ending yesterday when today is still open.
    public static func currentStreak(
        today: DayKey,
        steps: [RoutineStep],
        checks: [CheckIn],
        calendar: Calendar
    ) -> Int {
        guard !activeSteps(steps).isEmpty else { return 0 }
        var cursor = today
        if mark(on: cursor, steps: steps, checks: checks) != .complete {
            cursor = cursor.adding(days: -1, calendar: calendar)
        }
        var count = 0
        while mark(on: cursor, steps: steps, checks: checks) == .complete {
            count += 1
            cursor = cursor.adding(days: -1, calendar: calendar)
            if count > 5000 { break }
        }
        return count
    }

    public static func longestStreak(steps: [RoutineStep], checks: [CheckIn], calendar: Calendar) -> Int {
        guard let start = checks.map(\.day).min(), let end = checks.map(\.day).max() else { return 0 }
        var cursor = start
        var best = 0
        var run = 0
        var guardrail = 0
        while cursor <= end && guardrail < 8000 {
            if mark(on: cursor, steps: steps, checks: checks) == .complete {
                run += 1
                if run > best { best = run }
            } else {
                run = 0
            }
            cursor = cursor.adding(days: 1, calendar: calendar)
            guardrail += 1
        }
        return best
    }

    public static func checkedCount(on day: DayKey, steps: [RoutineStep], checks: [CheckIn], part: DayPart? = nil) -> (done: Int, total: Int) {
        let active = activeSteps(steps, part: part)
        let done = active.filter { step in
            checks.contains { $0.day == day && $0.stepID == step.id }
        }.count
        return (done, active.count)
    }
}

public struct TrendPoint: Equatable, Sendable {
    public var day: DayKey
    public var dryness: Int?
    public var breakouts: Int?
    public var mood: Int?
    public var sleep: Int?

    public init(day: DayKey, dryness: Int? = nil, breakouts: Int? = nil, mood: Int? = nil, sleep: Int? = nil) {
        self.day = day
        self.dryness = dryness
        self.breakouts = breakouts
        self.mood = mood
        self.sleep = sleep
    }
}

public struct TrendSummary: Equatable, Sendable {
    public var points: [TrendPoint]
    public var notedDays: Int
    public var drynessAverage: Double?
    public var moodAverage: Double?
    public var sleepAverage: Double?
    public var breakoutDays: Int

    public init(
        points: [TrendPoint],
        notedDays: Int,
        drynessAverage: Double?,
        moodAverage: Double?,
        sleepAverage: Double?,
        breakoutDays: Int
    ) {
        self.points = points
        self.notedDays = notedDays
        self.drynessAverage = drynessAverage
        self.moodAverage = moodAverage
        self.sleepAverage = sleepAverage
        self.breakoutDays = breakoutDays
    }
}

public enum NoteTrends {
    public static func summary(
        notes: [SkinNote],
        today: DayKey,
        window: Int,
        calendar: Calendar
    ) -> TrendSummary {
        let span = max(1, window)
        var byDay: [DayKey: SkinNote] = [:]
        for note in notes {
            byDay[note.day] = note.clamped()
        }
        var points: [TrendPoint] = []
        var dryness: [Int] = []
        var mood: [Int] = []
        var sleep: [Int] = []
        var breakoutDays = 0
        for offset in stride(from: span - 1, through: 0, by: -1) {
            let day = today.adding(days: -offset, calendar: calendar)
            if let note = byDay[day] {
                let dry = Scale.dryness(note.dryness)
                let spots = Scale.breakouts(note.breakouts)
                let moodValue = Scale.mood(note.mood)
                let sleepValue = Scale.sleep(note.sleep)
                points.append(TrendPoint(day: day, dryness: dry, breakouts: spots, mood: moodValue, sleep: sleepValue))
                dryness.append(dry)
                mood.append(moodValue)
                sleep.append(sleepValue)
                if spots > 0 { breakoutDays += 1 }
            } else {
                points.append(TrendPoint(day: day))
            }
        }
        func average(_ values: [Int]) -> Double? {
            guard !values.isEmpty else { return nil }
            return Double(values.reduce(0, +)) / Double(values.count)
        }
        return TrendSummary(
            points: points,
            notedDays: dryness.count,
            drynessAverage: average(dryness),
            moodAverage: average(mood),
            sleepAverage: average(sleep),
            breakoutDays: breakoutDays
        )
    }
}

public extension Studio {
    var hasSample: Bool {
        products.contains(where: \.isSample)
            || steps.contains(where: \.isSample)
            || notes.contains(where: \.isSample)
            || photos.contains(where: \.isSample)
    }

    func product(id: UUID?) -> Product? {
        guard let id else { return nil }
        return products.first { $0.id == id }
    }

    func isChecked(day: DayKey, stepID: UUID) -> Bool {
        checks.contains { $0.day == day && $0.stepID == stepID }
    }

    func toggling(day: DayKey, stepID: UUID) -> Studio {
        var copy = self
        if let index = copy.checks.firstIndex(where: { $0.day == day && $0.stepID == stepID }) {
            copy.checks.remove(at: index)
        } else {
            copy.checks.append(CheckIn(day: day, stepID: stepID))
        }
        return copy
    }

    func markingRemaining(day: DayKey, part: DayPart) -> Studio {
        var copy = self
        for step in RoutineMath.activeSteps(steps, part: part) where !copy.isChecked(day: day, stepID: step.id) {
            copy.checks.append(CheckIn(day: day, stepID: step.id))
        }
        return copy
    }

    func saving(note: SkinNote) -> Studio {
        var copy = self
        var note = note.clamped()
        if let index = copy.notes.firstIndex(where: { $0.day == note.day }) {
            note.id = copy.notes[index].id
            note.isSample = copy.notes[index].isSample
            copy.notes[index] = note
        } else {
            copy.notes.append(note)
        }
        return copy
    }

    func deletingNote(id: UUID) -> Studio {
        var copy = self
        copy.notes.removeAll { $0.id == id }
        return copy
    }

    func adding(product: Product) -> Studio {
        var copy = self
        copy.products.append(product)
        return copy
    }

    func replacing(product: Product) -> Studio {
        var copy = self
        guard let index = copy.products.firstIndex(where: { $0.id == product.id }) else { return copy }
        copy.products[index] = product
        return copy
    }

    func deletingProduct(id: UUID) -> Studio {
        var copy = self
        copy.products.removeAll { $0.id == id }
        for index in copy.steps.indices where copy.steps[index].productID == id {
            copy.steps[index].productID = nil
        }
        return copy
    }

    func adding(step: RoutineStep) -> Studio {
        var copy = self
        var step = step
        let peers = copy.steps.filter { $0.part == step.part }
        step.position = (peers.map(\.position).max() ?? -1) + 1
        copy.steps.append(step)
        return copy
    }

    func replacing(step: RoutineStep) -> Studio {
        var copy = self
        guard let index = copy.steps.firstIndex(where: { $0.id == step.id }) else { return copy }
        copy.steps[index] = step
        return copy
    }

    func deletingStep(id: UUID) -> Studio {
        var copy = self
        copy.steps.removeAll { $0.id == id }
        copy.checks.removeAll { $0.stepID == id }
        return copy
    }

    func adding(photo: ProgressPhoto) -> Studio {
        var copy = self
        copy.photos.append(photo)
        return copy
    }

    func deletingPhoto(id: UUID) -> Studio {
        var copy = self
        copy.photos.removeAll { $0.id == id }
        return copy
    }

    func removingSample() -> Studio {
        let removedSteps = Set(steps.filter(\.isSample).map(\.id))
        let removedProducts = Set(products.filter(\.isSample).map(\.id))
        var copy = self
        copy.products.removeAll { $0.isSample }
        copy.steps.removeAll { $0.isSample }
        copy.notes.removeAll { $0.isSample }
        copy.photos.removeAll { $0.isSample }
        copy.checks.removeAll { removedSteps.contains($0.stepID) }
        for index in copy.steps.indices {
            if let productID = copy.steps[index].productID, removedProducts.contains(productID) {
                copy.steps[index].productID = nil
            }
        }
        return copy
    }

    func attentionCounts(today: DayKey, calendar: Calendar) -> (past: Int, soon: Int) {
        var past = 0
        var soon = 0
        for product in products {
            switch product.freshness(today: today, calendar: calendar) {
            case .past: past += 1
            case .soon: soon += 1
            case .sealed, .untracked, .good: break
            }
        }
        return (past, soon)
    }

    func attentionSummary(today: DayKey, calendar: Calendar) -> String? {
        let counts = attentionCounts(today: today, calendar: calendar)
        switch (counts.past, counts.soon) {
        case (0, 0):
            return nil
        case (1, 0):
            return "1 jar is past its open-jar window."
        case (let past, 0):
            return "\(past) jars are past their open-jar window."
        case (0, 1):
            return "1 jar is close to the end of its open-jar window."
        case (0, let soon):
            return "\(soon) jars are close to the end of their open-jar window."
        case (1, 1):
            return "1 jar is past its open-jar window, and 1 is close."
        case (1, let soon):
            return "1 jar is past its open-jar window, and \(soon) are close."
        case (let past, 1):
            return "\(past) jars are past their open-jar window, and 1 is close."
        case (let past, let soon):
            return "\(past) jars are past their open-jar window, and \(soon) are close."
        }
    }
}
