import SwiftUI

struct RecordsView: View {
    @State private var revision = 0

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    let stats = Scorebook.shared.stats
                    InfoCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("On this device")
                                .font(Theme.rounded(13, .bold))
                                .foregroundStyle(Theme.brass)
                            Text("\(stats.gamesPlayed) finished \(stats.gamesPlayed == 1 ? "run" : "runs")")
                                .font(Theme.serif(22))
                                .foregroundStyle(Theme.parchment)
                            Text("\(Format.score(stats.motesCleared)) motes cleared  ·  best chain \(stats.bestChain)")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    ForEach(GameMode.allCases) { mode in
                        modeCard(mode)
                    }
                    Text("Records stay in local storage on this device. They are not uploaded.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
        .id(revision)
        .navigationTitle("Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { revision += 1 }
    }

    private func modeCard(_ mode: GameMode) -> some View {
        let runs = Scorebook.shared.top(for: mode)
        return InfoCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mode.title)
                        .font(Theme.serif(22))
                        .foregroundStyle(Theme.parchment)
                    Spacer()
                    Text(runs.first.map { Format.score($0.score) } ?? "—")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.brass)
                        .monospacedDigit()
                }
                if runs.isEmpty {
                    Text("No finished runs yet.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
                        HStack {
                            Text("\(index + 1)")
                                .font(Theme.rounded(13, .bold))
                                .foregroundStyle(Theme.muted)
                                .frame(width: 16, alignment: .leading)
                            Text(Format.score(run.score))
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.parchment)
                                .monospacedDigit()
                            Spacer()
                            Text("chain \(run.bestChain)")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
    }
}
