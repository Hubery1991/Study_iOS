import SwiftUI

struct MeadowBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
        ZStack {
                LinearGradient(
                    colors: [Theme.skyTop, Theme.skyMid, Theme.skyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle()
                    .fill(Color(hex: 0xFFE38A))
                    .frame(width: geo.size.width * 0.3, height: geo.size.width * 0.3)
                    .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 6))
                    .shadow(color: Color(hex: 0xFFE38A).opacity(0.45), radius: 12)
                    .position(x: geo.size.width * 0.96, y: 8)
                TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        Cloud(x: loop(time, speed: 12, span: geo.size.width), y: geo.size.height * 0.16, scale: 1)
                        Cloud(x: loop(time + 40, speed: 18, span: geo.size.width), y: geo.size.height * 0.24, scale: 0.72)
                        Cloud(x: loop(time + 18, speed: 15, span: geo.size.width), y: geo.size.height * 0.08, scale: 0.55)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                Ellipse()
                    .fill(Theme.hillDeep)
                    .frame(width: geo.size.width * 1.3, height: geo.size.height * 0.28)
                    .position(x: geo.size.width * 0.3, y: geo.size.height * 0.96)
                Ellipse()
                    .fill(Theme.hill)
                    .frame(width: geo.size.width * 1.15, height: geo.size.height * 0.22)
                    .position(x: geo.size.width * 0.75, y: geo.size.height * 0.98)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private func loop(_ time: TimeInterval, speed: CGFloat, span: CGFloat) -> CGFloat {
        let width = span + 180
        let raw = CGFloat(time) * speed
        return width - raw.truncatingRemainder(dividingBy: width) - 80
    }
}

private struct Cloud: View {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat

    var body: some View {
        ZStack {
            Ellipse().frame(width: 90 * scale, height: 36 * scale).offset(y: 6 * scale)
            Ellipse().frame(width: 48 * scale, height: 40 * scale).offset(x: -22 * scale, y: -4 * scale)
            Ellipse().frame(width: 58 * scale, height: 46 * scale).offset(x: 16 * scale, y: -8 * scale)
        }
        .foregroundStyle(Color.white.opacity(0.92))
        .shadow(color: Color(hex: 0x7EB6E8).opacity(0.25), radius: 4, y: 3)
        .position(x: x, y: y)
    }
}

struct MallowCharacter: View {
    var facing: Direction = .down
    var squash: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Ellipse()
                    .fill(Theme.shadow)
                    .frame(width: side * 0.48, height: side * 0.13)
                    .offset(y: side * 0.36)
                HStack(spacing: side * 0.18) {
                    Capsule().fill(Color(hex: 0xF2B89A)).frame(width: side * 0.14, height: side * 0.1)
                    Capsule().fill(Color(hex: 0xF2B89A)).frame(width: side * 0.14, height: side * 0.1)
                }
                .offset(y: side * 0.30)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: 0xFFD8C6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(Ellipse().stroke(Color(hex: 0xE7B39A), lineWidth: max(1.5, side * 0.028)))
                    .frame(width: side * 0.72, height: side * 0.62)
                Ellipse()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: side * 0.32, height: side * 0.2)
                    .offset(y: side * 0.1)
                HStack(spacing: side * 0.22) {
                    Circle().fill(Theme.blush).frame(width: side * 0.11, height: side * 0.08)
                    Circle().fill(Theme.blush).frame(width: side * 0.11, height: side * 0.08)
                }
                .offset(y: side * 0.08)
                HStack(spacing: side * 0.12) {
                    eye(side)
                    eye(side)
                }
                .offset(x: eyeNudge(side).width, y: side * -0.04 + eyeNudge(side).height)
                Smile()
                    .stroke(Color(hex: 0x6B4636), style: StrokeStyle(lineWidth: max(1.6, side * 0.025), lineCap: .round))
                    .frame(width: side * 0.18, height: side * 0.1)
                    .offset(y: side * 0.08)
                sprout(side)
                    .offset(y: -side * 0.38)
            }
            .scaleEffect(x: squash, y: max(0.82, 1 - (squash - 1) * 0.85), anchor: .bottom)
            .frame(width: geo.size.width, height: geo.size.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func eyeNudge(_ side: CGFloat) -> CGSize {
        switch facing {
        case .left: return CGSize(width: -side * 0.03, height: 0)
        case .right: return CGSize(width: side * 0.03, height: 0)
        case .up: return CGSize(width: 0, height: -side * 0.02)
        case .down: return CGSize(width: 0, height: side * 0.012)
        }
    }

    private func eye(_ side: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0x3A2A24))
                .frame(width: side * 0.1, height: side * 0.12)
            Circle()
                .fill(Color.white)
                .frame(width: side * 0.034)
                .offset(x: -side * 0.016, y: -side * 0.02)
        }
    }

    private func sprout(_ side: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x2F8A45))
                .frame(width: side * 0.045, height: side * 0.12)
                .offset(y: side * 0.02)
            Ellipse()
                .fill(Color(hex: 0x5CBF6A))
                .frame(width: side * 0.18, height: side * 0.1)
                .rotationEffect(.degrees(-38))
                .offset(x: -side * 0.07, y: -side * 0.02)
            Ellipse()
                .fill(Color(hex: 0x8BE08A))
                .frame(width: side * 0.17, height: side * 0.09)
                .rotationEffect(.degrees(32))
                .offset(x: side * 0.07, y: -side * 0.015)
        }
        .frame(width: side * 0.4, height: side * 0.24)
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(20),
            endAngle: .degrees(160),
            clockwise: false
        )
        return path
    }
}

struct CrateView: View {
    var onGoal: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Ellipse()
                    .fill(Theme.shadow)
                    .frame(width: side * 0.72, height: side * 0.16)
                    .offset(y: side * 0.36)
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFD56A), Theme.goldDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                            .stroke(Theme.crateEdge, lineWidth: max(2, side * 0.045))
                    )
                    .frame(width: side * 0.78, height: side * 0.78)
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(Theme.crateBand)
                    .frame(width: side * 0.78, height: side * 0.11)
                    .offset(y: -side * 0.16)
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(Theme.crateBand)
                    .frame(width: side * 0.78, height: side * 0.11)
                    .offset(y: side * 0.16)
                RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                    .fill(Color.white.opacity(0.45))
                    .frame(width: side * 0.22, height: side * 0.1)
                    .offset(x: -side * 0.16, y: -side * 0.24)
                CloverStamp()
                    .frame(width: side * 0.24, height: side * 0.24)
                if onGoal {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: max(2, side * 0.04))
                        .frame(width: side * 0.9, height: side * 0.9)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

private struct CloverStamp: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().frame(width: side * 0.46).offset(y: -side * 0.16)
                Circle().frame(width: side * 0.46).offset(x: -side * 0.16, y: side * 0.08)
                Circle().frame(width: side * 0.46).offset(x: side * 0.16, y: side * 0.08)
                Capsule().frame(width: side * 0.12, height: side * 0.28).offset(y: side * 0.34)
            }
            .foregroundStyle(Color(hex: 0xC45C2A))
        }
    }
}

struct DaisyPad: View {
    var filled: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(Color(hex: 0x7ED07A).opacity(0.35))
                    .frame(width: side * 0.78, height: side * 0.78)
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(Color.white)
                        .frame(width: side * 0.16, height: side * 0.28)
                        .offset(y: -side * 0.16)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                Circle()
                    .fill(Theme.gold)
                    .frame(width: side * 0.24, height: side * 0.24)
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: side * 0.07, height: side * 0.07)
                    .offset(x: -side * 0.04, y: -side * 0.04)
            }
            .scaleEffect(filled ? 1.05 : 1)
            .frame(width: geo.size.width, height: geo.size.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

struct FloorTile: View {
    var alt: Bool

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: geo.size.width * 0.18, style: .continuous)
                .fill(alt ? Theme.floorAlt : Theme.floor)
                .padding(geo.size.width * 0.06)
                .overlay(
                    RoundedRectangle(cornerRadius: geo.size.width * 0.14, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 2)
                        .padding(geo.size.width * 0.1)
                )
        }
    }
}

struct WallBlock: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFF8FB0), Theme.raspberry, Theme.raspberryDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                            .stroke(Color(hex: 0xA33A5C), lineWidth: max(2, side * 0.04))
                    )
                    .padding(side * 0.06)
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: side * 0.36, height: side * 0.16)
                    .offset(y: -side * 0.18)
                HStack(spacing: side * 0.08) {
                    Capsule().fill(Theme.gold).frame(width: side * 0.08, height: side * 0.05)
                    Capsule().fill(Color.white).frame(width: side * 0.08, height: side * 0.05)
                    Capsule().fill(Color(hex: 0x7ED0FF)).frame(width: side * 0.08, height: side * 0.05)
                }
                .offset(y: side * 0.08)
            }
        }
    }
}

struct SparkleBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                StarShape()
                    .fill(index.isMultiple(of: 2) ? Theme.gold : Color.white)
                    .frame(width: 12, height: 12)
                    .offset(y: pop ? -28 : -6)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .opacity(pop ? 0 : 1)
                    .scaleEffect(pop ? 1.2 : 0.3)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.01) : .easeOut(duration: 0.55)) {
                pop = true
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
