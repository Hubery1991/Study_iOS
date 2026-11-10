import SwiftUI

struct WellBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.sky, Theme.ink], startPoint: .top, endPoint: .bottom)
            .overlay(
                RadialGradient(
                    colors: [Theme.brass.opacity(0.14), .clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 460
                )
            )
            .ignoresSafeArea()
    }
}

struct BrassLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(Theme.rounded(18, .semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.brass))
    }
}

struct GhostLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(Theme.parchment)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.brass.opacity(0.5), lineWidth: 1.5)
            )
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct WellMark: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x241838), Theme.shaft],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.55
                    )
                )
            Circle()
                .strokeBorder(Theme.brass, lineWidth: max(3, size * 0.045))
            Circle()
                .strokeBorder(Theme.brass.opacity(0.35), lineWidth: 1)
                .padding(size * 0.07)
            MoteView(hue: .violet, showPattern: false)
                .frame(width: size * 0.26, height: size * 0.26)
                .offset(x: 0, y: -size * 0.12)
            MoteView(hue: .amber, showPattern: false)
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: -size * 0.16, y: size * 0.1)
            MoteView(hue: .tide, showPattern: false)
                .frame(width: size * 0.24, height: size * 0.24)
                .offset(x: size * 0.17, y: size * 0.12)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.brass.opacity(0.22), radius: size * 0.08, y: size * 0.02)
        .accessibilityHidden(true)
    }
}

struct ClaveRule: View {
    var body: some View {
        HStack(spacing: 5) {
            rule(10)
            rule(4)
            rule(10)
            Spacer().frame(width: 8)
            rule(10)
            rule(4)
        }
        .accessibilityHidden(true)
    }

    private func rule(_ width: CGFloat) -> some View {
        Capsule()
            .fill(Theme.brass)
            .frame(width: width, height: 3)
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var active: Bool

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard active else { return ProjectionTransform(.identity) }
        let translation = sin(shakes * .pi * 6) * 6
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct InfoCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Theme.line, lineWidth: 1)
                    )
            )
    }
}
