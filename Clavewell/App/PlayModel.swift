import SwiftUI

@MainActor
final class PlayModel: ObservableObject {
    let mode: GameMode

    @Published private(set) var board: WellBoard
    @Published private(set) var score = 0
    @Published private(set) var clearing: Set<CellCoord> = []
    @Published private(set) var banner: String?
    @Published private(set) var pointsPop: Int?
    @Published private(set) var now: Hue
    @Published private(set) var upcoming: Hue
    @Published private(set) var dropsUntilRise: Int
    @Published private(set) var riseInterval: Int
    @Published private(set) var timeRemaining: TimeInterval
    @Published var paused = false
    @Published private(set) var gameOver = false
    @Published private(set) var endReason: EndReason?
    @Published private(set) var isNewRecord = false
    @Published private(set) var busy = false
    @Published private(set) var rejectedColumn: Int?
    @Published private(set) var shake: CGFloat = 0
    @Published private(set) var landing: CellCoord?
    @Published private(set) var landingSettled = true
    @Published private(set) var drops = 0
    @Published var soundOn: Bool
    @Published private(set) var finalChain = 0
    @Published private(set) var finalMotes = 0
    @Published private(set) var storedBest: Int

    var reduceMotion = false
    var shownBest: Int { max(storedBest, score) }

    private var session: MatchSession
    private var playback: Task<Void, Never>?
    private var generation = 0
    private var didRecord = false
    private var active = true

    init(mode: GameMode) {
        let session = MatchSession(mode: mode)
        self.mode = mode
        self.session = session
        board = session.board
        now = session.current
        upcoming = session.upcoming
        dropsUntilRise = session.dropsUntilRise
        riseInterval = session.riseInterval
        timeRemaining = session.timeRemaining
        soundOn = Scorebook.shared.soundEnabled
        storedBest = Scorebook.shared.bestScore(for: mode)
    }

    func drop(in column: Int) {
        guard active, !paused, !gameOver, !busy else { return }
        let outcome = session.drop(in: column)
        if !outcome.accepted {
            reject(column)
            return
        }
        if session.isOver {
            saveRecordIfNeeded()
        }
        drops = session.drops
        timeRemaining = session.timeRemaining
        busy = true
        let token = generation
        playback = Task { [weak self] in
            await self?.play(outcome, token: token)
        }
    }

    func tick(_ delta: TimeInterval) {
        guard active, !paused, !gameOver else { return }
        if session.tick(delta) != nil {
            timeRemaining = 0
            saveRecordIfNeeded()
            if !busy {
                showGameOver()
            }
        } else {
            timeRemaining = session.timeRemaining
        }
    }

    func toggleSound() {
        soundOn.toggle()
        Scorebook.shared.soundEnabled = soundOn
        if soundOn {
            ToneBed.shared.play(.ui)
        }
    }

    func restart() {
        generation += 1
        playback?.cancel()
        playback = nil
        session = MatchSession(mode: mode)
        didRecord = false
        active = true
        board = session.board
        score = 0
        clearing = []
        banner = nil
        pointsPop = nil
        now = session.current
        upcoming = session.upcoming
        dropsUntilRise = session.dropsUntilRise
        riseInterval = session.riseInterval
        timeRemaining = session.timeRemaining
        paused = false
        gameOver = false
        endReason = nil
        isNewRecord = false
        busy = false
        rejectedColumn = nil
        landing = nil
        landingSettled = true
        drops = 0
        finalChain = 0
        finalMotes = 0
        storedBest = Scorebook.shared.bestScore(for: mode)
        soundOn = Scorebook.shared.soundEnabled
    }

    func stop() {
        active = false
        generation += 1
        playback?.cancel()
        playback = nil
    }

    private func reject(_ column: Int) {
        rejectedColumn = column
        ToneBed.shared.play(.reject)
        Haptics.warning()
        withAnimation(.linear(duration: 0.28)) {
            shake += 1
        }
        let token = generation
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, self.generation == token else { return }
            if self.rejectedColumn == column {
                self.rejectedColumn = nil
            }
        }
    }

    private func play(_ outcome: DropOutcome, token: Int) async {
        for frame in outcome.frames {
            if Task.isCancelled || generation != token { return }
            apply(frame, token: token)
            switch frame.kind {
            case .place:
                ToneBed.shared.play(.drop)
                Haptics.tap()
            case .clear:
                ToneBed.shared.play(.clear(chain: frame.chain))
                Haptics.clear(chain: frame.chain)
            case .rise:
                ToneBed.shared.play(.rise)
                Haptics.tap()
            case .settle:
                break
            }
            let delay = delay(for: frame.kind)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            if Task.isCancelled || generation != token { return }
        }
        guard generation == token else { return }
        busy = false
        banner = nil
        clearing = []
        pointsPop = nil
        landing = nil
        landingSettled = true
        playback = nil
        if session.isOver {
            saveRecordIfNeeded()
            showGameOver()
        }
    }

    private func apply(_ frame: Frame, token: Int) {
        board = frame.board
        score = frame.score
        clearing = Set(frame.clearing)
        banner = frame.banner
        pointsPop = frame.pointsJustEarned > 0 ? frame.pointsJustEarned : nil
        now = frame.now
        upcoming = frame.next
        dropsUntilRise = frame.dropsUntilRise
        riseInterval = frame.riseInterval
        if frame.kind == .place, let placed = frame.placed, !reduceMotion {
            landing = placed
            landingSettled = false
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 20_000_000)
                guard let self, self.generation == token, self.landing == placed else { return }
                withAnimation(.easeIn(duration: 0.15)) {
                    self.landingSettled = true
                }
            }
        } else {
            landing = nil
            landingSettled = true
        }
    }

    private func delay(for kind: Frame.Kind) -> Double {
        if reduceMotion {
            return 0.01
        }
        switch kind {
        case .place: return 0.18
        case .clear: return 0.34
        case .settle: return 0.16
        case .rise: return 0.28
        }
    }

    private func saveRecordIfNeeded() {
        guard session.isOver, !didRecord else { return }
        didRecord = true
        finalChain = session.chainBest
        finalMotes = session.motesCleared
        isNewRecord = Scorebook.shared.record(
            score: session.score,
            bestChain: session.chainBest,
            motesCleared: session.motesCleared,
            mode: mode
        )
        storedBest = Scorebook.shared.bestScore(for: mode)
    }

    private func showGameOver() {
        guard active, !gameOver else { return }
        gameOver = true
        paused = false
        endReason = session.ended
        finalChain = session.chainBest
        finalMotes = session.motesCleared
        busy = false
        banner = nil
        clearing = []
        landing = nil
        pointsPop = nil
        if isNewRecord {
            ToneBed.shared.play(.record)
            Haptics.success()
        } else {
            ToneBed.shared.play(.over)
            Haptics.warning()
        }
    }
}
