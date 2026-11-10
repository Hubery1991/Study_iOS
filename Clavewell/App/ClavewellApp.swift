import SwiftUI

@main
struct ClavewellApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.brass)
        }
    }
}
