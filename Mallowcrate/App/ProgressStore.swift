import SwiftUI

final class ProgressStore: ObservableObject {
    @Published private(set) var save: SaveGame

    private let key = "mallowcrate.save.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? SaveGame.decoded(data) {
            save = decoded
        } else {
            save = SaveGame()
        }
    }

    func setSound(_ on: Bool) {
        update { $0.soundOn = on }
    }

    func setHaptics(_ on: Bool) {
        update { $0.hapticsOn = on }
    }

    func markHintSeen() {
        guard !save.sawHint else { return }
        update { $0.sawHint = true }
    }

    @discardableResult
    func recordClear(level: Int, moves: Int, par: Int) -> Bool {
        var improved = false
        update { improved = $0.recordClear(level: level, moves: moves, par: par) }
        return improved
    }

    func resetProgress() {
        let sound = save.soundOn
        let haptics = save.hapticsOn
        save = SaveGame(soundOn: sound, hapticsOn: haptics, sawHint: true)
        persist()
    }

    private func update(_ change: (inout SaveGame) -> Void) {
        var copy = save
        change(&copy)
        save = copy
        persist()
    }

    private func persist() {
        if let data = try? save.encoded() {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
