import SwiftUI

struct AboutView: View {
    @ObservedObject var model: ClosetModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSample = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Quillisse keeps a closet on this device and suggests a look for the day. There is no account.")
                        .font(Theme.serif(18))
                        .foregroundStyle(Theme.ink)
                    Toggle(isOn: hapticsBinding) {
                        Text("Haptics")
                            .font(Theme.serif(18))
                    }
                    .tint(Theme.oxblood)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Repeat window")
                            .font(Theme.serif(18))
                        Text("A look worn inside this many days is ranked lower.")
                            .font(Theme.sans(13, weight: .medium))
                            .foregroundStyle(Theme.muted)
                        Stepper(value: windowBinding, in: 3...21) {
                            Text("\(model.document.preferences.clampedWindow) days")
                                .font(Theme.sans(15, weight: .semibold))
                        }
                    }
                    Button("Remove the sample closet") { confirmSample = true }
                        .font(Theme.sans(15, weight: .semibold))
                        .foregroundStyle(Theme.oxblood)
                    legal(LegalCopy.privacyTitle, LegalCopy.privacyParagraphs)
                    legal(LegalCopy.termsTitle, LegalCopy.termsParagraphs)
                    VStack(alignment: .leading, spacing: 8) {
                        Link("Privacy on the web", destination: URL(string: LegalCopy.privacyURL)!)
                        Link("Terms on the web", destination: URL(string: LegalCopy.termsURL)!)
                        Link("Support", destination: URL(string: LegalCopy.supportURL)!)
                    }
                    .font(Theme.sans(15, weight: .semibold))
                    .tint(Theme.oxblood)
                    Text("Version 1.0.0")
                        .font(Theme.sans(12, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Remove the sample pieces?", isPresented: $confirmSample, titleVisibility: .visible) {
                Button("Remove sample pieces", role: .destructive) {
                    model.removeSamplePieces()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Pieces you photographed stay. Sample journal days that only used sample pieces are removed.")
            }
        }
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { model.document.preferences.hapticsEnabled },
            set: { value in model.updatePreferences { $0.hapticsEnabled = value } }
        )
    }

    private var windowBinding: Binding<Int> {
        Binding(
            get: { model.document.preferences.clampedWindow },
            set: { value in model.updatePreferences { $0.repeatWindowDays = value } }
        )
    }

    private func legal(_ title: String, _ paragraphs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.serif(24))
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(Theme.serif(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
