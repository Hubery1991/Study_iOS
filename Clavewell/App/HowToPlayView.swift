import SwiftUI

struct HowToPlayView: View {
    private let steps: [(String, String)] = [
        ("Drop a mote", "Tap a column. The mote falls to the lowest open cell. The next mote waits beside the score."),
        ("Resonate", "Three or more motes of the same color that touch along an edge ring and clear. Corners do not count. Motes above fall into the gap."),
        ("Chains", "If a fall makes a new group, it rings too. Each step multiplies the points for that step."),
        ("Spark", "Every 12th mote is a spark. It bursts the motes touching it, then any new group can ring."),
        ("Scoring", "Each mote in a clear is worth 100 points. Groups larger than three are worth more, and the chain multiplies the step."),
        ("Three wells", "Cadence raises a new row and speeds up as you last. Stillwater never rises. Flare gives you 75 seconds, and clears return a little time."),
        ("How a run ends", "Cadence ends if a rise would pass the rim. Stillwater ends when every column is blocked. Flare ends when the clock reaches zero, or the well locks. Finished runs are saved on this device.")
    ]

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Line up color. Keep the mouth of the well open.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.muted)
                    diagram
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(Theme.serif(18))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Theme.brass))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.0)
                                    .font(Theme.serif(20))
                                    .foregroundStyle(Theme.parchment)
                                Text(step.1)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Color patterns in Settings draw a shape on every mote, for play without relying on color alone. The landing guide marks where the next mote will rest.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var diagram: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Edges match. Corners do not.")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.parchment)
                HStack(spacing: 22) {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            sample(.amber)
                            sample(.amber)
                            sample(.amber)
                        }
                        Text("These clear")
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(Theme.brass)
                    }
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                sample(.tide)
                                sample(.rose)
                            }
                            HStack(spacing: 4) {
                                sample(.rose)
                                sample(.tide)
                            }
                        }
                        Text("These stay")
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private func sample(_ hue: Hue) -> some View {
        MoteView(hue: hue, showPattern: false)
            .frame(width: 28, height: 28)
    }
}
