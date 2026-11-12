import UIKit

enum MakeupDrawing {
    static func draw(
        in context: CGContext,
        canvas: CGSize,
        landmarks: FaceLandmarks,
        recipe: MakeupRecipe,
        expression: FaceExpression,
        compare: CompareSplit?,
        map: (Point2D) -> CGPoint
    ) {
        guard canvas.width > 1, canvas.height > 1 else { return }
        guard let geometry = RegionBuilder.geometry(from: landmarks) else { return }
        let drawn = ExpressionAdjuster.adjusted(recipe, expression: expression)
        let left = map(Point2D(x: landmarks.bounds.minX, y: landmarks.bounds.midY))
        let right = map(Point2D(x: landmarks.bounds.maxX, y: landmarks.bounds.midY))
        let facePx = hypot(right.x - left.x, right.y - left.y)
        guard facePx > 8 else { return }

        context.saveGState()
        if let compare {
            let cut = CGFloat(compare.position) * canvas.width
            context.clip(to: CGRect(x: cut, y: 0, width: max(0, canvas.width - cut), height: canvas.height))
        }

        stroke(
            geometry.leftBrow,
            region: .brows,
            setting: drawn.brows,
            context: context,
            width: max(2, facePx * 0.045),
            close: false,
            map: map
        )
        stroke(
            geometry.rightBrow,
            region: .brows,
            setting: drawn.brows,
            context: context,
            width: max(2, facePx * 0.045),
            close: false,
            map: map
        )
        fill(geometry.leftLid, region: .eyeshadow, setting: drawn.eyeshadow, context: context, map: map)
        fill(geometry.rightLid, region: .eyeshadow, setting: drawn.eyeshadow, context: context, map: map)
        blush(geometry.leftCheek, setting: drawn.blush, context: context, map: map)
        blush(geometry.rightCheek, setting: drawn.blush, context: context, map: map)
        stroke(
            geometry.leftLiner,
            region: .eyeliner,
            setting: drawn.eyeliner,
            context: context,
            width: max(1.6, facePx * 0.016),
            close: false,
            map: map
        )
        stroke(
            geometry.rightLiner,
            region: .eyeliner,
            setting: drawn.eyeliner,
            context: context,
            width: max(1.6, facePx * 0.016),
            close: false,
            map: map
        )
        lips(outer: geometry.lipsOuter, inner: geometry.lipsInner, setting: drawn.lipstick, context: context, map: map)
        context.restoreGState()
    }

    private static func lips(
        outer: [Point2D],
        inner: [Point2D],
        setting: RegionSetting,
        context: CGContext,
        map: (Point2D) -> CGPoint
    ) {
        guard let shade = ShadeCatalog.shade(id: setting.shadeID) else { return }
        let style = MakeupPainter.style(
            region: .lipstick,
            finish: shade.finish,
            intensity: setting.intensity,
            enabled: setting.enabled
        )
        guard style.opacity > 0.01, let outerPath = path(outer, close: true, map: map) else { return }
        let combined = CGMutablePath()
        combined.addPath(outerPath)
        if inner.count >= 3, let innerPath = path(inner, close: true, map: map) {
            combined.addPath(innerPath)
        }
        context.saveGState()
        context.setBlendMode(cgBlend(style.mode))
        context.setFillColor(Theme.uiColor(shade.color, alpha: CGFloat(style.opacity)).cgColor)
        context.addPath(combined)
        context.fillPath(using: .evenOdd)
        context.restoreGState()
    }

    private static func fill(
        _ points: [Point2D],
        region: MakeupRegion,
        setting: RegionSetting,
        context: CGContext,
        map: (Point2D) -> CGPoint
    ) {
        guard let shade = ShadeCatalog.shade(id: setting.shadeID) else { return }
        let style = MakeupPainter.style(
            region: region,
            finish: shade.finish,
            intensity: setting.intensity,
            enabled: setting.enabled
        )
        guard style.opacity > 0.01, let shape = path(points, close: true, map: map) else { return }
        context.saveGState()
        context.setBlendMode(cgBlend(style.mode))
        context.setFillColor(Theme.uiColor(shade.color, alpha: CGFloat(style.opacity)).cgColor)
        context.addPath(shape)
        context.fillPath()
        context.restoreGState()
    }

    private static func blush(
        _ points: [Point2D],
        setting: RegionSetting,
        context: CGContext,
        map: (Point2D) -> CGPoint
    ) {
        guard let shade = ShadeCatalog.shade(id: setting.shadeID) else { return }
        let style = MakeupPainter.style(
            region: .blush,
            finish: shade.finish,
            intensity: setting.intensity,
            enabled: setting.enabled
        )
        guard style.opacity > 0.01, points.count >= 3, let shape = path(points, close: true, map: map) else { return }
        let mapped = points.map(map)
        let center = mapped.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let count = CGFloat(mapped.count)
        let mid = CGPoint(x: center.x / count, y: center.y / count)
        let radius = mapped.map { hypot($0.x - mid.x, $0.y - mid.y) }.max() ?? 12
        let peak = Theme.uiColor(shade.color, alpha: CGFloat(style.opacity))
        let edge = Theme.uiColor(shade.color, alpha: 0)
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [peak.cgColor, edge.cgColor] as CFArray,
            locations: [0, 1]
        ) else { return }
        context.saveGState()
        context.addPath(shape)
        context.clip()
        context.setBlendMode(cgBlend(style.mode))
        context.drawRadialGradient(
            gradient,
            startCenter: mid,
            startRadius: 0,
            endCenter: mid,
            endRadius: radius,
            options: []
        )
        context.restoreGState()
    }

    private static func stroke(
        _ points: [Point2D],
        region: MakeupRegion,
        setting: RegionSetting,
        context: CGContext,
        width: CGFloat,
        close: Bool,
        map: (Point2D) -> CGPoint
    ) {
        guard let shade = ShadeCatalog.shade(id: setting.shadeID) else { return }
        let style = MakeupPainter.style(
            region: region,
            finish: shade.finish,
            intensity: setting.intensity,
            enabled: setting.enabled
        )
        guard style.opacity > 0.01, let shape = path(points, close: close, map: map) else { return }
        context.saveGState()
        context.setBlendMode(cgBlend(style.mode))
        context.setStrokeColor(Theme.uiColor(shade.color, alpha: CGFloat(style.opacity)).cgColor)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(shape)
        context.strokePath()
        context.restoreGState()
    }

    private static func path(_ points: [Point2D], close: Bool, map: (Point2D) -> CGPoint) -> CGPath? {
        guard points.count >= 2 else { return nil }
        let path = CGMutablePath()
        path.move(to: map(points[0]))
        for point in points.dropFirst() {
            path.addLine(to: map(point))
        }
        if close { path.closeSubpath() }
        return path
    }

    private static func cgBlend(_ mode: BlendMode) -> CGBlendMode {
        switch mode {
        case .sourceOver: return .normal
        case .multiply: return .multiply
        case .softLight: return .softLight
        case .overlay: return .overlay
        }
    }
}

final class MakeupCanvas: UIView {
    var landmarks: FaceLandmarks?
    var imageSize: CGSize = .zero
    var recipe: MakeupRecipe = CuratedLooks.bare
    var expression: FaceExpression = .neutral
    var compare: CompareSplit?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let landmarks,
              imageSize.width > 1,
              imageSize.height > 1 else { return }
        let mapper = PreviewMapper(
            imageWidth: imageSize.width,
            imageHeight: imageSize.height,
            viewWidth: bounds.width,
            viewHeight: bounds.height,
            mirrorX: false
        )
        MakeupDrawing.draw(
            in: context,
            canvas: bounds.size,
            landmarks: landmarks,
            recipe: recipe,
            expression: expression,
            compare: compare,
            map: { point in
                let mapped = mapper.viewPoint(point)
                return CGPoint(x: mapped.x, y: mapped.y)
            }
        )
    }
}

struct MakeupCanvasView: UIViewRepresentable {
    var landmarks: FaceLandmarks?
    var imageSize: CGSize
    var recipe: MakeupRecipe
    var expression: FaceExpression
    var compare: CompareSplit?

    func makeUIView(context: Context) -> MakeupCanvas {
        MakeupCanvas()
    }

    func updateUIView(_ uiView: MakeupCanvas, context: Context) {
        uiView.landmarks = landmarks
        uiView.imageSize = imageSize
        uiView.recipe = recipe
        uiView.expression = expression
        uiView.compare = compare
        uiView.setNeedsDisplay()
    }
}
