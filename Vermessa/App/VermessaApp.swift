import SwiftUI

@main
struct VermessaApp: App {
    @StateObject private var drawer = DrawerModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(drawer)
                .tint(VermessaColor.merlot)
                .preferredColorScheme(.light)
        }
    }
}
