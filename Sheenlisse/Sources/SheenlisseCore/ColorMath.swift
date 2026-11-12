import Foundation

/// A color in straight (non-premultiplied) RGBA, channels in 0...1.
public struct RGBA: Equatable, Codable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = Self.unit(r)
        self.g = Self.unit(g)
        self.b = Self.unit(b)
        self.a = Self.unit(a)
    }

    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            r: Double((hex >> 16) & 0xFF) / 255,
            g: Double((hex >> 8) & 0xFF) / 255,
            b: Double(hex & 0xFF) / 255,
            a: alpha
        )
    }

    public static func unit(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
}

public enum BlendMode: String, Codable, Equatable {
    case sourceOver
    case multiply
    case softLight
    case overlay
}

public enum ColorBlend {
    /// Photoshop / W3C blend of two opaque channel values, then a straight alpha composite.
    public static func composite(base: RGBA, over layer: RGBA, mode: BlendMode) -> RGBA {
        let baseAlpha = RGBA.unit(base.a)
        let layerAlpha = RGBA.unit(layer.a)
        if layerAlpha <= 0 { return base }

        let blendedR = blendChannel(base.r, layer.r, mode)
        let blendedG = blendChannel(base.g, layer.g, mode)
        let blendedB = blendChannel(base.b, layer.b, mode)
        let outAlpha = layerAlpha + baseAlpha * (1 - layerAlpha)
        guard outAlpha > 0 else { return RGBA(r: 0, g: 0, b: 0, a: 0) }

        func mix(_ blended: Double, _ baseChannel: Double) -> Double {
            (blended * layerAlpha + baseChannel * baseAlpha * (1 - layerAlpha)) / outAlpha
        }
        return RGBA(
            r: mix(blendedR, base.r),
            g: mix(blendedG, base.g),
            b: mix(blendedB, base.b),
            a: outAlpha
        )
    }

    /// `opacity` is coverage, 0...1. Zero leaves the base untouched.
    public static func apply(base: RGBA, shade: RGBA, opacity: Double, mode: BlendMode) -> RGBA {
        let coverage = RGBA.unit(opacity)
        if coverage <= 0 { return base }
        var layer = shade
        layer.a = RGBA.unit(shade.a * coverage)
        return composite(base: base, over: layer, mode: mode)
    }

    static func blendChannel(_ base: Double, _ layer: Double, _ mode: BlendMode) -> Double {
        let cb = RGBA.unit(base)
        let cs = RGBA.unit(layer)
        switch mode {
        case .sourceOver:
            return cs
        case .multiply:
            return cb * cs
        case .overlay:
            if cb <= 0.5 {
                return 2 * cb * cs
            }
            return 1 - 2 * (1 - cb) * (1 - cs)
        case .softLight:
            if cs <= 0.5 {
                return cb - (1 - 2 * cs) * cb * (1 - cb)
            }
            let d: Double
            if cb <= 0.25 {
                d = ((16 * cb - 12) * cb + 4) * cb
            } else {
                d = cb.squareRoot()
            }
            return cb + (2 * cs - 1) * (d - cb)
        }
    }
}
