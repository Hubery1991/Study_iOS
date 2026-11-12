import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct Point2D: Equatable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: Point2D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

public struct Rect2D: Equatable, Codable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: Double { x }
    public var maxX: Double { x + width }
    public var minY: Double { y }
    public var maxY: Double { y + height }
    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
}

/// Landmarks in a normalized image. Origin is the top-left. Y grows downward.
public struct FaceLandmarks: Equatable {
    public var bounds: Rect2D
    public var contour: [Point2D]
    public var leftEye: [Point2D]
    public var rightEye: [Point2D]
    public var leftBrow: [Point2D]
    public var rightBrow: [Point2D]
    public var outerLips: [Point2D]
    public var innerLips: [Point2D]

    public init(
        bounds: Rect2D,
        contour: [Point2D],
        leftEye: [Point2D],
        rightEye: [Point2D],
        leftBrow: [Point2D],
        rightBrow: [Point2D],
        outerLips: [Point2D],
        innerLips: [Point2D] = []
    ) {
        self.bounds = bounds
        self.contour = contour
        self.leftEye = leftEye
        self.rightEye = rightEye
        self.leftBrow = leftBrow
        self.rightBrow = rightBrow
        self.outerLips = outerLips
        self.innerLips = innerLips
    }
}

public struct MakeupGeometry: Equatable {
    public var lipsOuter: [Point2D]
    public var lipsInner: [Point2D]
    public var leftCheek: [Point2D]
    public var rightCheek: [Point2D]
    public var leftLid: [Point2D]
    public var rightLid: [Point2D]
    public var leftLiner: [Point2D]
    public var rightLiner: [Point2D]
    public var leftBrow: [Point2D]
    public var rightBrow: [Point2D]

    public init(
        lipsOuter: [Point2D],
        lipsInner: [Point2D],
        leftCheek: [Point2D],
        rightCheek: [Point2D],
        leftLid: [Point2D],
        rightLid: [Point2D],
        leftLiner: [Point2D],
        rightLiner: [Point2D],
        leftBrow: [Point2D],
        rightBrow: [Point2D]
    ) {
        self.lipsOuter = lipsOuter
        self.lipsInner = lipsInner
        self.leftCheek = leftCheek
        self.rightCheek = rightCheek
        self.leftLid = leftLid
        self.rightLid = rightLid
        self.leftLiner = leftLiner
        self.rightLiner = rightLiner
        self.leftBrow = leftBrow
        self.rightBrow = rightBrow
    }
}

public enum RegionBuilder {
    public static let minimumFaceWidth = 0.12

    public static func ellipse(center: Point2D, rx: Double, ry: Double, samples: Int = 24) -> [Point2D] {
        let count = max(8, samples)
        return (0..<count).map { index in
            let theta = Double(index) / Double(count) * 2 * Double.pi
            return Point2D(x: center.x + rx * cos(theta), y: center.y + ry * sin(theta))
        }
    }

    public static func geometry(from face: FaceLandmarks) -> MakeupGeometry? {
        guard face.bounds.width >= minimumFaceWidth, face.bounds.height > 0 else { return nil }
        guard face.outerLips.count >= 6 else { return nil }
        guard face.leftEye.count >= 4, face.rightEye.count >= 4 else { return nil }
        guard face.leftBrow.count >= 3, face.rightBrow.count >= 3 else { return nil }

        let leftCheek = cheek(eye: face.leftEye, lips: face.outerLips, face: face, side: -1)
        let rightCheek = cheek(eye: face.rightEye, lips: face.outerLips, face: face, side: 1)
        guard leftCheek.count >= 8, rightCheek.count >= 8 else { return nil }

        return MakeupGeometry(
            lipsOuter: face.outerLips,
            lipsInner: face.innerLips.count >= 3 ? face.innerLips : [],
            leftCheek: leftCheek,
            rightCheek: rightCheek,
            leftLid: lid(eye: face.leftEye, brow: face.leftBrow),
            rightLid: lid(eye: face.rightEye, brow: face.rightBrow),
            leftLiner: liner(eye: face.leftEye),
            rightLiner: liner(eye: face.rightEye),
            leftBrow: face.leftBrow,
            rightBrow: face.rightBrow
        )
    }

    private static func cheek(eye: [Point2D], lips: [Point2D], face: FaceLandmarks, side: Double) -> [Point2D] {
        guard let eyeOuter = eye.min(by: { abs($0.x - (side < 0 ? face.bounds.minX : face.bounds.maxX)) < abs($1.x - (side < 0 ? face.bounds.minX : face.bounds.maxX)) }) else {
            return []
        }
        guard let mouth = lips.min(by: { abs($0.x - eyeOuter.x) < abs($1.x - eyeOuter.x) }) else {
            return []
        }
        let center = Point2D(
            x: (eyeOuter.x + mouth.x) / 2 + side * face.bounds.width * 0.06,
            y: (eyeOuter.y + mouth.y) / 2 + face.bounds.height * 0.02
        )
        return ellipse(
            center: center,
            rx: face.bounds.width * 0.11,
            ry: face.bounds.height * 0.065,
            samples: 20
        )
    }

    private static func lid(eye: [Point2D], brow: [Point2D]) -> [Point2D] {
        let eyeTop = eye.map(\.y).min() ?? 0
        let browBottom = brow.map(\.y).max() ?? eyeTop
        let gap = max(0.008, eyeTop - browBottom)
        let mid = eye.map(\.y).reduce(0, +) / Double(eye.count)
        return eye.map { point in
            guard point.y <= mid else { return point }
            return Point2D(x: point.x, y: point.y - gap * 0.65)
        }
    }

    private static func liner(eye: [Point2D]) -> [Point2D] {
        let mid = eye.map(\.y).reduce(0, +) / Double(eye.count)
        let upper = eye.filter { $0.y <= mid + 0.002 }
        let source = upper.count >= 2 ? upper : eye
        return source.sorted { $0.x < $1.x }
    }
}

public struct FaceMetrics: Equatable {
    public var length: Double
    public var cheekWidth: Double
    public var foreheadWidth: Double
    public var jawWidth: Double

    public init(length: Double, cheekWidth: Double, foreheadWidth: Double, jawWidth: Double) {
        self.length = length
        self.cheekWidth = cheekWidth
        self.foreheadWidth = foreheadWidth
        self.jawWidth = jawWidth
    }
}

public enum FaceShape: String, Codable, CaseIterable, Equatable {
    case oval
    case round
    case square
    case heart
    case oblong

    public var title: String {
        switch self {
        case .oval: return "Oval"
        case .round: return "Round"
        case .square: return "Square"
        case .heart: return "Heart"
        case .oblong: return "Oblong"
        }
    }
}

public enum FaceShapeClassifier {
    /// Geometric heuristic for a starting look. Not a measurement of a person.
    public static func classify(_ metrics: FaceMetrics) -> FaceShape {
        guard metrics.cheekWidth > 0 else { return .oval }
        let ratio = metrics.length / metrics.cheekWidth
        let jawRatio = metrics.jawWidth / metrics.cheekWidth
        let foreheadRatio = metrics.foreheadWidth / metrics.cheekWidth
        if ratio >= 1.45 { return .oblong }
        if foreheadRatio >= 0.92 && jawRatio <= 0.80 { return .heart }
        if ratio <= 1.20 && jawRatio >= 0.88 { return .round }
        if ratio <= 1.35 && jawRatio >= 0.90 && foreheadRatio >= 0.88 { return .square }
        return .oval
    }

    public static func metrics(from face: FaceLandmarks) -> FaceMetrics? {
        guard face.bounds.height > 0, face.contour.count >= 4 else { return nil }
        guard face.leftBrow.count >= 2, face.rightBrow.count >= 2 else { return nil }
        let xs = face.contour.map(\.x)
        guard let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return nil }
        let browXs = (face.leftBrow + face.rightBrow).map(\.x)
        guard let browMin = browXs.min(), let browMax = browXs.max(), browMax > browMin else { return nil }
        let ys = face.contour.map(\.y)
        guard let minY = ys.min(), let maxY = ys.max(), maxY > minY else { return nil }
        let jawLine = minY + (maxY - minY) * 0.70
        let jawXs = face.contour.filter { $0.y >= jawLine }.map(\.x)
        guard let jawMin = jawXs.min(), let jawMax = jawXs.max(), jawMax > jawMin else { return nil }
        return FaceMetrics(
            length: face.bounds.height,
            cheekWidth: maxX - minX,
            foreheadWidth: browMax - browMin,
            jawWidth: jawMax - jawMin
        )
    }

    public static func shape(of face: FaceLandmarks) -> FaceShape? {
        guard let metrics = metrics(from: face) else { return nil }
        return classify(metrics)
    }
}

public struct SkinSample: Equatable {
    public var r: Double
    public var g: Double
    public var b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
}

public enum SkinTone: String, Codable, CaseIterable, Equatable {
    case fair
    case light
    case medium
    case tan
    case deep
    case rich

    public var title: String {
        switch self {
        case .fair: return "Fair"
        case .light: return "Light"
        case .medium: return "Medium"
        case .tan: return "Tan"
        case .deep: return "Deep"
        case .rich: return "Rich"
        }
    }
}

public enum SkinToneClassifier {
    public static func luminance(_ sample: SkinSample) -> Double {
        0.2126 * sample.r + 0.7152 * sample.g + 0.0722 * sample.b
    }

    public static func isLikelySkin(_ sample: SkinSample) -> Bool {
        let y = luminance(sample)
        if y < 0.08 || y > 0.96 { return false }
        if sample.b > sample.r + 0.08 { return false }
        if sample.g > sample.r + 0.12 { return false }
        return true
    }

    public static func classify(_ sample: SkinSample) -> SkinTone {
        switch luminance(sample) {
        case 0.72...: return .fair
        case 0.60..<0.72: return .light
        case 0.48..<0.60: return .medium
        case 0.36..<0.48: return .tan
        case 0.22..<0.36: return .deep
        default: return .rich
        }
    }

    public static func average(_ samples: [SkinSample]) -> SkinSample? {
        guard !samples.isEmpty else { return nil }
        let count = Double(samples.count)
        return SkinSample(
            r: samples.reduce(0) { $0 + $1.r } / count,
            g: samples.reduce(0) { $0 + $1.g } / count,
            b: samples.reduce(0) { $0 + $1.b } / count
        )
    }

    /// Drops samples that fail the skin gate. Returns nil when none remain.
    public static func averageSkin(_ samples: [SkinSample]) -> SkinSample? {
        average(samples.filter(isLikelySkin))
    }
}

public struct FaceExpression: Equatable {
    public var jawOpen: Double
    public var blinkLeft: Double
    public var blinkRight: Double

    public init(jawOpen: Double = 0, blinkLeft: Double = 0, blinkRight: Double = 0) {
        self.jawOpen = jawOpen
        self.blinkLeft = blinkLeft
        self.blinkRight = blinkRight
    }

    public static let neutral = FaceExpression()
}

public enum ExpressionAdjuster {
    /// Closed eyes fade shadow and liner. An open jaw is handled by the inner-lip cutout, not by the recipe.
    public static func adjusted(_ recipe: MakeupRecipe, expression: FaceExpression) -> MakeupRecipe {
        let blink = min(1, max(expression.blinkLeft, expression.blinkRight))
        let keep = 1 - min(1, max(0, blink))
        var copy = recipe
        copy.eyeshadow.intensity = min(1, max(0, copy.eyeshadow.intensity * keep))
        copy.eyeliner.intensity = min(1, max(0, copy.eyeliner.intensity * keep))
        return copy
    }
}

public struct LookSuggestion: Equatable {
    public var look: Look
    public var faceShape: FaceShape
    public var skinTone: SkinTone
    public var headline: String
    public var notes: [String]

    public init(look: Look, faceShape: FaceShape, skinTone: SkinTone, headline: String, notes: [String]) {
        self.look = look
        self.faceShape = faceShape
        self.skinTone = skinTone
        self.headline = headline
        self.notes = notes
    }
}

public enum SuggestionEngine {
    public static func suggest(shape: FaceShape, tone: SkinTone) -> LookSuggestion {
        let look = CuratedLooks.look(id: lookID(shape: shape, tone: tone)) ?? CuratedLooks.natural
        return LookSuggestion(
            look: look,
            faceShape: shape,
            skinTone: tone,
            headline: "Start with \(look.name).",
            notes: [shapeNote(shape), toneNote(tone)]
        )
    }

    public static func tunedRecipe(shape: FaceShape, tone: SkinTone) -> MakeupRecipe {
        tune(suggest(shape: shape, tone: tone).look.recipe, tone: tone)
    }

    public static func tune(_ recipe: MakeupRecipe, tone: SkinTone) -> MakeupRecipe {
        var copy = recipe
        switch tone {
        case .fair, .light:
            copy.blush.intensity = clamp(copy.blush.intensity * 0.85)
            copy.lipstick.intensity = clamp(copy.lipstick.intensity * 0.92)
        case .medium:
            break
        case .tan:
            copy.blush.intensity = clamp(copy.blush.intensity * 1.05)
        case .deep, .rich:
            copy.blush.intensity = clamp(copy.blush.intensity * 1.12)
            copy.lipstick.intensity = clamp(copy.lipstick.intensity * 1.06)
            copy.eyeshadow.intensity = clamp(copy.eyeshadow.intensity * 1.05)
        }
        return copy
    }

    public static func lookID(shape: FaceShape, tone: SkinTone) -> String {
        switch tone {
        case .fair, .light:
            switch shape {
            case .oval, .heart, .oblong: return CuratedLooks.natural.id
            case .round, .square: return CuratedLooks.fresh.id
            }
        case .medium:
            switch shape {
            case .oval, .heart: return CuratedLooks.fresh.id
            case .round, .square: return CuratedLooks.vibrant.id
            case .oblong: return CuratedLooks.natural.id
            }
        case .tan:
            switch shape {
            case .round, .square: return CuratedLooks.vibrant.id
            case .oval, .heart, .oblong: return CuratedLooks.evening.id
            }
        case .deep, .rich:
            switch shape {
            case .heart, .oval: return CuratedLooks.evening.id
            case .round, .square, .oblong: return CuratedLooks.vibrant.id
            }
        }
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    private static func shapeNote(_ shape: FaceShape) -> String {
        switch shape {
        case .oval:
            return "An oval face can carry color evenly. Keep the blush soft and the lip the focus."
        case .round:
            return "A slightly higher blush and a cleaner liner lift a round face."
        case .square:
            return "A softer shadow and a rounded lip balance a stronger jaw."
        case .heart:
            return "Keep the lip gentle and the blush low so a heart-shaped face stays calm."
        case .oblong:
            return "A little more blush width keeps a longer face from looking narrow."
        }
    }

    private static func toneNote(_ tone: SkinTone) -> String {
        switch tone {
        case .fair:
            return "Fair skin reads sheer color well. A light hand keeps it from looking chalky."
        case .light:
            return "Light skin takes soft pinks and mauves without needing heavy coverage."
        case .medium:
            return "Medium skin has room for both a fresh lip and a brighter cheek."
        case .tan:
            return "Warm skin holds coral, bronze, and a deeper lip clearly."
        case .deep:
            return "Deep skin shows a saturated lip and shadow best when the color is rich, not gray."
        case .rich:
            return "Rich skin can take a full lip and a jewel-toned shadow without losing detail."
        }
    }
}
