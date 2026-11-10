import SwiftUI

struct GameView: View {
    @StateObject private var model: PlayModel
    @EnvironmentObject private var router: Router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmRestart = false
    @State private var confirmHome = false
    @State private var showGuide = false

    init(mode: GameMode) {
        _model = StateObject(wrappedValue: PlayModel(mode: mode))
    }

    var body: some View {
        ZStack {
            WellBackground()
            GeometryReader { geo in
                Group {
                    if geo.size.width >= 960 {
                        wideLayout
                    } else {
                        phoneLayout
                            .frame(maxWidth: 560)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            if model.paused && !model.gameOver {
                pauseOverlay
            }
            if model.gameOver {
                gameOverOverlay
            }
        }
        .navigationTitle("Clavewell")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    model.paused = true
                } label: {
                    Image(systemName: "pause.fill")
                }
                .accessibilityLabel("Pause")
                .disabled(model.gameOver)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.toggleSound()
                } label: {
                    Image(systemName: model.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .accessibilityLabel(model.soundOn ? "Mute sound" : "Enable sound")
            }
        }
        .onAppear { model.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { value in
            model.reduceMotion = value
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, !model.gameOver {
                model.paused = true
            }
        }
        .onDisappear { model.stop() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                model.tick(0.1)
            }
        }
        .confirmationDialog("Restart this well?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { model.restart() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("This run will not be saved.")
        }
        .confirmationDialog("Leave this well?", isPresented: $confirmHome, titleVisibility: .visible) {
            Button("Leave", role: .destructive) { router.home() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("An unfinished run is not added to your records.")
        }
        .sheet(isPresented: $showGuide) {
            NavigationStack {
                HowToPlayView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showGuide = false }
                        }
                    }
            }
            .tint(Theme.brass)
            .preferredColorScheme(.dark)
        }
    }

    private var phoneLayout: some View {
        VStack(spacing: 12) {
            scoreHeader(showsQueue: true)
            statusRow
            well
            Text(hint)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 18)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var wideLayout: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                Text(model.mode.title)
                    .font(Theme.serif(32))
                    .foregroundStyle(Theme.parchment)
                Text(model.mode.detail)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                scoreHeader(showsQueue: false)
                statusRow
                Spacer(minLength: 0)
            }
            .frame(width: 250, alignment: .leading)
            well
            VStack(spacing: 18) {
                queueChip(title: "Now", hue: model.now, side: 84)
                queueChip(title: "Next", hue: model.upcoming, side: 64)
                Text(hint)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
    }

    private func scoreHeader(showsQueue: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("SCORE")
                    .font(Theme.rounded(11, .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                Text(Format.score(model.score))
                    .font(Theme.serif(36))
                    .foregroundStyle(Theme.parchment)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("Best \(Format.score(model.shownBest))")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.brass)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            if showsQueue {
                queueChip(title: "Now", hue: model.now, side: 52)
                queueChip(title: "Next", hue: model.upcoming, side: 40)
            }
        }
    }

    private var statusRow: some View {
        Group {
            switch model.mode {
            case .cadence:
                cadenceStatus
            case .flare:
                flareStatus
            case .stillwater:
                HStack {
                    Text("Stillwater")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Text("No rising row")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
    }

    private var cadenceStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.dropsUntilRise <= 0 ? "Rising" : "Rise in \(model.dropsUntilRise)")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.parchment)
                Spacer()
                Text("Pace \(model.riseInterval)")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.muted)
            }
            GeometryReader { geo in
                let fraction = model.riseInterval == 0
                    ? 0
                    : CGFloat(max(model.dropsUntilRise, 0)) / CGFloat(model.riseInterval)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(Theme.brass)
                        .frame(width: max(0, geo.size.width * min(1, fraction)))
                }
            }
            .frame(height: 7)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var flareStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Time")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.parchment)
                Spacer()
                Text(Format.clock(model.timeRemaining))
                    .font(Theme.serif(22))
                    .foregroundStyle(Theme.brass)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                let fraction = min(1, CGFloat(model.timeRemaining / MatchSession.flareDuration))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(Theme.brass)
                        .frame(width: max(0, geo.size.width * max(0, fraction)))
                }
            }
            .frame(height: 7)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var well: some View {
        WellView(
            model: model,
            showPatterns: differentiate || Scorebook.shared.patternsEnabled,
            showGuide: Scorebook.shared.landingGuideEnabled
        )
        .overlay(alignment: .top) { banner }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var banner: some View {
        if let banner = model.banner {
            VStack(spacing: 2) {
                Text(banner)
                    .font(Theme.serif(18))
                    .foregroundStyle(Theme.parchment)
                if let points = model.pointsPop, points > 0 {
                    Text("+\(Format.score(points))")
                        .font(Theme.rounded(13, .bold))
                        .foregroundStyle(Theme.brass)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.ink.opacity(0.9)))
            .overlay(Capsule().strokeBorder(Theme.brass.opacity(0.8), lineWidth: 1))
            .padding(.top, 18)
            .accessibilityElement(children: .combine)
        }
    }

    private var hint: String {
        if model.drops == 0 {
            return "Tap a column to drop the \(model.now.name.lowercased()) mote."
        }
        return "Match three of a color along an edge."
    }

    private func queueChip(title: String, hue: Hue, side: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(Theme.rounded(10, .bold))
                .tracking(1)
                .foregroundStyle(Theme.muted)
            MoteView(hue: hue, showPattern: differentiate || Scorebook.shared.patternsEnabled)
                .frame(width: side, height: side)
            Text(hue.name)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.parchment)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(hue.name)")
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Paused")
                    .font(Theme.serif(34))
                    .foregroundStyle(Theme.parchment)
                Text(model.mode.title)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.muted)
                Button {
                    model.paused = false
                } label: {
                    BrassLabel(title: "Resume")
                }
                .buttonStyle(PressStyle())
                Button {
                    showGuide = true
                } label: {
                    GhostLabel(title: "How to Play")
                }
                .buttonStyle(PressStyle())
                Button {
                    if model.score > 0 {
                        confirmRestart = true
                    } else {
                        model.restart()
                    }
                } label: {
                    GhostLabel(title: "Restart")
                }
                .buttonStyle(PressStyle())
                Button {
                    if model.score > 0 {
                        confirmHome = true
                    } else {
                        router.home()
                    }
                } label: {
                    GhostLabel(title: "Home")
                }
                .buttonStyle(PressStyle())
            }
            .padding(22)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.ink)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Theme.brass.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 12) {
                if model.isNewRecord {
                    Text("NEW RECORD")
                        .font(Theme.rounded(12, .bold))
                        .tracking(1.6)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.brass))
                }
                Text(model.endReason?.title ?? "The well is still")
                    .font(Theme.serif(30))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                Text(model.endReason?.detail ?? "")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                Text(Format.score(model.score))
                    .font(Theme.serif(52))
                    .foregroundStyle(Theme.brass)
                    .monospacedDigit()
                Text("Best \(Format.score(model.shownBest))  ·  Chain \(model.finalChain)  ·  \(model.finalMotes) motes")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                Button {
                    model.restart()
                } label: {
                    BrassLabel(title: "Play again")
                }
                .buttonStyle(PressStyle())
                .padding(.top, 6)
                Button {
                    router.home()
                } label: {
                    GhostLabel(title: "Home")
                }
                .buttonStyle(PressStyle())
            }
            .padding(22)
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.ink)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Theme.brass.opacity(0.45), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GameView(mode: .cadence)
        }
        .environmentObject(Router())
        .preferredColorScheme(.dark)
    }
}
