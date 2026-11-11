import Foundation

public enum Finger: Int, Codable, CaseIterable, Identifiable {
    case thumb = 0
    case index
    case middle
    case ring
    case pinky

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .thumb: return "Thumb"
        case .index: return "Index"
        case .middle: return "Middle"
        case .ring: return "Ring"
        case .pinky: return "Pinky"
        }
    }
}

public struct FrenchTip: Codable, Equatable {
    public var enabled: Bool
    public var colorID: String
    public var coverage: Double

    public init(enabled: Bool, colorID: String, coverage: Double) {
        self.enabled = enabled
        self.colorID = colorID
        self.coverage = FrenchTip.clamped(coverage)
    }

    public static let off = FrenchTip(enabled: false, colorID: Palette.whiteID, coverage: 0.28)

    public static func clamped(_ coverage: Double) -> Double {
        min(0.48, max(0.16, coverage))
    }
}

public struct NailGradient: Codable, Equatable {
    public var enabled: Bool
    public var endColorID: String
    public var angle: Double

    public init(enabled: Bool, endColorID: String, angle: Double) {
        self.enabled = enabled
        self.endColorID = endColorID
        self.angle = NailGradient.normalized(angle)
    }

    public static let off = NailGradient(enabled: false, endColorID: "petal", angle: 90)

    public static func normalized(_ angle: Double) -> Double {
        var value = angle.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }
}

public struct PlacedDecoration: Codable, Equatable, Identifiable {
    public var id: UUID
    public var motifID: String
    public var colorID: String
    public var x: Double
    public var y: Double
    public var scale: Double
    public var rotation: Double

    public init(id: UUID, motifID: String, colorID: String, x: Double, y: Double, scale: Double, rotation: Double) {
        self.id = id
        self.motifID = motifID
        self.colorID = colorID
        self.x = min(0.92, max(0.08, x))
        self.y = min(0.92, max(0.08, y))
        self.scale = min(1.6, max(0.4, scale))
        self.rotation = rotation
    }

    public static func automatic(motifID: String, colorID: String, index: Int, id: UUID = UUID()) -> PlacedDecoration {
        let kind = Palette.motif(id: motifID)?.kind
        let slots = [(0.50, 0.42), (0.34, 0.58), (0.66, 0.56), (0.48, 0.72)]
        let slot = slots[index % slots.count]
        let isLine = kind == .line
        return PlacedDecoration(
            id: id,
            motifID: motifID,
            colorID: colorID,
            x: isLine ? 0.5 : slot.0,
            y: isLine ? (motifID == "slant" ? 0.48 : 0.28) : slot.1,
            scale: isLine ? 1 : 0.9,
            rotation: motifID == "slant" ? -28 : 0
        )
    }
}

public struct NailDesign: Codable, Equatable {
    public static let maxDecorations = 4

    public var shape: NailShape
    public var colorID: String
    public var finish: Finish
    public var french: FrenchTip
    public var gradient: NailGradient
    public var decorations: [PlacedDecoration]

    public init(
        shape: NailShape,
        colorID: String,
        finish: Finish,
        french: FrenchTip = .off,
        gradient: NailGradient = .off,
        decorations: [PlacedDecoration] = []
    ) {
        self.shape = shape
        self.colorID = colorID
        self.finish = finish
        self.french = french
        self.gradient = gradient
        self.decorations = Array(decorations.prefix(Self.maxDecorations))
    }

    public static let bare = NailDesign(shape: .almond, colorID: Palette.balletID, finish: .gloss)

    public func has(kind: DecorationKind) -> Bool {
        decorations.contains { Palette.motif(id: $0.motifID)?.kind == kind }
    }
}

public struct Manicure: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var nails: [NailDesign]
    public var createdAt: Date

    public init(id: UUID, name: String, nails: [NailDesign], createdAt: Date) {
        self.id = id
        self.name = name
        self.nails = Manicure.padded(nails)
        self.createdAt = createdAt
    }

    public static func blank(id: UUID = UUID(), name: String = "Untitled", now: Date = Date()) -> Manicure {
        Manicure(id: id, name: name, nails: Array(repeating: .bare, count: 5), createdAt: now)
    }

    public func nail(_ finger: Finger) -> NailDesign {
        nails[finger.rawValue]
    }

    public static func padded(_ nails: [NailDesign]) -> [NailDesign] {
        if nails.count == 5 { return nails }
        if nails.count > 5 { return Array(nails.prefix(5)) }
        return nails + Array(repeating: .bare, count: 5 - nails.count)
    }
}

public struct CuratedLook: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let blurb: String
    public let manicure: Manicure

    public init(id: String, name: String, blurb: String, manicure: Manicure) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.manicure = manicure
    }
}

public enum Lookbook {
    public static let epoch = Date(timeIntervalSince1970: 0)

    public static let looks: [CuratedLook] = [
        blushPearl,
        burgundyFoil,
        colorfulBloom,
        nudeGoldLine,
        midnightChrome,
        sageCream,
        coralGlitter,
        ivoryFrench,
    ]

    public static func look(id: String) -> CuratedLook? {
        looks.first { $0.id == id }
    }

    public static let blushPearl = make(
        id: "blush-pearl",
        name: "Blush Pearl",
        blurb: "Almond nails in blush veil, a soft shimmer, and a pearl on every nail.",
        nails: Finger.allCases.map { finger in
            decorated(
                shape: .almond,
                colorID: "blush-veil",
                finish: .shimmer,
                decorations: [pearl(n: 10 + finger.rawValue, y: 0.62)]
            )
        }
    )

    public static let burgundyFoil = make(
        id: "burgundy-foil",
        name: "Burgundy Foil",
        blurb: "Long coffin nails in deep burgundy, glossy, with gold foil.",
        nails: Finger.allCases.map { finger in
            decorated(
                shape: .coffin,
                colorID: "burgundy",
                finish: .gloss,
                decorations: [
                    foil(n: 20 + finger.rawValue, motif: "flake", x: 0.38, y: 0.36),
                    foil(n: 30 + finger.rawValue, motif: "leaf", x: 0.64, y: 0.58),
                ]
            )
        }
    )

    public static let colorfulBloom = make(
        id: "colorful-bloom",
        name: "Colorful Bloom",
        blurb: "A different bright tip on each oval nail, with a tiny flower.",
        nails: [
            bloom(finger: .thumb, base: "petal", tip: "coral", flower: 40),
            bloom(finger: .index, base: "lilac", tip: "tangerine", flower: 41),
            bloom(finger: .middle, base: "sky", tip: "cherry", flower: 42),
            bloom(finger: .ring, base: "peach", tip: "violet", flower: 43),
            bloom(finger: .pinky, base: "ivory", tip: "sage", flower: 44),
        ]
    )

    public static let nudeGoldLine = make(
        id: "nude-gold-line",
        name: "Nude Gold Line",
        blurb: "A nude almond nail with a cream finish and one thin gold line.",
        nails: Finger.allCases.map { finger in
            decorated(
                shape: .almond,
                colorID: "nude",
                finish: .cream,
                decorations: [line(n: 50 + finger.rawValue)]
            )
        }
    )

    public static let midnightChrome = make(
        id: "midnight-chrome",
        name: "Midnight Chrome",
        blurb: "Stiletto nails in ink, finished like a dark mirror.",
        nails: Finger.allCases.map { finger in
            decorated(
                shape: .stiletto,
                colorID: "ink",
                finish: .chrome,
                decorations: finger == .ring ? [gem(n: 60, x: 0.5, y: 0.7)] : []
            )
        }
    )

    public static let sageCream = make(
        id: "sage-cream",
        name: "Sage Cream",
        blurb: "Square sage nails with a cream finish and nothing else.",
        nails: Array(repeating: NailDesign(shape: .square, colorID: "sage", finish: .cream), count: 5)
    )

    public static let coralGlitter = make(
        id: "coral-glitter",
        name: "Coral Glitter",
        blurb: "Oval coral nails full of glitter.",
        nails: Array(repeating: NailDesign(shape: .oval, colorID: "coral", finish: .glitter), count: 5)
    )

    public static let ivoryFrench = make(
        id: "ivory-french",
        name: "Ivory French",
        blurb: "Rounded ivory nails with a classic white tip.",
        nails: Array(
            repeating: NailDesign(
                shape: .rounded,
                colorID: "ivory",
                finish: .gloss,
                french: FrenchTip(enabled: true, colorID: "white", coverage: 0.26)
            ),
            count: 5
        )
    )

    private static func make(id: String, name: String, blurb: String, nails: [NailDesign]) -> CuratedLook {
        CuratedLook(
            id: id,
            name: name,
            blurb: blurb,
            manicure: Manicure(
                id: StableID.uuid(800 + looksCount(id)),
                name: name,
                nails: nails,
                createdAt: epoch
            )
        )
    }

    private static func looksCount(_ id: String) -> Int {
        id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private static func decorated(
        shape: NailShape,
        colorID: String,
        finish: Finish,
        french: FrenchTip = .off,
        gradient: NailGradient = .off,
        decorations: [PlacedDecoration]
    ) -> NailDesign {
        NailDesign(
            shape: shape,
            colorID: colorID,
            finish: finish,
            french: french,
            gradient: gradient,
            decorations: decorations
        )
    }

    private static func bloom(finger: Finger, base: String, tip: String, flower: Int) -> NailDesign {
        NailDesign(
            shape: .oval,
            colorID: base,
            finish: .gloss,
            french: FrenchTip(enabled: true, colorID: tip, coverage: 0.32),
            decorations: [
                PlacedDecoration(
                    id: StableID.uuid(flower),
                    motifID: "daisy",
                    colorID: tip,
                    x: 0.5,
                    y: 0.62,
                    scale: 0.85,
                    rotation: 0
                )
            ]
        )
    }

    private static func pearl(n: Int, y: Double) -> PlacedDecoration {
        PlacedDecoration(id: StableID.uuid(n), motifID: "pearl", colorID: "white", x: 0.5, y: y, scale: 0.7, rotation: 0)
    }

    private static func foil(n: Int, motif: String, x: Double, y: Double) -> PlacedDecoration {
        PlacedDecoration(id: StableID.uuid(n), motifID: motif, colorID: "gold", x: x, y: y, scale: 0.85, rotation: 12)
    }

    private static func line(n: Int) -> PlacedDecoration {
        PlacedDecoration(id: StableID.uuid(n), motifID: "tip-line", colorID: "gold", x: 0.5, y: 0.28, scale: 1, rotation: 0)
    }

    private static func gem(n: Int, x: Double, y: Double) -> PlacedDecoration {
        PlacedDecoration(id: StableID.uuid(n), motifID: "round-gem", colorID: "silver", x: x, y: y, scale: 0.75, rotation: 0)
    }
}

enum StableID {
    static func uuid(_ n: Int) -> UUID {
        let suffix = String(format: "%012d", n % 1_000_000_000_000)
        return UUID(uuidString: "A1B2C3D4-E5F6-4789-8ABC-\(suffix)")!
    }
}
