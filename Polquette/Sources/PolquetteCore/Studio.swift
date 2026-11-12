import Foundation

public enum PaintScope: Equatable {
    case all
    case finger(Finger)

    public var title: String {
        switch self {
        case .all: return "All five"
        case .finger(let finger): return finger.title
        }
    }

    public var fingers: [Finger] {
        switch self {
        case .all: return Finger.allCases
        case .finger(let finger): return [finger]
        }
    }
}

public struct NailStudio {
    public static let undoLimit = 40

    public private(set) var manicure: Manicure
    public var scope: PaintScope
    public private(set) var undoStack: [Manicure]
    public private(set) var redoStack: [Manicure]
    private var coverageOrigin: Manicure?

    public init(manicure: Manicure = .blank(), scope: PaintScope = .all) {
        self.manicure = manicure
        self.scope = scope
        self.undoStack = []
        self.redoStack = []
        self.coverageOrigin = nil
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func select(_ finger: Finger) {
        scope = .finger(finger)
    }

    public mutating func selectAll() {
        scope = .all
    }

    @discardableResult
    public mutating func setShape(_ shape: NailShape) -> Bool {
        edit { $0.shape = shape }
    }

    @discardableResult
    public mutating func setColor(_ colorID: String) -> Bool {
        guard Palette.color(id: colorID) != nil else { return false }
        return edit { $0.colorID = colorID }
    }

    @discardableResult
    public mutating func setFinish(_ finish: Finish) -> Bool {
        edit { $0.finish = finish }
    }

    @discardableResult
    public mutating func setFrench(enabled: Bool, colorID: String? = nil, coverage: Double? = nil) -> Bool {
        if let colorID, Palette.color(id: colorID) == nil { return false }
        return edit { nail in
            var tip = nail.french
            tip.enabled = enabled
            if let colorID { tip.colorID = colorID }
            if let coverage { tip.coverage = FrenchTip.clamped(coverage) }
            nail.french = tip
        }
    }

    @discardableResult
    public mutating func setGradient(enabled: Bool, endColorID: String? = nil, angle: Double? = nil) -> Bool {
        if let endColorID, Palette.color(id: endColorID) == nil { return false }
        return edit { nail in
            var fade = nail.gradient
            fade.enabled = enabled
            if let endColorID { fade.endColorID = endColorID }
            if let angle { fade.angle = NailGradient.normalized(angle) }
            nail.gradient = fade
        }
    }

    @discardableResult
    public mutating func addDecoration(motifID: String, colorID: String) -> Bool {
        guard Palette.motif(id: motifID) != nil, Palette.color(id: colorID) != nil else { return false }
        let fingers = scope.fingers
        return commit { manicure in
            for finger in fingers {
                var nail = manicure.nails[finger.rawValue]
                guard nail.decorations.count < NailDesign.maxDecorations else { continue }
                nail.decorations.append(
                    PlacedDecoration.automatic(
                        motifID: motifID,
                        colorID: colorID,
                        index: nail.decorations.count
                    )
                )
                manicure.nails[finger.rawValue] = nail
            }
        }
    }

    public mutating func previewFrenchCoverage(_ coverage: Double) {
        if coverageOrigin == nil {
            coverageOrigin = manicure
        }
        let fingers = scope.fingers
        for finger in fingers {
            var tip = manicure.nails[finger.rawValue].french
            tip.enabled = true
            tip.coverage = FrenchTip.clamped(coverage)
            manicure.nails[finger.rawValue].french = tip
        }
    }

    public mutating func endFrenchCoverage() {
        sealPreview()
    }

    @discardableResult
    public mutating func clearDecorations() -> Bool {
        edit { $0.decorations = [] }
    }

    @discardableResult
    public mutating func apply(look: CuratedLook) -> Bool {
        commit { manicure in
            manicure.name = look.name
            manicure.nails = look.manicure.nails
        }
    }

    @discardableResult
    public mutating func load(saved: SavedLook) -> Bool {
        commit { manicure in
            manicure.name = saved.name
            manicure.nails = saved.manicure.nails
        }
    }

    @discardableResult
    public mutating func undo() -> Bool {
        sealPreview()
        guard let previous = undoStack.popLast() else { return false }
        redoStack.append(manicure)
        manicure = previous
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        sealPreview()
        guard let next = redoStack.popLast() else { return false }
        undoStack.append(manicure)
        manicure = next
        return true
    }

    @discardableResult
    private mutating func edit(_ body: (inout NailDesign) -> Void) -> Bool {
        let fingers = scope.fingers
        return commit { manicure in
            for finger in fingers {
                body(&manicure.nails[finger.rawValue])
            }
        }
    }

    private mutating func sealPreview() {
        guard let origin = coverageOrigin else { return }
        coverageOrigin = nil
        guard origin != manicure else { return }
        undoStack.append(origin)
        if undoStack.count > Self.undoLimit {
            undoStack.removeFirst(undoStack.count - Self.undoLimit)
        }
        redoStack.removeAll()
    }

    private mutating func commit(_ mutate: (inout Manicure) -> Void) -> Bool {
        sealPreview()
        var next = manicure
        mutate(&next)
        guard next != manicure else { return false }
        undoStack.append(manicure)
        if undoStack.count > Self.undoLimit {
            undoStack.removeFirst(undoStack.count - Self.undoLimit)
        }
        redoStack.removeAll()
        manicure = next
        return true
    }
}
