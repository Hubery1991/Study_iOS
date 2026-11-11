import Foundation

public struct RGBA: Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(hex: String) {
        let cleaned = hex.filter { $0.isHexDigit }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        if cleaned.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        } else {
            red = 0
            green = 0
            blue = 0
        }
    }
}

public enum ColorFamily: String, Codable, CaseIterable, Identifiable {
    case blush
    case red
    case nude
    case coral
    case berry
    case green
    case blue
    case lilac
    case gold
    case dark
    case neutral

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blush: return "Blush"
        case .red: return "Red"
        case .nude: return "Nude"
        case .coral: return "Coral"
        case .berry: return "Berry"
        case .green: return "Green"
        case .blue: return "Blue"
        case .lilac: return "Lilac"
        case .gold: return "Gold"
        case .dark: return "Dark"
        case .neutral: return "Neutral"
        }
    }
}

public struct PolishColor: Equatable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let family: ColorFamily
    public let hex: String

    public init(id: String, name: String, family: ColorFamily, hex: String) {
        self.id = id
        self.name = name
        self.family = family
        self.hex = hex
    }

    public var rgba: RGBA { RGBA(hex: hex) }
}

public enum NailShape: String, Codable, CaseIterable, Identifiable {
    case almond
    case square
    case coffin
    case oval
    case stiletto
    case rounded

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .almond: return "Almond"
        case .square: return "Square"
        case .coffin: return "Coffin"
        case .oval: return "Oval"
        case .stiletto: return "Stiletto"
        case .rounded: return "Rounded"
        }
    }
}

public enum Finish: String, Codable, CaseIterable, Identifiable {
    case gloss
    case matte
    case cream
    case chrome
    case shimmer
    case glitter

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .gloss: return "Gloss"
        case .matte: return "Matte"
        case .cream: return "Cream"
        case .chrome: return "Chrome"
        case .shimmer: return "Shimmer"
        case .glitter: return "Glitter"
        }
    }

    public var blurb: String {
        switch self {
        case .gloss: return "A clear, glassy shine"
        case .matte: return "Soft, with no reflection"
        case .cream: return "A quiet satin veil"
        case .chrome: return "A mirror of metal"
        case .shimmer: return "Fine light in the color"
        case .glitter: return "Scattered bright grains"
        }
    }
}

public enum DecorationKind: String, Codable, CaseIterable, Identifiable {
    case sticker
    case flower
    case gem
    case foil
    case pearl
    case line

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .sticker: return "Sticker"
        case .flower: return "Flower"
        case .gem: return "Gem"
        case .foil: return "Foil"
        case .pearl: return "Pearl"
        case .line: return "Line"
        }
    }

    public var plural: String {
        switch self {
        case .sticker: return "Stickers"
        case .flower: return "Flowers"
        case .gem: return "Gems"
        case .foil: return "Foil"
        case .pearl: return "Pearls"
        case .line: return "Lines"
        }
    }
}

public struct DecorationMotif: Equatable, Hashable, Identifiable {
    public let id: String
    public let kind: DecorationKind
    public let name: String

    public init(id: String, kind: DecorationKind, name: String) {
        self.id = id
        self.kind = kind
        self.name = name
    }
}

public enum Palette {
    public static let colors: [PolishColor] = [
        PolishColor(id: "blush-veil", name: "Blush Veil", family: .blush, hex: "F4C2C8"),
        PolishColor(id: "rosewater", name: "Rosewater", family: .blush, hex: "E8A0B0"),
        PolishColor(id: "petal", name: "Petal", family: .blush, hex: "F7D5DC"),
        PolishColor(id: "ballet", name: "Ballet", family: .blush, hex: "F3D3C8"),
        PolishColor(id: "nude", name: "Nude", family: .nude, hex: "E6C7B2"),
        PolishColor(id: "sand", name: "Sand", family: .nude, hex: "D9B89A"),
        PolishColor(id: "ivory", name: "Ivory", family: .nude, hex: "F6EDE4"),
        PolishColor(id: "cream", name: "Cream", family: .nude, hex: "F3E6D4"),
        PolishColor(id: "burgundy", name: "Burgundy", family: .berry, hex: "6E2433"),
        PolishColor(id: "wine", name: "Wine", family: .berry, hex: "8C2F45"),
        PolishColor(id: "cherry", name: "Cherry", family: .red, hex: "C23B4A"),
        PolishColor(id: "coral", name: "Coral", family: .coral, hex: "E9786A"),
        PolishColor(id: "peach", name: "Peach", family: .coral, hex: "F0A48A"),
        PolishColor(id: "tangerine", name: "Tangerine", family: .coral, hex: "E07A4C"),
        PolishColor(id: "sage", name: "Sage", family: .green, hex: "8FA88A"),
        PolishColor(id: "moss", name: "Moss", family: .green, hex: "5E7A62"),
        PolishColor(id: "sea", name: "Sea Glass", family: .blue, hex: "7EAEA4"),
        PolishColor(id: "sky", name: "Sky", family: .blue, hex: "8EB4D4"),
        PolishColor(id: "lilac", name: "Lilac", family: .lilac, hex: "C7B0D6"),
        PolishColor(id: "violet", name: "Violet", family: .lilac, hex: "7A5C8A"),
        PolishColor(id: "ink", name: "Ink", family: .dark, hex: "2A2428"),
        PolishColor(id: "plum", name: "Plum", family: .dark, hex: "4A2C40"),
        PolishColor(id: "gold", name: "Gold", family: .gold, hex: "C6A15B"),
        PolishColor(id: "champagne", name: "Champagne", family: .gold, hex: "E4D0A8"),
        PolishColor(id: "silver", name: "Silver", family: .neutral, hex: "C9CDD4"),
        PolishColor(id: "white", name: "French White", family: .neutral, hex: "F7F4F1"),
    ]

    public static let motifs: [DecorationMotif] = [
        DecorationMotif(id: "heart", kind: .sticker, name: "Heart"),
        DecorationMotif(id: "star", kind: .sticker, name: "Star"),
        DecorationMotif(id: "bow", kind: .sticker, name: "Bow"),
        DecorationMotif(id: "daisy", kind: .flower, name: "Daisy"),
        DecorationMotif(id: "blossom", kind: .flower, name: "Blossom"),
        DecorationMotif(id: "round-gem", kind: .gem, name: "Round gem"),
        DecorationMotif(id: "marquise", kind: .gem, name: "Marquise"),
        DecorationMotif(id: "flake", kind: .foil, name: "Flake"),
        DecorationMotif(id: "leaf", kind: .foil, name: "Leaf"),
        DecorationMotif(id: "pearl", kind: .pearl, name: "Pearl"),
        DecorationMotif(id: "tip-line", kind: .line, name: "Tip line"),
        DecorationMotif(id: "slant", kind: .line, name: "Slant"),
    ]

    public static func color(id: String) -> PolishColor? {
        colors.first { $0.id == id }
    }

    public static func motif(id: String) -> DecorationMotif? {
        motifs.first { $0.id == id }
    }

    public static let balletID = "ballet"
    public static let whiteID = "white"
    public static let goldID = "gold"
}
