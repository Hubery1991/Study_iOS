import SwiftUI

@main
struct NimvelleApp: App {
    @StateObject private var store = RoutineStore()

    init() {
        Theme.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
