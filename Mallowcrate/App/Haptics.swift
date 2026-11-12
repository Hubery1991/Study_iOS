import UIKit

enum Haptics {
    static func soft() { fire(UIImpactFeedbackGenerator(style: .soft)) }
    static func push() { fire(UIImpactFeedbackGenerator(style: .medium)) }
    static func goal() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func blocked() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func win() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

    private static func fire(_ generator: UIImpactFeedbackGenerator) {
        generator.prepare()
        generator.impactOccurred()
    }
}

enum Feelings {
    static func walked(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.step() }
        if store.save.hapticsOn { Haptics.soft() }
    }

    static func pushed(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.push() }
        if store.save.hapticsOn { Haptics.push() }
    }

    static func goal(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.goal() }
        if store.save.hapticsOn { Haptics.goal() }
    }

    static func blocked(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.blocked() }
        if store.save.hapticsOn { Haptics.blocked() }
    }

    static func undo(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.undo() }
        if store.save.hapticsOn { Haptics.soft() }
    }

    static func win(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.win() }
        if store.save.hapticsOn { Haptics.win() }
    }

    static func tap(_ store: ProgressStore) {
        if store.save.soundOn { ToneBed.shared.tap() }
    }
}
