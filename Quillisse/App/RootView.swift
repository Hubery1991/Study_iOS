import SwiftUI

struct RootView: View {
    @StateObject private var model = ClosetModel()

    var body: some View {
        TabView {
            TodayView(model: model)
                .tabItem { Label("Today", systemImage: "sun.max") }
            ClosetView(model: model)
                .tabItem { Label("Closet", systemImage: "tshirt") }
            AtelierView(model: model)
                .tabItem { Label("Atelier", systemImage: "square.grid.2x2") }
            JournalView(model: model)
                .tabItem { Label("Journal", systemImage: "calendar") }
        }
        .tint(Theme.oxblood)
    }
}
