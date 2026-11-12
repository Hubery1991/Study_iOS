import SwiftUI

enum AppRoute: Hashable {
    case levels
    case game(Int)
    case howTo
    case settings
    case about
    case privacy
    case terms
}

struct RootView: View {
    @StateObject private var store = ProgressStore()

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .levels:
                        LevelSelectView()
                    case .game(let index):
                        GameFlow(index: index)
                    case .howTo:
                        HowToPlayView()
                    case .settings:
                        SettingsView()
                    case .about:
                        AboutView()
                    case .privacy:
                        LegalDocumentView(
                            title: LegalCopy.privacyTitle,
                            paragraphs: LegalCopy.privacyParagraphs,
                            webURL: LegalCopy.privacyURL
                        )
                    case .terms:
                        LegalDocumentView(
                            title: LegalCopy.termsTitle,
                            paragraphs: LegalCopy.termsParagraphs,
                            webURL: LegalCopy.termsURL
                        )
                    }
                }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
        .tint(Theme.coralDeep)
    }
}
