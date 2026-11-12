import SwiftUI
import UIKit

struct ArrowKeyCatcher: UIViewControllerRepresentable {
    var onMove: (Direction) -> Void
    var onUndo: () -> Void
    var onRestart: () -> Void

    func makeUIViewController(context: Context) -> KeyController {
        let controller = KeyController()
        controller.onMove = onMove
        controller.onUndo = onUndo
        controller.onRestart = onRestart
        return controller
    }

    func updateUIViewController(_ controller: KeyController, context: Context) {
        controller.onMove = onMove
        controller.onUndo = onUndo
        controller.onRestart = onRestart
    }
}

final class KeyController: UIViewController {
    var onMove: ((Direction) -> Void)?
    var onUndo: (() -> Void)?
    var onRestart: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        let arrows: [(String, Selector)] = [
            (UIKeyCommand.inputUpArrow, #selector(goUp)),
            (UIKeyCommand.inputDownArrow, #selector(goDown)),
            (UIKeyCommand.inputLeftArrow, #selector(goLeft)),
            (UIKeyCommand.inputRightArrow, #selector(goRight)),
        ]
        var commands: [UIKeyCommand] = arrows.map { input, action in
            let command = UIKeyCommand(input: input, modifierFlags: [], action: action)
            command.wantsPriorityOverSystemBehavior = true
            return command
        }
        let letters: [(String, Selector, String)] = [
            ("w", #selector(goUp), "Walk up"),
            ("s", #selector(goDown), "Walk down"),
            ("a", #selector(goLeft), "Walk left"),
            ("d", #selector(goRight), "Walk right"),
            ("u", #selector(doUndo), "Undo"),
            ("r", #selector(doRestart), "Restart"),
        ]
        for (input, action, title) in letters {
            let command = UIKeyCommand(input: input, modifierFlags: [], action: action)
            command.discoverabilityTitle = title
            commands.append(command)
        }
        let undo = UIKeyCommand(input: "z", modifierFlags: .command, action: #selector(doUndo))
        undo.discoverabilityTitle = "Undo"
        commands.append(undo)
        return commands
    }

    @objc private func goUp() { onMove?(.up) }
    @objc private func goDown() { onMove?(.down) }
    @objc private func goLeft() { onMove?(.left) }
    @objc private func goRight() { onMove?(.right) }
    @objc private func doUndo() { onUndo?() }
    @objc private func doRestart() { onRestart?() }
}
