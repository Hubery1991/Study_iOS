import SwiftUI

struct AboutView: View {
    @ObservedObject var model: MirrorModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sheenlisse")
                            .font(Theme.serif(32, weight: .semibold))
                        Text("A mirror for color. Lipstick, blush, eyeshadow, liner, and brows, drawn on your face while you look.")
                            .font(Theme.sans(15))
                            .foregroundStyle(Theme.plum.opacity(0.85))
                        Text("Version 1.0.0")
                            .font(Theme.sans(13))
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.vertical, 6)
                    Toggle("Haptics", isOn: Binding(
                        get: { model.document.preferences.hapticsEnabled },
                        set: { model.setHaptics($0) }
                    ))
                    .tint(Theme.rose)
                }
                Section("On this device") {
                    NavigationLink("Privacy Policy") {
                        LegalPage(title: LegalCopy.privacyTitle, paragraphs: LegalCopy.privacyParagraphs)
                    }
                    NavigationLink("Terms of Use") {
                        LegalPage(title: LegalCopy.termsTitle, paragraphs: LegalCopy.termsParagraphs)
                    }
                    Link("Support page", destination: URL(string: LegalCopy.supportURL)!)
                    Button("Delete saved looks", role: .destructive) {
                        confirmDelete = true
                    }
                }
                Section {
                    Text("The camera is used only for the live preview. Frames, face geometry, and photos are not uploaded. There is no account.")
                        .font(Theme.sans(14))
                        .foregroundStyle(Theme.plum.opacity(0.85))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.ivory)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete saved looks?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { model.deleteAllFavorites() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Favorites on this device will be removed. The look currently in the mirror stays.")
            }
        }
    }
}

struct LegalPage: View {
    var title: String
    var paragraphs: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(Theme.serif(34, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                ForEach(paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(Theme.sans(16))
                        .foregroundStyle(Theme.plum)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.ivory)
        .navigationBarTitleDisplayMode(.inline)
    }
}
