import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                ScreenColumn {
                    VStack(spacing: 14) {
                        step(
                            title: "Walk",
                            text: "Swipe the meadow, tap the pad, or use the arrow keys. Mallow moves one tile. Walls and crates stop a walk."
                        ) {
                            MallowCharacter().frame(width: 84, height: 84)
                        }
                        step(
                            title: "Nudge one crate",
                            text: "Walk into a honey crate to push it one tile. You cannot pull, and you cannot push two crates at once."
                        ) {
                            HStack(spacing: 6) {
                                MallowCharacter(facing: .right).frame(width: 72, height: 72)
                                CrateView().frame(width: 64, height: 64)
                            }
                        }
                        step(
                            title: "Fill every daisy",
                            text: "A level is done when each daisy has a crate. A crate on a daisy sparkles. Undo and Restart are there when a nudge goes sideways."
                        ) {
                            ZStack {
                                DaisyPad(filled: true)
                                CrateView(onGoal: true).padding(16)
                            }
                            .frame(width: 88, height: 88)
                        }
                        CreamCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stars")
                                    .font(Theme.rounded(20))
                                    .foregroundStyle(Theme.ink)
                                Text("Par is the fewest steps. Finish within two steps of par for three stars. A wider band earns two. Any clear earns one. Your best moves stay on this device.")
                                    .font(Theme.rounded(15, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                StarRow(filled: 3, size: 22)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .meadowNavigation()
    }

    private func step<Art: View>(title: String, text: String, @ViewBuilder art: () -> Art) -> some View {
        CreamCard {
            HStack(alignment: .center, spacing: 14) {
                art()
                    .frame(width: 96, height: 88)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(Theme.rounded(20))
                        .foregroundStyle(Theme.ink)
                    Text(text)
                        .font(Theme.rounded(15, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
