import SwiftUI

@MainActor
final class SettingsModel: ObservableObject {
    @Published var sound: Bool
    @Published var haptics: Bool
    @Published var patterns: Bool
    @Published var guide: Bool

    init() {
        let book = Scorebook.shared
        sound = book.soundEnabled
        haptics = book.hapticsEnabled
        patterns = book.patternsEnabled
        guide = book.landingGuideEnabled
    }

    func persist() {
        let book = Scorebook.shared
        book.soundEnabled = sound
        book.hapticsEnabled = haptics
        book.patternsEnabled = patterns
        book.landingGuideEnabled = guide
    }
}

struct SettingsView: View {
    @StateObject private var model = SettingsModel()
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InfoCard {
                        VStack(spacing: 4) {
                            toggle("Sound", isOn: soundBinding, symbol: "speaker.wave.2.fill")
                            Divider().overlay(Theme.line)
                            toggle("Haptics", isOn: hapticsBinding, symbol: "hand.tap.fill")
                            Divider().overlay(Theme.line)
                            toggle("Color patterns", isOn: patternsBinding, symbol: "circle.grid.2x2")
                            Divider().overlay(Theme.line)
                            toggle("Landing guide", isOn: guideBinding, symbol: "scope")
                        }
                    }
                    Text("Color patterns draw a distinct shape on each mote. The landing guide shows where a mote will come to rest. Both are stored only on this device.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Text("Reset records")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Color(hex: 0xFFB4C0))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color(hex: 0xFFB4C0).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressStyle())
                    Text("Resetting removes high scores and lifetime totals. Sound and the other switches stay as they are.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog("Reset all records?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset records", role: .destructive) {
                Scorebook.shared.resetRecords()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("High scores on this device will be erased.")
        }
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { model.sound },
            set: { value in
                model.sound = value
                model.persist()
                if value { ToneBed.shared.play(.ui) }
            }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { model.haptics },
            set: { value in
                model.haptics = value
                model.persist()
                if value { Haptics.tap() }
            }
        )
    }

    private var patternsBinding: Binding<Bool> {
        Binding(
            get: { model.patterns },
            set: { value in
                model.patterns = value
                model.persist()
            }
        )
    }

    private var guideBinding: Binding<Bool> {
        Binding(
            get: { model.guide },
            set: { value in
                model.guide = value
                model.persist()
            }
        )
    }

    private func toggle(_ title: String, isOn: Binding<Bool>, symbol: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(Theme.brass)
                    .frame(width: 22)
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.parchment)
            }
        }
        .tint(Theme.brass)
        .padding(.vertical, 8)
    }
}
