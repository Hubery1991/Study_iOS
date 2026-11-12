import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            MeadowBackground()
            ScreenColumn {
                VStack(spacing: 18) {
                    hero
                    VStack(spacing: 4) {
                        Text("Mallowcrate")
                            .font(Theme.rounded(46))
                            .foregroundStyle(Theme.ink)
                        Text("Nudge every honey crate onto a daisy.")
                            .font(Theme.rounded(16, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    Text("\(store.save.starCount) / \(LevelCatalog.levels.count * 3) stars")
                        .font(Theme.rounded(14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.cream))
                    VStack(spacing: 12) {
                        NavigationLink(value: AppRoute.game(nextIndex)) {
                            jellyLabel(playTitle, subtitle: playSubtitle, fill: Theme.coral, ink: .white)
                        }
                        .buttonStyle(PressStyle())
                        NavigationLink(value: AppRoute.levels) {
                            jellyLabel("Levels", subtitle: nil, fill: Theme.cream, ink: Theme.ink)
                        }
                        .buttonStyle(PressStyle())
                        HStack(spacing: 12) {
                            NavigationLink(value: AppRoute.howTo) {
                                jellyLabel("How to Play", subtitle: nil, fill: Theme.leaf, ink: .white)
                            }
                            .buttonStyle(PressStyle())
                            NavigationLink(value: AppRoute.settings) {
                                jellyLabel("Settings", subtitle: nil, fill: Theme.cream, ink: Theme.ink)
                            }
                            .buttonStyle(PressStyle())
                        }
                        NavigationLink(value: AppRoute.about) {
                            Text("About")
                                .font(Theme.rounded(16))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
            }
        }
        .navigationBarHidden(true)
    }

    private var hero: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let bob = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 2) * 6
            HStack(alignment: .bottom, spacing: 8) {
                DaisyPad()
                    .frame(width: 72, height: 72)
                    .offset(y: -bob * 0.3)
                MallowCharacter()
                    .frame(width: 150, height: 150)
                    .offset(y: bob)
                CrateView()
                    .frame(width: 86, height: 86)
                    .offset(y: -8)
            }
            .frame(height: 170)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Mallow, a round marshmallow courier, beside a honey crate and a daisy.")
        }
    }

    private var nextIndex: Int {
        store.save.nextPlayableIndex(levelCount: LevelCatalog.levels.count)
    }

    private var nextLevel: LevelDefinition {
        LevelCatalog.levels[nextIndex - 1]
    }

    private var playTitle: String {
        store.save.clearedCount == LevelCatalog.levels.count ? "Play again" : "Play"
    }

    private var playSubtitle: String {
        "Level \(nextLevel.index) · \(nextLevel.title)"
    }

    private func jellyLabel(_ title: String, subtitle: String?, fill: Color, ink: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Theme.rounded(subtitle == nil ? 18 : 22))
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(13, weight: .semibold))
                    .opacity(0.92)
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, subtitle == nil ? 14 : 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .shadow(color: Theme.ink.opacity(0.14), radius: 0, y: 5)
        )
    }
}
