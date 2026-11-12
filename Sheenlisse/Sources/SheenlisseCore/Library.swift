import Foundation

public struct CompareSplit: Equatable {
    /// 0 is the left edge. Pixels at or to the right of the divider show makeup.
    public var position: Double

    public init(position: Double) {
        self.position = min(1, max(0, position))
    }

    public func showsMakeup(normalizedX: Double) -> Bool {
        normalizedX >= position
    }
}

public struct PreviewMapper: Equatable {
    public var imageWidth: Double
    public var imageHeight: Double
    public var viewWidth: Double
    public var viewHeight: Double
    public var mirrorX: Bool

    public init(imageWidth: Double, imageHeight: Double, viewWidth: Double, viewHeight: Double, mirrorX: Bool = false) {
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.viewWidth = viewWidth
        self.viewHeight = viewHeight
        self.mirrorX = mirrorX
    }

    /// Aspect-fill rect of the image inside the view. It may extend past the view.
    public var displayedImageRect: Rect2D {
        guard imageWidth > 0, imageHeight > 0, viewWidth > 0, viewHeight > 0 else {
            return Rect2D(x: 0, y: 0, width: 0, height: 0)
        }
        let scale = max(viewWidth / imageWidth, viewHeight / imageHeight)
        let displayedWidth = imageWidth * scale
        let displayedHeight = imageHeight * scale
        return Rect2D(
            x: (viewWidth - displayedWidth) / 2,
            y: (viewHeight - displayedHeight) / 2,
            width: displayedWidth,
            height: displayedHeight
        )
    }

    /// Normalized image point, origin top-left, mapped into the view.
    public func viewPoint(_ point: Point2D) -> Point2D {
        let rect = displayedImageRect
        let nx = mirrorX ? (1 - point.x) : point.x
        return Point2D(x: rect.x + nx * rect.width, y: rect.y + point.y * rect.height)
    }
}

public struct MirrorPreferences: Codable, Equatable {
    public var hapticsEnabled: Bool
    public var hasSeenCoach: Bool

    public init(hapticsEnabled: Bool = true, hasSeenCoach: Bool = false) {
        self.hapticsEnabled = hapticsEnabled
        self.hasSeenCoach = hasSeenCoach
    }

    public static let standard = MirrorPreferences()
}

public struct SavedLook: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var recipe: MakeupRecipe
    public var note: String

    public init(id: UUID = UUID(), name: String, createdAt: Date = Date(), recipe: MakeupRecipe, note: String = "") {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.recipe = recipe
        self.note = note
    }
}

public struct MirrorDocument: Codable, Equatable {
    public static let maxFavorites = 24
    public static let currentVersion = 1

    public var version: Int
    public var favorites: [SavedLook]
    public var preferences: MirrorPreferences
    public var lastRecipe: MakeupRecipe
    public var lastLookID: String?

    public init(
        version: Int = MirrorDocument.currentVersion,
        favorites: [SavedLook] = [],
        preferences: MirrorPreferences = .standard,
        lastRecipe: MakeupRecipe,
        lastLookID: String?
    ) {
        self.version = version
        self.favorites = favorites
        self.preferences = preferences
        self.lastRecipe = lastRecipe
        self.lastLookID = lastLookID
    }

    public static var initial: MirrorDocument {
        MirrorDocument(
            favorites: [],
            preferences: .standard,
            lastRecipe: CuratedLooks.natural.recipe,
            lastLookID: CuratedLooks.natural.id
        )
    }

    public static func sanitizedName(_ raw: String) -> String {
        let collapsed = raw
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Saved look" }
        return String(trimmed.prefix(40))
    }

    public mutating func save(_ look: SavedLook) {
        var stored = look
        stored.name = Self.sanitizedName(look.name)
        favorites.removeAll { $0.id == stored.id }
        favorites.insert(stored, at: 0)
        if favorites.count > Self.maxFavorites {
            favorites = Array(favorites.prefix(Self.maxFavorites))
        }
    }

    @discardableResult
    public mutating func remove(id: UUID) -> Bool {
        let before = favorites.count
        favorites.removeAll { $0.id == id }
        return favorites.count != before
    }

    @discardableResult
    public mutating func rename(id: UUID, to name: String) -> Bool {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else { return false }
        favorites[index].name = Self.sanitizedName(name)
        return true
    }

    public func encodeData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public static func decodeData(_ data: Data) throws -> MirrorDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MirrorDocument.self, from: data)
    }
}
