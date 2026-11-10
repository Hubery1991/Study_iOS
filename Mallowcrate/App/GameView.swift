import SwiftUI

struct GameFlow: View {
    @State private var index: Int

    init(index: Int) {
        _index = State(initialValue: index)
    }

    var body: some View {
        GameView(
            level: LevelCatalog.levels[index - 1],
            onNext: index < LevelCatalog.levels.count ? { index += 1 } : nil
        )
        .id(index)
    }
}

struct GameView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: PlayModel
    var onNext: (() -> Void)?

    @State private var confirmLeave = false

    init(level: LevelDefinition, onNext: (() -> Void)?) {
        _model = StateObject(wrappedValue: PlayModel(level: level))
        self.onNext = onNext
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 740
            VStack(spacing: compact ? 6 : 10) {
                topBar
                hud
                if model.level.index == 1 && !store.save.sawHint && !model.won {
                    Text("Swipe the meadow, or tap the pad.")
                        .font(Theme.rounded(14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.cream))
                }
                BoardView(
                    puzzle: model.puzzle,
                    facing: model.facing,
                    spark: model.spark,
                    bumpCrateID: model.bumpCrateID,
                    blockedToken: model.blockedToken,
                    moveToken: model.moveToken
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(swipe)
                ControlsView(
                    enabled: !model.won,
                    canUndo: model.puzzle.canUndo,
                    pad: compact ? 54 : 64,
                    onMove: perform,
                    onUndo: undo,
                    onRestart: restart
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(MeadowBackground())
        .navigationBarHidden(true)
        .overlay {
            if model.won {
                CelebrationView(
                    moves: model.puzzle.moves,
                    par: model.level.par,
                    stars: SaveGame.stars(moves: model.puzzle.moves, par: model.level.par),
                    kind: model.clearKind,
                    hasNext: onNext != nil,
                    onNext: { onNext?() },
                    onReplay: restart,
                    onLevels: { dismiss() }
                )
                .transition(reduceMotion ? .opacity : .scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .background(
            ArrowKeyCatcher(onMove: perform, onUndo: undo, onRestart: restart)
                .allowsHitTesting(false)
        )
        .confirmationDialog("Leave this try?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("This try is not saved. Your best score stays on this device.")
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: leave) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.cream))
            }
            .accessibilityLabel("Back")
            Spacer()
            VStack(spacing: 0) {
                Text("Level \(model.level.index)")
                    .font(Theme.rounded(13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                Text(model.level.title)
                    .font(Theme.rounded(20))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                StarRow(filled: store.save.records[model.level.index]?.stars ?? 0, size: 12)
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var hud: some View {
        HStack(spacing: 8) {
            stat("Moves", value: "\(model.puzzle.moves)")
            stat("Par", value: "\(model.level.par)")
            stat("Best", value: bestText)
        }
    }

    private var bestText: String {
        if let best = store.save.records[model.level.index]?.bestMoves {
            return "\(best)"
        }
        return "—"
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(Theme.rounded(11, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
            Text(value)
                .font(Theme.rounded(20))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.cream.opacity(0.92))
        )
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    perform(dx > 0 ? .right : .left)
                } else {
                    perform(dy > 0 ? .down : .up)
                }
            }
    }

    private func perform(_ direction: Direction) {
        let wasWon = model.won
        let outcome = model.move(direction)
        if !store.save.sawHint {
            store.markHintSeen()
        }
        switch outcome {
        case .blocked:
            Feelings.blocked(store)
        case .walked:
            Feelings.walked(store)
        case .pushed(let ontoGoal, _):
            if ontoGoal {
                Feelings.goal(store)
            } else {
                Feelings.pushed(store)
            }
        }
        if model.won && !wasWon {
            let hadRecord = store.save.records[model.level.index] != nil
            let improved = store.recordClear(level: model.level.index, moves: model.puzzle.moves, par: model.level.par)
            model.clearKind = hadRecord ? (improved ? .better : .again) : .first
            Feelings.win(store)
        }
    }

    private func undo() {
        guard model.puzzle.canUndo else { return }
        model.undo()
        Feelings.undo(store)
    }

    private func restart() {
        model.restart()
        Feelings.tap(store)
    }

    private func leave() {
        if model.puzzle.moves > 0 && !model.won {
            confirmLeave = true
        } else {
            dismiss()
        }
    }
}
