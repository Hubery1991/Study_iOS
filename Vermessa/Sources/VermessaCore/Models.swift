import Foundation

public enum Finish: String, Codable, CaseIterable, Sendable {
    case matte, satin, cream, gloss, sheer, stain

    public var title: String {
        switch self {
        case .matte: return "Matte"
        case .satin: return "Satin"
        case .cream: return "Cream"
        case .gloss: return "Gloss"
        case .sheer: return "Sheer"
        case .stain: return "Stain"
        }
    }
}

public enum Undertone: String, Codable, CaseIterable, Sendable {
    case warm, cool, neutral

    public var title: String {
        switch self {
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .neutral: return "Neutral"
        }
    }
}

public enum ColorFamily: String, Codable, CaseIterable, Sendable {
    case red, berry, pink, nude, coral, brown, plum, rose, wine, mauve

    public var title: String {
        switch self {
        case .red: return "Red"
        case .berry: return "Berry"
        case .pink: return "Pink"
        case .nude: return "Nude"
        case .coral: return "Coral"
        case .brown: return "Brown"
        case .plum: return "Plum"
        case .rose: return "Rose"
        case .wine: return "Wine"
        case .mauve: return "Mauve"
        }
    }
}

public enum Occasion: String, Codable, CaseIterable, Sendable {
    case everyday, office, date, evening, wedding, brunch, holiday, photos

    public var title: String {
        switch self {
        case .everyday: return "Everyday"
        case .office: return "Office"
        case .date: return "Date"
        case .evening: return "Evening"
        case .wedding: return "Wedding"
        case .brunch: return "Brunch"
        case .holiday: return "Holiday"
        case .photos: return "Photos"
        }
    }
}

public enum Ownership: String, Codable, CaseIterable, Sendable {
    case owned
    case wishlist

    public var title: String {
        switch self {
        case .owned: return "In the drawer"
        case .wishlist: return "Wishlist"
        }
    }
}

public enum WardrobeError: Error, Equatable, Sendable {
    case emptyName
    case missingLipstick
    case wishlistCannotBeWorn
    case shadeOutOfRange
    case invalidHex
    case unsafeFileName

    public var message: String {
        switch self {
        case .emptyName:
            return "Give this lipstick a name."
        case .missingLipstick:
            return "That lipstick is no longer in the drawer."
        case .wishlistCannotBeWorn:
            return "Move a wishlist shade into the drawer before logging it as worn."
        case .shadeOutOfRange:
            return "Shade color channels have to stay between 0 and 255."
        case .invalidHex:
            return "Enter a shade as six hex digits, such as 6E2436."
        case .unsafeFileName:
            return "The photo file name has to stay inside the app folder."
        }
    }
}

public struct ShadeColor: Codable, Hashable, Sendable {
    public var red: Int
    public var green: Int
    public var blue: Int

    public init(red: Int, green: Int, blue: Int) throws {
        guard (0...255).contains(red), (0...255).contains(green), (0...255).contains(blue) else {
            throw WardrobeError.shadeOutOfRange
        }
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(hex: String) throws {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16), cleaned.allSatisfy({ $0.isHexDigit }) else {
            throw WardrobeError.invalidHex
        }
        try self.init(
            red: (value >> 16) & 0xFF,
            green: (value >> 8) & 0xFF,
            blue: value & 0xFF
        )
    }

    public var hex: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }

    /// Approximate sRGB luminance in 0...1, using the Rec. 709 coefficients without gamma.
    public var relativeLuminance: Double {
        (0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)) / 255.0
    }

    public var prefersLightText: Bool {
        relativeLuminance < 0.45
    }
}

public struct Lipstick: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var brand: String?
    public var finish: Finish
    public var undertone: Undertone
    public var colorFamily: ColorFamily
    public var occasions: [Occasion]
    public var shade: ShadeColor
    public var swatchFileName: String?
    public var ownership: Ownership
    public var createdAt: Date

    public init(
        id: UUID,
        name: String,
        brand: String?,
        finish: Finish,
        undertone: Undertone,
        colorFamily: ColorFamily,
        occasions: [Occasion],
        shade: ShadeColor,
        swatchFileName: String?,
        ownership: Ownership,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.finish = finish
        self.undertone = undertone
        self.colorFamily = colorFamily
        self.occasions = occasions
        self.shade = shade
        self.swatchFileName = swatchFileName
        self.ownership = ownership
        self.createdAt = createdAt
    }
}

public struct LipstickDraft: Equatable, Sendable {
    public var name: String
    public var brand: String
    public var finish: Finish
    public var undertone: Undertone
    public var colorFamily: ColorFamily
    public var occasions: Set<Occasion>
    public var shade: ShadeColor
    public var swatchFileName: String?
    public var ownership: Ownership

    public init(
        name: String,
        brand: String = "",
        finish: Finish,
        undertone: Undertone,
        colorFamily: ColorFamily,
        occasions: Set<Occasion> = [],
        shade: ShadeColor,
        swatchFileName: String? = nil,
        ownership: Ownership
    ) {
        self.name = name
        self.brand = brand
        self.finish = finish
        self.undertone = undertone
        self.colorFamily = colorFamily
        self.occasions = occasions
        self.shade = shade
        self.swatchFileName = swatchFileName
        self.ownership = ownership
    }
}

public struct WearRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var lipstickID: UUID
    public var day: CalendarDay

    public init(id: UUID, lipstickID: UUID, day: CalendarDay) {
        self.id = id
        self.lipstickID = lipstickID
        self.day = day
    }
}

public struct WardrobeSnapshot: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var lipsticks: [Lipstick]
    public var wears: [WearRecord]
    public var starterInstalled: Bool

    public static let currentFormat = 1

    public static let empty = WardrobeSnapshot(
        formatVersion: WardrobeSnapshot.currentFormat,
        lipsticks: [],
        wears: [],
        starterInstalled: false
    )

    public init(formatVersion: Int = WardrobeSnapshot.currentFormat, lipsticks: [Lipstick], wears: [WearRecord], starterInstalled: Bool) {
        self.formatVersion = formatVersion
        self.lipsticks = lipsticks
        self.wears = wears
        self.starterInstalled = starterInstalled
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion, lipsticks, wears, starterInstalled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .formatVersion)
        guard version == WardrobeSnapshot.currentFormat else {
            throw DecodingError.dataCorruptedError(
                forKey: .formatVersion,
                in: container,
                debugDescription: "Unsupported drawer format \(version)."
            )
        }
        formatVersion = version
        lipsticks = try container.decode([Lipstick].self, forKey: .lipsticks)
        wears = try container.decode([WearRecord].self, forKey: .wears)
        starterInstalled = try container.decode(Bool.self, forKey: .starterInstalled)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formatVersion, forKey: .formatVersion)
        try container.encode(lipsticks, forKey: .lipsticks)
        try container.encode(wears, forKey: .wears)
        try container.encode(starterInstalled, forKey: .starterInstalled)
    }
}

enum LipstickRules {
    static func validated(
        id: UUID,
        name: String,
        brand: String?,
        finish: Finish,
        undertone: Undertone,
        colorFamily: ColorFamily,
        occasions: [Occasion],
        shade: ShadeColor,
        swatchFileName: String?,
        ownership: Ownership,
        createdAt: Date
    ) throws -> Lipstick {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw WardrobeError.emptyName }

        let trimmedBrand = brand?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let storedBrand = trimmedBrand.isEmpty ? nil : trimmedBrand

        let ordered = Occasion.allCases.filter { occasions.contains($0) }
        let fileName = try sanitizedFileName(swatchFileName)

        return Lipstick(
            id: id,
            name: trimmedName,
            brand: storedBrand,
            finish: finish,
            undertone: undertone,
            colorFamily: colorFamily,
            occasions: ordered,
            shade: shade,
            swatchFileName: fileName,
            ownership: ownership,
            createdAt: createdAt
        )
    }

    static func sanitizedFileName(_ raw: String?) throws -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let forbidden = trimmed.contains("/") || trimmed.contains("\\") || trimmed.contains("..") || trimmed.hasPrefix(".")
        if forbidden { throw WardrobeError.unsafeFileName }
        return trimmed
    }
}
