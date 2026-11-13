import Foundation

public struct WearDay: Equatable, Sendable {
    public var day: CalendarDay
    public var lipsticks: [Lipstick]

    public init(day: CalendarDay, lipsticks: [Lipstick]) {
        self.day = day
        self.lipsticks = lipsticks
    }
}

public struct WardrobeFilter: Equatable, Sendable {
    public var text: String
    public var finishes: Set<Finish>
    public var undertones: Set<Undertone>
    public var families: Set<ColorFamily>
    public var occasions: Set<Occasion>
    public var ownership: Ownership?

    public init(
        text: String = "",
        finishes: Set<Finish> = [],
        undertones: Set<Undertone> = [],
        families: Set<ColorFamily> = [],
        occasions: Set<Occasion> = [],
        ownership: Ownership? = nil
    ) {
        self.text = text
        self.finishes = finishes
        self.undertones = undertones
        self.families = families
        self.occasions = occasions
        self.ownership = ownership
    }

    public var isNarrowed: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
            || !finishes.isEmpty
            || !undertones.isEmpty
            || !families.isEmpty
            || !occasions.isEmpty
    }
}

public struct WardrobeLibrary: Equatable, Sendable {
    public private(set) var snapshot: WardrobeSnapshot

    public init(snapshot: WardrobeSnapshot = .empty) {
        self.snapshot = snapshot
    }

    public var lipsticks: [Lipstick] { snapshot.lipsticks }
    public var wears: [WearRecord] { snapshot.wears }

    public func lipstick(id: UUID) -> Lipstick? {
        snapshot.lipsticks.first { $0.id == id }
    }

    @discardableResult
    public mutating func add(
        _ draft: LipstickDraft,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> Lipstick {
        let lipstick = try LipstickRules.validated(
            id: id,
            name: draft.name,
            brand: draft.brand,
            finish: draft.finish,
            undertone: draft.undertone,
            colorFamily: draft.colorFamily,
            occasions: Array(draft.occasions),
            shade: draft.shade,
            swatchFileName: draft.swatchFileName,
            ownership: draft.ownership,
            createdAt: createdAt
        )
        snapshot.lipsticks.append(lipstick)
        return lipstick
    }

    public mutating func update(_ incoming: Lipstick) throws {
        guard let index = snapshot.lipsticks.firstIndex(where: { $0.id == incoming.id }) else {
            throw WardrobeError.missingLipstick
        }
        let keptCreatedAt = snapshot.lipsticks[index].createdAt
        snapshot.lipsticks[index] = try LipstickRules.validated(
            id: incoming.id,
            name: incoming.name,
            brand: incoming.brand,
            finish: incoming.finish,
            undertone: incoming.undertone,
            colorFamily: incoming.colorFamily,
            occasions: incoming.occasions,
            shade: incoming.shade,
            swatchFileName: incoming.swatchFileName,
            ownership: incoming.ownership,
            createdAt: keptCreatedAt
        )
    }

    public mutating func delete(id: UUID) throws {
        guard snapshot.lipsticks.contains(where: { $0.id == id }) else {
            throw WardrobeError.missingLipstick
        }
        snapshot.lipsticks.removeAll { $0.id == id }
        snapshot.wears.removeAll { $0.lipstickID == id }
    }

    public mutating func setOwnership(id: UUID, to ownership: Ownership) throws {
        guard let index = snapshot.lipsticks.firstIndex(where: { $0.id == id }) else {
            throw WardrobeError.missingLipstick
        }
        snapshot.lipsticks[index].ownership = ownership
    }

    public func filtered(_ filter: WardrobeFilter) -> [Lipstick] {
        let needle = filter.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matches = snapshot.lipsticks.filter { lipstick in
            if let ownership = filter.ownership, lipstick.ownership != ownership { return false }
            if !filter.finishes.isEmpty, !filter.finishes.contains(lipstick.finish) { return false }
            if !filter.undertones.isEmpty, !filter.undertones.contains(lipstick.undertone) { return false }
            if !filter.families.isEmpty, !filter.families.contains(lipstick.colorFamily) { return false }
            if !filter.occasions.isEmpty, Set(lipstick.occasions).isDisjoint(with: filter.occasions) { return false }
            if !needle.isEmpty {
                let haystack = [
                    lipstick.name,
                    lipstick.brand ?? "",
                    lipstick.finish.title,
                    lipstick.undertone.title,
                    lipstick.colorFamily.title
                ] + lipstick.occasions.map(\.title)
                let joined = haystack.joined(separator: " ").lowercased()
                if !joined.contains(needle) { return false }
            }
            return true
        }
        return matches.sorted(by: sortByName)
    }

    @discardableResult
    public mutating func markWorn(
        lipstickID: UUID,
        on day: CalendarDay,
        id: UUID = UUID()
    ) throws -> WearRecord {
        guard let lipstick = lipstick(id: lipstickID) else {
            throw WardrobeError.missingLipstick
        }
        guard lipstick.ownership == .owned else {
            throw WardrobeError.wishlistCannotBeWorn
        }
        if let existing = snapshot.wears.first(where: { $0.lipstickID == lipstickID && $0.day == day }) {
            return existing
        }
        let record = WearRecord(id: id, lipstickID: lipstickID, day: day)
        snapshot.wears.append(record)
        return record
    }

    @discardableResult
    public mutating func clearWorn(lipstickID: UUID, on day: CalendarDay) -> Bool {
        let before = snapshot.wears.count
        snapshot.wears.removeAll { $0.lipstickID == lipstickID && $0.day == day }
        return snapshot.wears.count != before
    }

    public func wornLipsticks(on day: CalendarDay) -> [Lipstick] {
        let ids = snapshot.wears.filter { $0.day == day }.map(\.lipstickID)
        let found = ids.compactMap { lipstick(id: $0) }
        return found.sorted(by: sortByName)
    }

    public func history() -> [WearDay] {
        let days = Set(snapshot.wears.map(\.day)).sorted(by: >)
        return days.map { day in
            WearDay(day: day, lipsticks: wornLipsticks(on: day))
        }
    }

    /// Latest wear on or before `day`. Future logs do not count as "already worn".
    public func lastWornDay(for lipstickID: UUID, onOrBefore day: CalendarDay) -> CalendarDay? {
        snapshot.wears
            .filter { $0.lipstickID == lipstickID && $0.day <= day && $0.day.isValid }
            .map(\.day)
            .max()
    }

    public func daysSinceLastWear(for lipstickID: UUID, on day: CalendarDay) -> Int? {
        guard let last = lastWornDay(for: lipstickID, onOrBefore: day) else { return nil }
        return last.daysUntil(day)
    }

    public func recommendations(_ query: RecommendationQuery) -> [ShadeRecommendation] {
        let capped = max(0, query.limit)
        let owned = snapshot.lipsticks.filter { $0.ownership == .owned }
        let ranked = owned.map { lipstick -> ShadeRecommendation in
            let days = daysSinceLastWear(for: lipstick.id, on: query.day)
            let score = ShadeMatch.score(lipstick: lipstick, daysSinceWorn: days, query: query)
            return ShadeRecommendation(lipstick: lipstick, score: score)
        }
        let sorted = ranked.sorted { lhs, rhs in
            if lhs.score.total != rhs.score.total { return lhs.score.total > rhs.score.total }
            return sortByName(lhs.lipstick, rhs.lipstick)
        }
        return Array(sorted.prefix(capped))
    }

    /// Fills an empty drawer once. Clearing the drawer later does not bring the samples back.
    @discardableResult
    public mutating func installStarterIfNeeded(today: CalendarDay) -> Bool {
        guard snapshot.lipsticks.isEmpty, snapshot.starterInstalled == false else { return false }
        snapshot = StarterWardrobe.make(today: today)
        return true
    }

    private func sortByName(_ lhs: Lipstick, _ rhs: Lipstick) -> Bool {
        let left = lhs.name.lowercased()
        let right = rhs.name.lowercased()
        if left == right { return lhs.id.uuidString < rhs.id.uuidString }
        return left < right
    }
}
