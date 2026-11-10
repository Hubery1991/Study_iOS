import SwiftUI

struct MoteView: View {
    var hue: Hue
    var showPattern: Bool

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let colors = Theme.colors(for: hue)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [colors.light, colors.deep],
                            center: UnitPoint(x: 0.38, y: 0.32),
                            startRadius: side * 0.02,
                            endRadius: side * 0.62
                        )
                    )
                Circle()
                    .strokeBorder(Color.white.opacity(0.38), lineWidth: max(1, side * 0.045))
                Circle()
                    .fill(Color.white.opacity(hue == .spark ? 0.7 : 0.48))
                    .frame(width: side * 0.28, height: side * 0.16)
                    .offset(x: -side * 0.12, y: -side * 0.16)
                if hue == .spark {
                    SparkMark()
                        .stroke(Theme.ink.opacity(0.75), style: StrokeStyle(lineWidth: max(1.5, side * 0.055), lineCap: .round))
                        .frame(width: side * 0.42, height: side * 0.42)
                } else if showPattern {
                    HuePattern(hue: hue)
                        .frame(width: side * 0.34, height: side * 0.34)
                }
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A simple mark so each color is recognizable without relying on hue alone.
struct HuePattern: View {
    var hue: Hue

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let mark = Theme.ink.opacity(0.72)
            ZStack {
                switch hue {
                case .amber:
                    Circle().fill(mark).frame(width: side * 0.38, height: side * 0.38)
                case .tide:
                    Capsule().fill(mark).frame(width: side * 0.72, height: side * 0.18)
                case .moss:
                    Triangle().fill(mark)
                case .violet:
                    Rectangle()
                        .fill(mark)
                        .frame(width: side * 0.46, height: side * 0.46)
                        .rotationEffect(.degrees(45))
                case .rose:
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(mark, lineWidth: max(2, side * 0.14))
                case .spark:
                    EmptyView()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SparkMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        let inset = rect.width * 0.18
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        path.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        return path
    }
}
