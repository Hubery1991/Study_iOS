import UIKit

enum Haptics {
    static func tap() {
        guard Scorebook.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func clear(chain: Int) {
        guard Scorebook.shared.hapticsEnabled else { return }
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch chain {
        case ...1: style = .soft
        case 2: style = .medium
        default: style = .heavy
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func warning() {
        guard Scorebook.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func success() {
        guard Scorebook.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
