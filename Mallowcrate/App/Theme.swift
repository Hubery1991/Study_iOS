import SwiftUI

enum Theme {
    static let skyTop = Color(hex: 0x7EC8FF)
    static let skyMid = Color(hex: 0xB7E4FF)
    static let skyBottom = Color(hex: 0xFFF3C4)
    static let hill = Color(hex: 0x7ED07A)
    static let hillDeep = Color(hex: 0x4EAE68)
    static let ink = Color(hex: 0x4A3428)
    static let inkSoft = Color(hex: 0x7A5B48)
    static let cream = Color(hex: 0xFFF8EE)
    static let creamDeep = Color(hex: 0xFFE7C4)
    static let coral = Color(hex: 0xFF7A59)
    static let coralDeep = Color(hex: 0xE85D3A)
    static let leaf = Color(hex: 0x3CB371)
    static let gold = Color(hex: 0xFFC857)
    static let goldDeep = Color(hex: 0xF0A202)
    static let crateBand = Color(hex: 0xE08A1E)
    static let crateEdge = Color(hex: 0xC46A12)
    static let blush = Color(hex: 0xFF9BB3)
    static let raspberry = Color(hex: 0xE36A8A)
    static let raspberryDeep = Color(hex: 0xC44B70)
    static let floor = Color(hex: 0xFFE6B8)
    static let floorAlt = Color(hex: 0xFFD9A0)
    static let board = Color(hex: 0xFFF1D4)
    static let boardRim = Color(hex: 0xE2B56A)
    static let shadow = Color(hex: 0x4A3428).opacity(0.16)

    static func rounded(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.46
        var path = Path()
        for index in 0..<10 {
            let angle = (Double(index) * .pi / 5) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct StarRow: View {
    var filled: Int
    var total: Int = 3
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<total, id: \.self) { index in
                StarShape()
                    .fill(index < filled ? Theme.gold : Theme.creamDeep)
                    .overlay(
                        StarShape().stroke(Theme.crateEdge.opacity(index < filled ? 0.9 : 0.35), lineWidth: max(1, size * 0.08))
                    )
                    .frame(width: size, height: size)
                    .shadow(color: index < filled ? Theme.gold.opacity(0.35) : .clear, radius: 2, y: 1)
            }
        }
        .accessibilityLabel("\(filled) of \(total) stars")
    }
}
