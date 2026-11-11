import SwiftUI

struct SuggestView: View {
    @ObservedObject var model: MirrorModel
    @ObservedObject var session: FaceSession
    @Environment(\.dismiss) private var dismiss
    @State private var shape: FaceShape = .oval
    @State private var tone: SkinTone = .medium

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(seenNote)
                        .font(Theme.sans(14))
                        .foregroundStyle(Theme.plum.opacity(0.75))
                    chipGroup(title: "Face shape", items: FaceShape.allCases.map(\.title), selected: shape.title) { title in
                        if let match = FaceShape.allCases.first(where: { $0.title == title }) {
                            shape = match
                        }
                    }
                    chipGroup(title: "Skin tone", items: SkinTone.allCases.map(\.title), selected: tone.title) { title in
                        if let match = SkinTone.allCases.first(where: { $0.title == title }) {
                            tone = match
                        }
                    }
                    suggestionCard
                    Text("A starting point, not a rule. Color reads differently in every light, and the screen is not a cosmetic product.")
                        .font(Theme.sans(13))
                        .foregroundStyle(Theme.plum.opacity(0.7))
                }
                .padding(20)
            }
            .background(Theme.ivory)
            .navigationTitle("For you")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            shape = session.faceShape ?? .oval
            tone = session.skinTone ?? .medium
        }
    }

    private var seenNote: String {
        if session.faceVisible {
            return "Seen just now from the camera, on this device. You can change either reading."
        }
        if session.faceShape != nil || session.skinTone != nil {
            return "Using the last reading from this device. You can change it."
        }
        return "Choose a shape and a tone. Nothing is stored except the look you save."
    }

    private func chipGroup(title: String, items: [String], selected: String, choose: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.sans(13, weight: .semibold))
                .foregroundStyle(Theme.gold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        choose(item)
                    } label: {
                        Text(item)
                            .font(Theme.sans(14, weight: .semibold))
                            .foregroundStyle(selected == item ? Color.white : Theme.plum)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selected == item ? Theme.rose : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selected == item ? Theme.rose : Theme.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var suggestionCard: some View {
        let suggestion = SuggestionEngine.suggest(shape: shape, tone: tone)
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(shape.title) · \(tone.title)")
                .font(Theme.sans(13, weight: .bold))
                .foregroundStyle(Theme.gold)
                .textCase(.uppercase)
                .tracking(0.6)
            Text(suggestion.headline)
                .font(Theme.serif(28, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(suggestion.look.tagline)
                .font(Theme.sans(15))
                .foregroundStyle(Theme.plum)
            ForEach(suggestion.notes, id: \.self) { note in
                Text(note)
                    .font(Theme.sans(15))
                    .foregroundStyle(Theme.ink.opacity(0.85))
            }
            Button {
                model.applySuggestion(shape: shape, tone: tone)
                dismiss()
            } label: {
                Text("Try this look")
                    .font(Theme.sans(17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.rose))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Theme.plum.opacity(0.06), radius: 10, y: 4)
        )
    }
}
