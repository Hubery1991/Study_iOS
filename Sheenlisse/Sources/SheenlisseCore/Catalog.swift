import Foundation

public enum MakeupRegion: String, Codable, CaseIterable, Equatable {
    case lipstick
    case blush
    case eyeshadow
    case eyeliner
    case brows

    public var title: String {
        switch self {
        case .lipstick: return "Lipstick"
        case .blush: return "Blush"
        case .eyeshadow: return "Eyeshadow"
        case .eyeliner: return "Eyeliner"
        case .brows: return "Brows"
        }
    }

    public var chip: String {
        switch self {
        case .lipstick: return "Lips"
        case .blush: return "Blush"
        case .eyeshadow: return "Eyes"
        case .eyeliner: return "Liner"
        case .brows: return "Brows"
        }
    }
}

public enum Finish: String, Codable, Equatable {
    case matte
    case satin
    case gloss
    case shimmer
}

public struct Shade: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var region: MakeupRegion
    public var color: RGBA
    public var finish: Finish

    public init(id: String, name: String, region: MakeupRegion, color: RGBA, finish: Finish) {
        self.id = id
        self.name = name
        self.region = region
        self.color = color
        self.finish = finish
    }
}

public struct RegionSetting: Equatable {
    public var shadeID: String
    public var intensity: Double
    public var enabled: Bool

    public init(shadeID: String, intensity: Double, enabled: Bool = true) {
        self.shadeID = shadeID
        self.intensity = min(1, max(0, intensity))
        self.enabled = enabled
    }
}

extension RegionSetting: Codable {
    enum CodingKeys: String, CodingKey {
        case shadeID
        case intensity
        case enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shadeID = try container.decode(String.self, forKey: .shadeID)
        let intensity = try container.decode(Double.self, forKey: .intensity)
        let enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.init(shadeID: shadeID, intensity: intensity, enabled: enabled)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shadeID, forKey: .shadeID)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(enabled, forKey: .enabled)
    }
}

public struct MakeupRecipe: Codable, Equatable {
    public var lipstick: RegionSetting
    public var blush: RegionSetting
    public var eyeshadow: RegionSetting
    public var eyeliner: RegionSetting
    public var brows: RegionSetting

    public init(
        lipstick: RegionSetting,
        blush: RegionSetting,
        eyeshadow: RegionSetting,
        eyeliner: RegionSetting,
        brows: RegionSetting
    ) {
        self.lipstick = lipstick
        self.blush = blush
        self.eyeshadow = eyeshadow
        self.eyeliner = eyeliner
        self.brows = brows
    }

    public func setting(for region: MakeupRegion) -> RegionSetting {
        switch region {
        case .lipstick: return lipstick
        case .blush: return blush
        case .eyeshadow: return eyeshadow
        case .eyeliner: return eyeliner
        case .brows: return brows
        }
    }

    public func updating(_ region: MakeupRegion, _ setting: RegionSetting) -> MakeupRecipe {
        var copy = self
        switch region {
        case .lipstick: copy.lipstick = setting
        case .blush: copy.blush = setting
        case .eyeshadow: copy.eyeshadow = setting
        case .eyeliner: copy.eyeliner = setting
        case .brows: copy.brows = setting
        }
        return copy
    }

    public var isBare: Bool {
        MakeupRegion.allCases.allSatisfy { region in
            let setting = setting(for: region)
            return !setting.enabled || setting.intensity <= 0
        }
    }
}

public struct DrawStyle: Equatable {
    public var mode: BlendMode
    public var opacity: Double

    public init(mode: BlendMode, opacity: Double) {
        self.mode = mode
        self.opacity = min(1, max(0, opacity))
    }
}

public enum MakeupPainter {
    public static func style(region: MakeupRegion, finish: Finish, intensity: Double, enabled: Bool) -> DrawStyle {
        let coverage = enabled ? min(1, max(0, intensity)) * cap(region: region, finish: finish) : 0
        return DrawStyle(mode: blendMode(region: region, finish: finish), opacity: coverage)
    }

    public static func cap(region: MakeupRegion, finish: Finish) -> Double {
        switch region {
        case .lipstick:
            switch finish {
            case .matte: return 0.78
            case .satin: return 0.72
            case .gloss: return 0.68
            case .shimmer: return 0.64
            }
        case .blush:
            return 0.48
        case .eyeshadow:
            return 0.70
        case .eyeliner:
            return 0.92
        case .brows:
            return 0.58
        }
    }

    public static func blendMode(region: MakeupRegion, finish: Finish) -> BlendMode {
        switch region {
        case .lipstick:
            switch finish {
            case .matte: return .multiply
            case .satin, .shimmer: return .softLight
            case .gloss: return .overlay
            }
        case .blush, .eyeshadow:
            return .softLight
        case .eyeliner:
            return .sourceOver
        case .brows:
            return .multiply
        }
    }
}

public enum ShadeCatalog {
    public static let all: [Shade] = lipstick + blush + eyeshadow + eyeliner + brows

    public static let lipstick: [Shade] = [
        shade("lip-petal", "Petal", .lipstick, 0xE7A0A8, .satin),
        shade("lip-rosewater", "Rosewater", .lipstick, 0xD9899A, .satin),
        shade("lip-coral", "Coral", .lipstick, 0xE36B55, .satin),
        shade("lip-nude-mauve", "Nude Mauve", .lipstick, 0xC48B8E, .matte),
        shade("lip-berry", "Berry", .lipstick, 0xA63D5C, .satin),
        shade("lip-deep-red", "Deep Red", .lipstick, 0x8E1E2D, .matte),
        shade("lip-brick", "Brick", .lipstick, 0xA3473A, .matte),
        shade("lip-plum", "Plum", .lipstick, 0x7A3058, .satin),
    ]

    public static let blush: [Shade] = [
        shade("blush-baby", "Baby Pink", .blush, 0xF2B6C0, .satin),
        shade("blush-peach", "Peach", .blush, 0xF0A48A, .satin),
        shade("blush-rose", "Rose", .blush, 0xE48B9A, .satin),
        shade("blush-apricot", "Apricot", .blush, 0xE8A07A, .satin),
        shade("blush-terracotta", "Terracotta", .blush, 0xC4745A, .matte),
        shade("blush-plum", "Plum Flush", .blush, 0xC46B8A, .satin),
    ]

    public static let eyeshadow: [Shade] = [
        shade("shadow-champagne", "Champagne", .eyeshadow, 0xE6C8A4, .shimmer),
        shade("shadow-taupe", "Soft Taupe", .eyeshadow, 0xC4A894, .matte),
        shade("shadow-rose", "Rose", .eyeshadow, 0xD9A0AE, .satin),
        shade("shadow-smoky", "Smoky Brown", .eyeshadow, 0x6E5346, .matte),
        shade("shadow-violet", "Violet", .eyeshadow, 0x8E74B8, .shimmer),
        shade("shadow-bronze", "Bronze", .eyeshadow, 0xA67848, .shimmer),
    ]

    public static let eyeliner: [Shade] = [
        shade("liner-brown", "Soft Brown", .eyeliner, 0x6B4A3A, .matte),
        shade("liner-charcoal", "Charcoal", .eyeliner, 0x3E3A3C, .matte),
        shade("liner-black", "Black", .eyeliner, 0x1A1A1A, .matte),
        shade("liner-plum", "Plum Ink", .eyeliner, 0x5A2A44, .matte),
    ]

    public static let brows: [Shade] = [
        shade("brow-blonde", "Soft Blonde", .brows, 0xC6A36A, .matte),
        shade("brow-taupe", "Taupe", .brows, 0xA0846C, .matte),
        shade("brow-brown", "Soft Brown", .brows, 0x7A5A42, .matte),
        shade("brow-deep", "Deep Brown", .brows, 0x4A3428, .matte),
    ]

    public static func shades(for region: MakeupRegion) -> [Shade] {
        all.filter { $0.region == region }
    }

    public static func shade(id: String) -> Shade? {
        all.first { $0.id == id }
    }

    private static func shade(
        _ id: String,
        _ name: String,
        _ region: MakeupRegion,
        _ hex: UInt32,
        _ finish: Finish
    ) -> Shade {
        Shade(id: id, name: name, region: region, color: RGBA(hex: hex), finish: finish)
    }
}

public struct Look: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var chip: String
    public var tagline: String
    public var recipe: MakeupRecipe

    public init(id: String, name: String, chip: String, tagline: String, recipe: MakeupRecipe) {
        self.id = id
        self.name = name
        self.chip = chip
        self.tagline = tagline
        self.recipe = recipe
    }
}

public enum CuratedLooks {
    public static let all: [Look] = [natural, evening, vibrant, fresh]

    public static let natural = Look(
        id: "natural",
        name: "Natural",
        chip: "Natural",
        tagline: "Soft pink, a quiet cheek, a little light on the lid.",
        recipe: recipe(
            lip: ("lip-petal", 0.62),
            blush: ("blush-baby", 0.48),
            shadow: ("shadow-champagne", 0.40),
            liner: ("liner-brown", 0.28),
            brow: ("brow-taupe", 0.50)
        )
    )

    public static let evening = Look(
        id: "evening",
        name: "Evening Glam",
        chip: "Evening",
        tagline: "A deep lip, smoky lid, and a liner that holds the eye.",
        recipe: recipe(
            lip: ("lip-deep-red", 0.90),
            blush: ("blush-rose", 0.58),
            shadow: ("shadow-smoky", 0.82),
            liner: ("liner-black", 0.78),
            brow: ("brow-deep", 0.62)
        )
    )

    public static let vibrant = Look(
        id: "vibrant",
        name: "Vibrant",
        chip: "Vibrant",
        tagline: "Coral on the mouth, violet on the lid, color turned up.",
        recipe: recipe(
            lip: ("lip-coral", 0.84),
            blush: ("blush-apricot", 0.62),
            shadow: ("shadow-violet", 0.78),
            liner: ("liner-plum", 0.55),
            brow: ("brow-brown", 0.52)
        )
    )

    public static let fresh = Look(
        id: "fresh",
        name: "Fresh",
        chip: "Fresh",
        tagline: "Nude-mauve lips, peach blush, and a clean taupe lid.",
        recipe: recipe(
            lip: ("lip-nude-mauve", 0.55),
            blush: ("blush-peach", 0.50),
            shadow: ("shadow-taupe", 0.34),
            liner: ("liner-brown", 0.22),
            brow: ("brow-blonde", 0.42)
        )
    )

    public static func look(id: String) -> Look? {
        all.first { $0.id == id }
    }

    public static var bare: MakeupRecipe {
        MakeupRecipe(
            lipstick: RegionSetting(shadeID: "lip-petal", intensity: 0, enabled: false),
            blush: RegionSetting(shadeID: "blush-baby", intensity: 0, enabled: false),
            eyeshadow: RegionSetting(shadeID: "shadow-champagne", intensity: 0, enabled: false),
            eyeliner: RegionSetting(shadeID: "liner-brown", intensity: 0, enabled: false),
            brows: RegionSetting(shadeID: "brow-taupe", intensity: 0, enabled: false)
        )
    }

    private static func recipe(
        lip: (String, Double),
        blush: (String, Double),
        shadow: (String, Double),
        liner: (String, Double),
        brow: (String, Double)
    ) -> MakeupRecipe {
        MakeupRecipe(
            lipstick: RegionSetting(shadeID: lip.0, intensity: lip.1),
            blush: RegionSetting(shadeID: blush.0, intensity: blush.1),
            eyeshadow: RegionSetting(shadeID: shadow.0, intensity: shadow.1),
            eyeliner: RegionSetting(shadeID: liner.0, intensity: liner.1),
            brows: RegionSetting(shadeID: brow.0, intensity: brow.1)
        )
    }
}
