import SwiftUI

struct JellyButton: View {
    var title: String
    var subtitle: String?
    var fill: Color = Theme.coral
    var ink: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(Theme.rounded(22))
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.rounded(13, weight: .semibold))
                        .opacity(0.9)
                }
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, subtitle == nil ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
                    .shadow(color: Theme.ink.opacity(0.14), radius: 0, y: 5)
            )
        }
        .buttonStyle(PressStyle())
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CreamCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.cream)
                    .shadow(color: Theme.shadow, radius: 10, y: 6)
            )
    }
}

struct ScreenColumn<Content: View>: View {
    var maxWidth: CGFloat = 560
    var content: Content

    init(maxWidth: CGFloat = 560, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func meadowNavigation() -> some View {
        self
            .toolbarBackground(Theme.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}

struct WorldBlurb {
    static func line(_ world: Int) -> String {
        switch world {
        case 1: return "First nudges"
        case 2: return "A second crate"
        case 3: return "Walk the long way"
        case 4: return "Mind the order"
        case 5: return "Tighter shelves"
        default: return "The tricky meadow"
        }
    }
}
