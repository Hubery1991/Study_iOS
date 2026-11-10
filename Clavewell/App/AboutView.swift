import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clavewell")
                            .font(Theme.serif(36))
                            .foregroundStyle(Theme.parchment)
                        Text("Version \(version)")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.brass)
                    }
                    Text("Clavewell is an original puzzle by Jacky Liu. Drop colored motes into a well, ring groups of three, and stay ahead of the dark.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.parchment.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("There is no account, no advertising, and no purchase. Scores and settings stay on this device. The artwork is drawn in SwiftUI. The tones are synthesized here, when you play. Nothing is downloaded.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 10) {
                        Button {
                            router.path.append(AppRoute.privacy)
                        } label: {
                            GhostLabel(title: "Privacy Policy")
                        }
                        .buttonStyle(PressStyle())
                        Button {
                            router.path.append(AppRoute.terms)
                        } label: {
                            GhostLabel(title: "Terms of Use")
                        }
                        .buttonStyle(PressStyle())
                    }
                    .padding(.top, 4)
                    Text("© 2026 Jacky Liu")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
