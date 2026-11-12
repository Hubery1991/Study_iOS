import SwiftUI

struct CelebrationView: View {
    var moves: Int
    var par: Int
    var stars: Int
    var kind: ClearKind
    var hasNext: Bool
    var onNext: () -> Void
    var onReplay: () -> Void
    var onLevels: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var show = false
    @State private var fall = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            confetti
            VStack(spacing: 14) {
                MallowCharacter()
                    .frame(width: 120, height: 120)
                    .offset(y: show ? 0 : 30)
                Text(headline)
                    .font(Theme.rounded(32))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                StarRow(filled: stars, size: 36)
                    .scaleEffect(show ? 1 : 0.4)
                Text("\(moves) moves  ·  par \(par)")
                    .font(Theme.rounded(16, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(detail)
                    .font(Theme.rounded(15, weight: .semibold))
                    .foregroundStyle(Theme.coralDeep)
                JellyButton(title: hasNext ? "Next level" : "Back to levels", fill: Theme.coral, action: hasNext ? onNext : onLevels)
                Button(action: onReplay) {
                    Text("Play again")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 2)
            }
            .padding(22)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.cream)
                    .shadow(color: Theme.shadow, radius: 16, y: 8)
            )
            .padding(.horizontal, 24)
            .scaleEffect(show ? 1 : 0.86)
        }
        .onAppear {
            withAnimation(reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.45, dampingFraction: 0.72)) {
                show = true
                fall = true
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private var headline: String {
        switch kind {
        case .again: return "Tucked in again"
        default: return "All tucked in!"
        }
    }

    private var detail: String {
        switch kind {
        case .better: return "New best!"
        case .first where stars == 3: return "A perfect little nudge."
        case .first: return "The daisies are happy."
        case .again: return "Your best is still saved."
        }
    }

    private var confetti: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(piece.color)
                        .frame(width: piece.wide ? 14 : 8, height: piece.wide ? 8 : 14)
                        .rotationEffect(.degrees(fall ? piece.spin : 0))
                        .position(
                            x: piece.x * geo.size.width,
                            y: fall && !reduceMotion ? geo.size.height + 30 : piece.y * geo.size.height * 0.35
                        )
                        .opacity(reduceMotion ? 0.9 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var pieces: [ConfettiBit] {
        let colors = [Theme.gold, Theme.coral, Theme.leaf, Theme.blush, Color.white, Theme.skyTop]
        return (0..<28).map { index in
            ConfettiBit(
                id: index,
                x: CGFloat((index * 37) % 100) / 100,
                y: CGFloat((index * 17) % 80) / 100,
                spin: Double((index * 48) % 360),
                wide: index.isMultiple(of: 2),
                color: colors[index % colors.count]
            )
        }
    }
}

private struct ConfettiBit: Identifiable {
    var id: Int
    var x: CGFloat
    var y: CGFloat
    var spin: Double
    var wide: Bool
    var color: Color
}
