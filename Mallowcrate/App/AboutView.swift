import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                ScreenColumn {
                    VStack(spacing: 14) {
                        CreamCard {
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    MallowCharacter().frame(width: 72, height: 72)
                                    CrateView().frame(width: 56, height: 56)
                                }
                                Text("Mallowcrate")
                                    .font(Theme.rounded(32))
                                    .foregroundStyle(Theme.ink)
                                Text("Version \(version)")
                                    .font(Theme.rounded(14, weight: .bold))
                                    .foregroundStyle(Theme.inkSoft)
                                Text("A cozy crate puzzle by Jacky Liu. Mallow nudges honey crates onto daisies. No account, no ads, no purchases, and no network is required to play.")
                                    .font(Theme.rounded(16, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        NavigationLink(value: AppRoute.privacy) {
                            row("Privacy Policy", detail: "Data not collected")
                        }
                        .buttonStyle(PressStyle())
                        NavigationLink(value: AppRoute.terms) {
                            row("Terms of Use", detail: "The rules for playing")
                        }
                        .buttonStyle(PressStyle())
                        Link(destination: URL(string: LegalCopy.supportURL)!) {
                            row("Support page", detail: "Opens in the browser")
                        }
                        Text("Progress, sound, and haptics stay on this device.")
                            .font(Theme.rounded(13, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .meadowNavigation()
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        return short
    }

    private func row(_ title: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(18))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.rounded(13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.cream)
                .shadow(color: Theme.shadow, radius: 6, y: 3)
        )
    }
}

struct LegalDocumentView: View {
    var title: String
    var paragraphs: [String]
    var webURL: String

    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                ScreenColumn {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(Theme.rounded(16, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let url = URL(string: webURL) {
                            Link("Open the web copy", destination: url)
                                .font(Theme.rounded(16))
                                .padding(.top, 6)
                        }
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Theme.cream.opacity(0.96))
                    )
                    .padding(20)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .meadowNavigation()
    }
}
