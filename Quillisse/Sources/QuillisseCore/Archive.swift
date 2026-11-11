import Foundation

public struct ClosetDocument: Codable, Equatable {
    public static let currentVersion = 1
    public static let maxLooks = 40

    public var version: Int
    public var garments: [Garment]
    public var looks: [SavedLook]
    public var wears: [WearEntry]
    public var preferences: ClosetPreferences

    public init(
        version: Int = ClosetDocument.currentVersion,
        garments: [Garment],
        looks: [SavedLook] = [],
        wears: [WearEntry] = [],
        preferences: ClosetPreferences = .standard
    ) {
        self.version = version
        self.garments = garments
        self.looks = looks
        self.wears = wears
        self.preferences = preferences
    }

    public static func fresh(on day: DayStamp, calendar: Calendar) -> ClosetDocument {
        ClosetDocument(
            garments: SeedCloset.garments,
            looks: [],
            wears: SeedCloset.sampleWears(around: day, calendar: calendar),
            preferences: .standard
        )
    }

    public func garment(_ id: UUID) -> Garment? {
        garments.first { $0.id == id }
    }

    public func resolved(_ ids: [UUID]) -> [Garment] {
        let byID = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }.sorted { $0.category.sortIndex < $1.category.sortIndex }
    }

    public func wear(on day: DayStamp) -> WearEntry? {
        wears.first { $0.day == day }
    }

    public func suggestions(on day: DayStamp, occasion: Occasion, calendar: Calendar) -> [SuggestedLook] {
        let query = SuggestQuery(
            occasion: occasion,
            weather: preferences.weather,
            season: preferences.season(on: day),
            day: day,
            repeatWindowDays: preferences.clampedWindow,
            limit: 6
        )
        return OutfitEngine.suggestions(garments: garments, wears: wears, query: query, calendar: calendar)
    }

    public mutating func upsert(_ garment: Garment) {
        if let index = garments.firstIndex(where: { $0.id == garment.id }) {
            garments[index] = garment
        } else {
            garments.insert(garment, at: 0)
        }
    }

    @discardableResult
    public mutating func removeGarment(id: UUID) -> Bool {
        let before = garments.count
        garments.removeAll { $0.id == id }
        guard garments.count != before else { return false }
        looks = looks.compactMap { look in
            var copy = look
            copy.pieceIDs.removeAll { $0 == id }
            return copy.pieceIDs.isEmpty ? nil : copy
        }
        wears = wears.compactMap { wear in
            var copy = wear
            copy.pieceIDs.removeAll { $0 == id }
            return copy.pieceIDs.isEmpty ? nil : copy
        }
        return true
    }

    public mutating func removeSamplePieces() {
        let sample = Set(garments.filter(\.isSample).map(\.id))
        garments.removeAll { sample.contains($0.id) }
        looks = looks.compactMap { look in
            var copy = look
            copy.pieceIDs.removeAll { sample.contains($0) }
            return copy.pieceIDs.isEmpty ? nil : copy
        }
        wears = wears.compactMap { wear in
            var copy = wear
            copy.pieceIDs.removeAll { sample.contains($0) }
            return copy.pieceIDs.isEmpty ? nil : copy
        }
    }

    @discardableResult
    public mutating func toggleFavorite(garment id: UUID) -> Bool {
        guard let index = garments.firstIndex(where: { $0.id == id }) else { return false }
        garments[index].isFavorite.toggle()
        return true
    }

    public mutating func saveLook(_ look: SavedLook) {
        var stored = look
        stored.name = ClosetText.name(look.name, fallback: "Saved look")
        looks.removeAll { $0.id == stored.id }
        looks.insert(stored, at: 0)
        if looks.count > Self.maxLooks {
            looks = Array(looks.prefix(Self.maxLooks))
        }
    }

    @discardableResult
    public mutating func removeLook(id: UUID) -> Bool {
        let before = looks.count
        looks.removeAll { $0.id == id }
        return looks.count != before
    }

    @discardableResult
    public mutating func toggleFavorite(look id: UUID) -> Bool {
        guard let index = looks.firstIndex(where: { $0.id == id }) else { return false }
        looks[index].isFavorite.toggle()
        return true
    }

    /// One look per day. A new log replaces whatever was already written for that day.
    @discardableResult
    public mutating func logWear(
        day: DayStamp,
        pieceIDs: [UUID],
        occasion: Occasion,
        lookID: UUID? = nil,
        note: String = ""
    ) -> WearEntry? {
        var seen = Set<UUID>()
        let kept = pieceIDs.filter { seen.insert($0).inserted && garment($0) != nil }
        guard !kept.isEmpty else { return nil }
        let trimmedNote = ClosetText.name(note, fallback: "")
        let entry = WearEntry(
            id: wear(on: day)?.id ?? UUID(),
            day: day,
            pieceIDs: kept,
            occasion: occasion,
            lookID: lookID,
            note: trimmedNote
        )
        wears.removeAll { $0.day == day }
        wears.append(entry)
        wears.sort { $0.day > $1.day }
        return entry
    }

    public mutating func clearWear(on day: DayStamp) {
        wears.removeAll { $0.day == day }
    }
}

public enum ClosetArchive {
    public static func encode(_ document: ClosetDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(document)
    }

    public static func decode(_ data: Data) throws -> ClosetDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ClosetDocument.self, from: data)
    }

    public static func load(from url: URL) -> ClosetDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }

    public static func save(_ document: ClosetDocument, to url: URL) throws {
        let data = try encode(document)
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
