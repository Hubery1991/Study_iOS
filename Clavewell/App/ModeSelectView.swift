import SwiftUI

struct ModeSelectView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(spacing: 14) {
                    Text("Choose a well. Each one keeps its own records on this device.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(GameMode.allCases) { mode in
                        Button {
                            router.path.append(AppRoute.game(mode))
                        } label: {
                            modeCard(mode)
                        }
                        .buttonStyle(PressStyle())
                    }
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func modeCard(_ mode: GameMode) -> some View {
        let best = Scorebook.shared.bestScore(for: mode)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mode.title)
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.parchment)
                Spacer()
                Text(best > 0 ? "Best \(Format.score(best))" : "No record yet")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.brass)
            }
            Text(mode.summary)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.parchment.opacity(0.9))
            Text(mode.detail)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.brass.opacity(0.28), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }
}
