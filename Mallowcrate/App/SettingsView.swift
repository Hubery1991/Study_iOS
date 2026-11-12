import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                ScreenColumn {
                    VStack(spacing: 14) {
                        CreamCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("On this device")
                                    .font(Theme.rounded(22))
                                    .foregroundStyle(Theme.ink)
                                toggleRow(
                                    title: "Sound",
                                    subtitle: "Soft tones for steps, nudges, and clears.",
                                    isOn: store.save.soundOn
                                ) { on in
                                    store.setSound(on)
                                    if on { ToneBed.shared.tap() }
                                }
                                toggleRow(
                                    title: "Haptics",
                                    subtitle: "Taps when Mallow walks, pushes, and finishes.",
                                    isOn: store.save.hapticsOn
                                ) { store.setHaptics($0) }
                            }
                        }
                        CreamCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progress")
                                    .font(Theme.rounded(22))
                                    .foregroundStyle(Theme.ink)
                                Text("\(store.save.clearedCount) of \(LevelCatalog.levels.count) levels cleared")
                                    .font(Theme.rounded(16, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Text("\(store.save.starCount) of \(LevelCatalog.levels.count * 3) stars")
                                    .font(Theme.rounded(16, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Text("Nothing here is uploaded. Reset clears levels and stars and keeps these switches.")
                                    .font(Theme.rounded(14, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button(role: .destructive) {
                                    confirmReset = true
                                } label: {
                                    Text("Reset progress")
                                        .font(Theme.rounded(16))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(hex: 0xFFE0DC))
                                        )
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .meadowNavigation()
        .confirmationDialog("Reset every level?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) { store.resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stars and best moves will be cleared on this device.")
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Bool, set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: set)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(18))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.rounded(13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .tint(Theme.coral)
    }
}
