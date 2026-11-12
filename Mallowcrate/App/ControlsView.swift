import SwiftUI

struct ControlsView: View {
    var enabled: Bool
    var canUndo: Bool
    var pad: CGFloat = 64
    var onMove: (Direction) -> Void
    var onUndo: () -> Void
    var onRestart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                pill("Undo", system: "arrow.uturn.backward", enabled: canUndo, action: onUndo)
                pill("Restart", system: "arrow.counterclockwise", enabled: true, action: onRestart)
            }
            dpad
        }
    }

    private var dpad: some View {
        VStack(spacing: 8) {
            padButton(.up, system: "chevron.up")
            HStack(spacing: 8) {
                padButton(.left, system: "chevron.left")
                ZStack {
                    Circle().fill(Theme.creamDeep)
                    DaisyPad().padding(10)
                }
                .frame(width: pad, height: pad)
                .accessibilityHidden(true)
                padButton(.right, system: "chevron.right")
            }
            padButton(.down, system: "chevron.down")
        }
        .opacity(enabled ? 1 : 0.45)
    }

    private func padButton(_ direction: Direction, system: String) -> some View {
        HoldButton(enabled: enabled) {
            onMove(direction)
        } label: {
            Image(systemName: system)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .frame(width: pad, height: pad)
                .background(
                    Circle()
                        .fill(Theme.cream)
                        .shadow(color: Theme.ink.opacity(0.14), radius: 0, y: 4)
                )
        }
        .accessibilityLabel(direction.spoken)
    }

    private func pill(_ title: String, system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(Theme.cream)
                        .shadow(color: Theme.ink.opacity(0.12), radius: 0, y: 3)
                )
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

private extension Direction {
    var spoken: String {
        switch self {
        case .up: return "Move up"
        case .down: return "Move down"
        case .left: return "Move left"
        case .right: return "Move right"
        }
    }
}

private struct HoldButton<Label: View>: View {
    var enabled: Bool
    var action: () -> Void
    var label: () -> Label
    @StateObject private var repeater = Repeater()

    var body: some View {
        label()
            .contentShape(Circle())
            .opacity(enabled ? 1 : 0.45)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard enabled else { return }
                        repeater.start(action)
                    }
                    .onEnded { _ in repeater.stop() }
            )
            .onDisappear { repeater.stop() }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if enabled { action() } }
    }
}

private final class Repeater: ObservableObject {
    private var timer: Timer?
    private var ticks = 0

    func start(_ action: @escaping () -> Void) {
        guard timer == nil else { return }
        ticks = 0
        action()
        let held = Timer(timeInterval: 0.16, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.ticks += 1
            if self.ticks >= 2 {
                action()
            }
        }
        timer = held
        RunLoop.main.add(held, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
