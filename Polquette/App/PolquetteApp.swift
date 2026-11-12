import SwiftUI

@main
struct PolquetteApp: App {
    @StateObject private var model = SalonModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}
