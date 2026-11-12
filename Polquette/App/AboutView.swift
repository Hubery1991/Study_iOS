import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var model: SalonModel
    @State private var confirmReset = false

    var body: some View {
        List {
            Section {
                Text("Polquette is a nail-design game. The hand is drawn in the app. Nothing is uploaded.")
                    .font(.body)
                    .foregroundStyle(SalonTheme.ink)
            }
            Section("On this device") {
                Toggle("Haptics", isOn: hapticsBinding)
                    .tint(SalonTheme.rose)
                Button("Delete saved looks and stars", role: .destructive) {
                    confirmReset = true
                }
            }
            Section("Policies") {
                NavigationLink(LegalCopy.privacyTitle) {
                    LegalPage(title: LegalCopy.privacyTitle, text: LegalCopy.privacy)
                }
                NavigationLink(LegalCopy.termsTitle) {
                    LegalPage(title: LegalCopy.termsTitle, text: LegalCopy.terms)
                }
            }
            Section("Support") {
                Link("Project page", destination: URL(string: "https://github.com/Hubery1991/Study_iOS")!)
                Text("Version 1.0.0")
                    .foregroundStyle(SalonTheme.muted)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete everything saved in Polquette?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { model.resetProgress() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { model.archive.hapticsEnabled },
            set: { model.setHaptics($0) }
        )
    }
}

struct LegalPage: View {
    var title: String
    var text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .foregroundStyle(SalonTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(SalonTheme.ivory)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
