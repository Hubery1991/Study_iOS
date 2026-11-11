import Foundation
import PolquetteCore

final class SalonModel: ObservableObject {
    @Published var studio: NailStudio
    @Published var archive: SalonArchive
    @Published var path = [SalonRoute]()
    @Published var activeBrief: DesignBrief?
    @Published var activeSource: BriefSource?
    @Published var lastScore: AppointmentScore?
    @Published var showScore = false
    @Published var showSave = false
    @Published var saveName = ""
    @Published var showPrimer = false

    private let store: SalonStore

    init(store: SalonStore = SalonStore(url: SalonModel.defaultURL())) {
        self.store = store
        let loaded = (try? store.load()) ?? .empty
        archive = loaded
        studio = NailStudio()
        showPrimer = !loaded.hasSeenPrimer
    }

    static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("polquette-salon.json")
    }

    var today: Date { Date() }

    var todayBrief: DesignBrief { DailyChallenge.brief(on: today) }

    var todayKey: String { DailyChallenge.dayKey(on: today) }

    var todayStars: Int { archive.challenges.stars(on: todayKey) }

    func open(_ route: SalonRoute) {
        path.append(route)
    }

    func openFreeStudio() {
        activeBrief = nil
        activeSource = nil
        open(.studio)
    }

    func beginDaily() {
        activeBrief = todayBrief
        activeSource = .daily(dayKey: todayKey)
        open(.studio)
    }

    func beginCareer(index: Int) {
        guard Career.isUnlocked(index: index, progress: archive.career) else { return }
        activeBrief = Career.clients[index].brief
        activeSource = .career(index: index)
        open(.studio)
    }

    func dismissBrief() {
        activeBrief = nil
        activeSource = nil
    }

    func select(_ finger: Finger) {
        studio.select(finger)
        tap()
    }

    func selectAll() {
        studio.selectAll()
        tap()
    }

    func setShape(_ shape: NailShape) {
        if studio.setShape(shape) { tap() }
    }

    func setColor(_ id: String) {
        if studio.setColor(id) { tap() }
    }

    func setFinish(_ finish: Finish) {
        if studio.setFinish(finish) { tap() }
    }

    func setFrench(enabled: Bool, colorID: String? = nil, coverage: Double? = nil) {
        if studio.setFrench(enabled: enabled, colorID: colorID, coverage: coverage) { tap() }
    }

    func previewFrenchCoverage(_ coverage: Double) {
        studio.previewFrenchCoverage(coverage)
    }

    func endFrenchCoverage() {
        studio.endFrenchCoverage()
    }

    func setGradient(enabled: Bool, endColorID: String? = nil, angle: Double? = nil) {
        if studio.setGradient(enabled: enabled, endColorID: endColorID, angle: angle) { tap() }
    }

    func addDecoration(motifID: String, colorID: String) {
        if studio.addDecoration(motifID: motifID, colorID: colorID) { tap() }
    }

    func clearDecorations() {
        if studio.clearDecorations() { tap() }
    }

    func apply(look: CuratedLook) {
        if studio.apply(look: look) { tap() }
        activeBrief = nil
        activeSource = nil
        if path.last != .studio {
            open(.studio)
        }
    }

    func load(saved: SavedLook) {
        if studio.load(saved: saved) { tap() }
        activeBrief = nil
        activeSource = nil
        open(.studio)
    }

    func undo() {
        if studio.undo() { tap() }
    }

    func redo() {
        if studio.redo() { tap() }
    }

    func prepareSave() {
        saveName = studio.manicure.name == "Untitled" ? "" : studio.manicure.name
        showSave = true
    }

    func confirmSave() {
        _ = archive.saveLook(name: saveName, manicure: studio.manicure)
        showSave = false
        persist()
        if archive.hapticsEnabled { Haptics.success() }
    }

    func deleteLook(id: UUID) {
        if archive.deleteLook(id: id) {
            persist()
            tap()
        }
    }

    func submitActive() {
        guard let brief = activeBrief, let source = activeSource else { return }
        let score = Scoring.score(studio.manicure, brief: brief)
        switch source {
        case .daily(let day):
            archive.challenges.record(day: day, stars: score.stars)
        case .career(let index):
            archive.career.record(index: index, stars: score.stars)
        }
        lastScore = score
        showScore = true
        persist()
        if archive.hapticsEnabled { Haptics.success() }
    }

    var scoreMessage: String {
        guard let score = lastScore else { return "" }
        let missed = score.checks.filter { !$0.met }.map(\.label)
        if score.stars == 3 {
            return "Three stars. Every request on this chair is on the nails."
        }
        if missed.isEmpty {
            return "\(score.stars) stars."
        }
        return "\(score.stars) of 3 stars. Still open: \(missed.joined(separator: ", "))."
    }

    func markPrimerSeen() {
        archive.hasSeenPrimer = true
        showPrimer = false
        persist()
    }

    func setHaptics(_ enabled: Bool) {
        archive.hapticsEnabled = enabled
        persist()
    }

    func resetProgress() {
        archive.resetProgress()
        studio = NailStudio()
        activeBrief = nil
        activeSource = nil
        persist()
    }

    func persist() {
        try? store.save(archive)
    }

    private func tap() {
        if archive.hapticsEnabled { Haptics.tap() }
    }
}
