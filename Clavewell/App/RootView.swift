import SwiftUI

enum AppRoute: Hashable {
    case modes
    case game(GameMode)
    case howTo
    case records
    case settings
    case about
    case privacy
    case terms
}

@MainActor
final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func home() {
        path = NavigationPath()
    }
}

struct RootView: View {
    @StateObject private var router = Router()
    @State private var showHowTo = false

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .modes:
                        ModeSelectView()
                    case .game(let mode):
                        GameView(mode: mode)
                    case .howTo:
                        HowToPlayView()
                    case .records:
                        RecordsView()
                    case .settings:
                        SettingsView()
                    case .about:
                        AboutView()
                    case .privacy:
                        LegalDocumentView(document: .privacy)
                    case .terms:
                        LegalDocumentView(document: .terms)
                    }
                }
        }
        .environmentObject(router)
        .sheet(isPresented: $showHowTo, onDismiss: {
            Scorebook.shared.seenHowTo = true
        }) {
            NavigationStack {
                HowToPlayView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showHowTo = false }
                        }
                    }
            }
            .tint(Theme.brass)
            .preferredColorScheme(.dark)
        }
        .task {
            if !Scorebook.shared.seenHowTo {
                showHowTo = true
            }
        }
    }
}
