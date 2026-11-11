import SwiftUI
import PolquetteCore

struct HandCanvas: View {
    var manicure: Manicure
    var scope: PaintScope
    var showsSelection: Bool = true

    var body: some View {
        Canvas { context, size in
            drawSalon(context: &context, size: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let names = Finger.allCases.map { finger in
            let nail = manicure.nail(finger)
            let color = Palette.color(id: nail.colorID)?.name ?? "color"
            return "\(finger.title), \(nail.shape.title), \(color), \(nail.finish.title)"
        }
        return "Illustrated hand. " + names.joined(separator: ". ")
    }

    private func drawSalon(context: inout GraphicsContext, size: CGSize) {
        let backdrop = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 28)
        context.fill(
            backdrop,
            with: .linearGradient(
                Gradient(colors: [SalonTheme.blush.opacity(0.9), SalonTheme.paper]),
                startPoint: CGPoint(x: size.width * 0.2, y: 0),
                endPoint: CGPoint(x: size.width * 0.8, y: size.height)
            )
        )

        let palmRect = CGRect(
            x: size.width * 0.16,
            y: size.height * 0.56,
            width: size.width * 0.66,
            height: size.height * 0.40
        )
        context.fill(
            Path(ellipseIn: palmRect),
            with: .linearGradient(
                Gradient(colors: [SalonTheme.skinLight, SalonTheme.skinMid, SalonTheme.skinShadow]),
                startPoint: CGPoint(x: palmRect.midX, y: palmRect.minY),
                endPoint: CGPoint(x: palmRect.midX, y: palmRect.maxY)
            )
        )

        let digits = DigitLayout.specs
        for spec in digits {
            drawFinger(spec, context: &context, size: size)
        }
        for spec in digits {
            drawNail(spec, context: &context, size: size)
        }
    }

    private func drawFinger(_ spec: DigitLayout, context: inout GraphicsContext, size: CGSize) {
        let base = spec.base(in: size)
        let tip = spec.tip(in: size)
        var line = Path()
        line.move(to: base)
        line.addLine(to: tip)
        context.stroke(
            line,
            with: .linearGradient(
                Gradient(colors: [SalonTheme.skinShadow, SalonTheme.skinMid, SalonTheme.skinLight]),
                startPoint: base,
                endPoint: tip
            ),
            style: StrokeStyle(lineWidth: spec.width * size.width, lineCap: .round)
        )
    }

    private func drawNail(_ spec: DigitLayout, context: inout GraphicsContext, size: CGSize) {
        let nail = manicure.nail(spec.finger)
        let frame = spec.nailFrame(in: size)
        let local = NailOutline.path(shape: nail.shape, in: frame.localRect)
        let selected = showsSelection && scope.fingers.contains(spec.finger) && scope != .all
        let allSelected = showsSelection && scope == .all

        context.drawLayer { layer in
            layer.translateBy(x: frame.center.x, y: frame.center.y)
            layer.rotate(by: .radians(frame.angle))
            layer.drawLayer { clipped in
                clipped.clip(to: local, style: FillStyle(eoFill: false))
                paintBed(nail, in: frame.localRect, context: &clipped)
                paintFinish(nail.finish, in: frame.localRect, context: &clipped, seed: spec.finger.rawValue)
            }
            paintDecorations(nail, in: frame.localRect, context: &layer)
            if selected {
                layer.stroke(local, with: .color(SalonTheme.gold), style: StrokeStyle(lineWidth: 3.5))
            } else if allSelected {
                layer.stroke(local, with: .color(SalonTheme.rose.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6))
            } else {
                layer.stroke(local, with: .color(Color.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1))
            }
        }
    }

    private func paintBed(_ nail: NailDesign, in rect: CGRect, context: inout GraphicsContext) {
        let base = SalonTheme.polish(nail.colorID)
        if nail.gradient.enabled {
            let end = SalonTheme.polish(nail.gradient.endColorID)
            context.fill(
                Path(rect.insetBy(dx: -4, dy: -4)),
                with: .linearGradient(
                    Gradient(colors: [end, base]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY),
                    endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                )
            )
        } else if nail.finish == .chrome {
            let deep = SalonTheme.polish(nail.colorID).opacity(0.55)
            context.fill(
                Path(rect.insetBy(dx: -4, dy: -4)),
                with: .linearGradient(
                    Gradient(colors: [Color.white, base, deep, Color.white.opacity(0.85)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
        } else {
            context.fill(Path(rect.insetBy(dx: -4, dy: -4)), with: .color(base))
        }

        if nail.french.enabled {
            let tipHeight = rect.height * CGFloat(nail.french.coverage)
            let tip = CGRect(x: rect.minX - 4, y: rect.minY, width: rect.width + 8, height: tipHeight)
            context.fill(Path(tip), with: .color(SalonTheme.polish(nail.french.colorID)))
        }

        let cuticle = CGRect(x: rect.minX, y: rect.maxY - rect.height * 0.08, width: rect.width, height: rect.height * 0.08)
        context.fill(Path(cuticle), with: .color(Color.black.opacity(0.10)))
    }

    private func paintFinish(_ finish: Finish, in rect: CGRect, context: inout GraphicsContext, seed: Int) {
        switch finish {
        case .gloss:
            let shine = CGRect(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.22, width: rect.width * 0.28, height: rect.height * 0.16)
            context.fill(Path(ellipseIn: shine), with: .color(Color.white.opacity(0.5)))
        case .matte:
            context.fill(Path(rect), with: .color(Color.black.opacity(0.08)))
        case .cream:
            let satin = CGRect(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.32, width: rect.width * 0.44, height: rect.height * 0.28)
            context.fill(Path(ellipseIn: satin), with: .color(Color.white.opacity(0.16)))
        case .chrome:
            let band = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.18, width: rect.width, height: rect.height * 0.12)
            context.fill(Path(band), with: .color(Color.white.opacity(0.55)))
        case .shimmer:
            let shine = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.12, width: rect.width * 0.6, height: rect.height * 0.26)
            context.fill(Path(ellipseIn: shine), with: .color(Color.white.opacity(0.28)))
            for (index, dot) in GlitterField.dots(seed: seed + 9, count: 8).enumerated() {
                let point = CGPoint(x: rect.minX + dot.x * rect.width, y: rect.minY + dot.y * rect.height)
                let spark = Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 1.6, height: 1.6))
                context.fill(spark, with: .color(Color.white.opacity(index.isMultiple(of: 2) ? 0.85 : 0.45)))
            }
        case .glitter:
            for (index, dot) in GlitterField.dots(seed: seed, count: 16).enumerated() {
                let point = CGPoint(x: rect.minX + dot.x * rect.width, y: rect.minY + dot.y * rect.height)
                let radius: CGFloat = index.isMultiple(of: 3) ? 2.2 : 1.3
                let spark = Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius, height: radius))
                context.fill(spark, with: .color(index.isMultiple(of: 2) ? Color.white : SalonTheme.gold.opacity(0.9)))
            }
        }
    }

    private func paintDecorations(_ nail: NailDesign, in rect: CGRect, context: inout GraphicsContext) {
        for decoration in nail.decorations {
            guard let motif = Palette.motif(id: decoration.motifID) else { continue }
            let center = CGPoint(
                x: rect.minX + CGFloat(decoration.x) * rect.width,
                y: rect.minY + CGFloat(decoration.y) * rect.height
            )
            let unit = min(rect.width, rect.height) * 0.22 * CGFloat(decoration.scale)
            let color = SalonTheme.polish(decoration.colorID)
            context.drawLayer { layer in
                layer.translateBy(x: center.x, y: center.y)
                layer.rotate(by: .degrees(decoration.rotation))
                MotifDrawing.draw(motif.kind, motifID: motif.id, color: color, unit: unit, context: &layer)
            }
        }
    }
}

struct HandTapOverlay: View {
    var scope: PaintScope
    var onSelect: (Finger) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(DigitLayout.specs, id: \.finger) { spec in
                    let frame = spec.nailFrame(in: geo.size)
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: max(frame.localRect.width, 44), height: max(frame.localRect.height, 44))
                        .position(frame.center)
                        .onTapGesture { onSelect(spec.finger) }
                        .accessibilityLabel("\(spec.finger.title) nail")
                }
            }
        }
        .allowsHitTesting(true)
    }
}

enum GlitterField {
    static func dots(seed: Int, count: Int) -> [(x: CGFloat, y: CGFloat)] {
        var state = UInt64(seed &* 997 + 17)
        return (0..<count).map { _ in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let x = CGFloat((state >> 33) % 1000) / 1000
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let y = CGFloat((state >> 33) % 1000) / 1000
            return (x: min(0.9, max(0.1, x)), y: min(0.88, max(0.12, y)))
        }
    }
}

enum MotifDrawing {
    static func draw(_ kind: DecorationKind, motifID: String, color: Color, unit: CGFloat, context: inout GraphicsContext) {
        switch kind {
        case .pearl:
            let rect = CGRect(x: -unit * 0.45, y: -unit * 0.45, width: unit * 0.9, height: unit * 0.9)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.95)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: unit * 0.28, dy: unit * 0.32).offsetBy(dx: -unit * 0.08, dy: -unit * 0.1)), with: .color(.white.opacity(0.85)))
        case .gem:
            var gem = Path()
            gem.move(to: CGPoint(x: 0, y: -unit * 0.55))
            gem.addLine(to: CGPoint(x: unit * 0.42, y: 0))
            gem.addLine(to: CGPoint(x: 0, y: unit * 0.55))
            gem.addLine(to: CGPoint(x: -unit * 0.42, y: 0))
            gem.closeSubpath()
            context.fill(gem, with: .linearGradient(Gradient(colors: [.white, color, SalonTheme.ink.opacity(0.35)]), startPoint: CGPoint(x: -unit, y: -unit), endPoint: CGPoint(x: unit, y: unit)))
        case .foil:
            var flake = Path()
            let signs: [CGFloat] = motifID == "leaf" ? [1, 0.2, -0.6, -1, -0.2, 0.7] : [0.9, 0.4, -0.2, -0.95, -0.3, 0.55]
            for index in signs.indices {
                let angle = CGFloat(index) / CGFloat(signs.count) * .pi * 2
                let radius = unit * signs[index].magnitude
                let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius * 0.7)
                if index == 0 { flake.move(to: point) } else { flake.addLine(to: point) }
            }
            flake.closeSubpath()
            context.fill(flake, with: .color(color))
            context.stroke(flake, with: .color(.white.opacity(0.6)), lineWidth: 0.8)
        case .flower:
            for petal in 0..<5 {
                let angle = CGFloat(petal) / 5 * .pi * 2 - .pi / 2
                let center = CGPoint(x: cos(angle) * unit * 0.28, y: sin(angle) * unit * 0.28)
                let petalRect = CGRect(x: center.x - unit * 0.22, y: center.y - unit * 0.16, width: unit * 0.44, height: unit * 0.32)
                context.fill(Path(ellipseIn: petalRect), with: .color(color))
            }
            context.fill(Path(ellipseIn: CGRect(x: -unit * 0.12, y: -unit * 0.12, width: unit * 0.24, height: unit * 0.24)), with: .color(SalonTheme.gold))
        case .line:
            var line = Path()
            if motifID == "slant" {
                line.move(to: CGPoint(x: -unit * 1.3, y: unit * 0.45))
                line.addLine(to: CGPoint(x: unit * 1.3, y: -unit * 0.45))
            } else {
                line.move(to: CGPoint(x: -unit * 1.35, y: 0))
                line.addLine(to: CGPoint(x: unit * 1.35, y: 0))
            }
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: max(1.4, unit * 0.14), lineCap: .round))
        case .sticker:
            if motifID == "star" {
                context.fill(star(unit: unit), with: .color(color))
            } else if motifID == "bow" {
                context.fill(Path(ellipseIn: CGRect(x: -unit * 0.7, y: -unit * 0.28, width: unit * 0.55, height: unit * 0.42)), with: .color(color))
                context.fill(Path(ellipseIn: CGRect(x: unit * 0.15, y: -unit * 0.28, width: unit * 0.55, height: unit * 0.42)), with: .color(color))
                context.fill(Path(ellipseIn: CGRect(x: -unit * 0.12, y: -unit * 0.12, width: unit * 0.24, height: unit * 0.24)), with: .color(SalonTheme.gold))
            } else {
                context.fill(heart(unit: unit), with: .color(color))
            }
        }
    }

    private static func star(unit: CGFloat) -> Path {
        var path = Path()
        for index in 0..<10 {
            let angle = CGFloat(index) / 10 * .pi * 2 - .pi / 2
            let radius = index.isMultiple(of: 2) ? unit * 0.48 : unit * 0.2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func heart(unit: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: unit * 0.42))
        path.addCurve(to: CGPoint(x: 0, y: -unit * 0.05), control1: CGPoint(x: unit * 0.7, y: unit * 0.05), control2: CGPoint(x: unit * 0.45, y: -unit * 0.42))
        path.addCurve(to: CGPoint(x: 0, y: unit * 0.42), control1: CGPoint(x: -unit * 0.45, y: -unit * 0.42), control2: CGPoint(x: -unit * 0.7, y: unit * 0.05))
        return path
    }
}

struct DigitLayout: Identifiable {
    let finger: Finger
    let tipX: CGFloat
    let tipY: CGFloat
    let baseX: CGFloat
    let baseY: CGFloat
    let width: CGFloat

    var id: Int { finger.rawValue }

    static let specs: [DigitLayout] = [
        DigitLayout(finger: .pinky, tipX: 0.16, tipY: 0.27, baseX: 0.24, baseY: 0.60, width: 0.078),
        DigitLayout(finger: .ring, tipX: 0.33, tipY: 0.15, baseX: 0.36, baseY: 0.58, width: 0.086),
        DigitLayout(finger: .middle, tipX: 0.51, tipY: 0.09, baseX: 0.51, baseY: 0.58, width: 0.092),
        DigitLayout(finger: .index, tipX: 0.69, tipY: 0.16, baseX: 0.66, baseY: 0.58, width: 0.084),
        DigitLayout(finger: .thumb, tipX: 0.88, tipY: 0.42, baseX: 0.72, baseY: 0.68, width: 0.108),
    ]

    func tip(in size: CGSize) -> CGPoint {
        CGPoint(x: tipX * size.width, y: tipY * size.height)
    }

    func base(in size: CGSize) -> CGPoint {
        CGPoint(x: baseX * size.width, y: baseY * size.height)
    }

    func nailFrame(in size: CGSize) -> NailFrame {
        let tip = tip(in: size)
        let base = base(in: size)
        let dx = tip.x - base.x
        let dy = tip.y - base.y
        let length = max(hypot(dx, dy), 1)
        let angle = atan2(dx, -dy)
        let nailW = width * size.width * 0.92
        let nailH = min(length * 0.46, nailW * 1.7)
        let along = length - nailH * 0.42
        let center = CGPoint(x: base.x + dx / length * along, y: base.y + dy / length * along)
        return NailFrame(
            center: center,
            angle: angle,
            localRect: CGRect(x: -nailW / 2, y: -nailH / 2, width: nailW, height: nailH)
        )
    }
}

struct NailFrame {
    var center: CGPoint
    var angle: CGFloat
    var localRect: CGRect
}

enum NailOutline {
    static func path(shape: NailShape, in rect: CGRect) -> Path {
        let unit = points(shape)
        func map(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.midX + point.x * rect.width / 2,
                y: rect.midY + point.y * rect.height / 2
            )
        }
        let mapped = unit.map(map)
        var path = Path()
        guard let first = mapped.first else { return path }
        path.move(to: midpoint(mapped[mapped.count - 1], first))
        for index in mapped.indices {
            let current = mapped[index]
            let next = mapped[(index + 1) % mapped.count]
            path.addQuadCurve(to: midpoint(current, next), control: current)
        }
        path.closeSubpath()
        return path
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    static func points(_ shape: NailShape) -> [CGPoint] {
        switch shape {
        case .almond:
            return points([
                (0.00, -1.00), (0.34, -0.62), (0.58, -0.08), (0.52, 0.55), (0.28, 1.00),
                (-0.28, 1.00), (-0.52, 0.55), (-0.58, -0.08), (-0.34, -0.62)
            ])
        case .square:
            return points([
                (-0.58, -0.92), (0.58, -0.92), (0.72, -0.62), (0.72, 0.55), (0.48, 1.00),
                (-0.48, 1.00), (-0.72, 0.55), (-0.72, -0.62)
            ])
        case .coffin:
            return points([
                (-0.30, -1.00), (0.30, -1.00), (0.62, -0.05), (0.46, 1.00),
                (-0.46, 1.00), (-0.62, -0.05)
            ])
        case .oval:
            return (0..<20).map { index in
                let theta = CGFloat(index) / 20 * .pi * 2 - .pi / 2
                return CGPoint(x: cos(theta) * 0.62, y: sin(theta))
            }
        case .stiletto:
            return points([
                (0.00, -1.00), (0.22, -0.42), (0.52, 0.18), (0.40, 1.00),
                (-0.40, 1.00), (-0.52, 0.18), (-0.22, -0.42)
            ])
        case .rounded:
            return points([
                (-0.22, -0.98), (0.22, -0.98), (0.70, -0.62), (0.74, 0.35), (0.50, 1.00),
                (-0.50, 1.00), (-0.74, 0.35), (-0.70, -0.62)
            ])
        }
    }

    private static func points(_ pairs: [(CGFloat, CGFloat)]) -> [CGPoint] {
        pairs.map { CGPoint(x: $0.0, y: $0.1) }
    }
}
