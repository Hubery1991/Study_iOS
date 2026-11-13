import SwiftUI

@main
struct LookmiraApp: App {
    @StateObject private var model = DiaryModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(DiaryColor.peachDeep)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: DiaryModel

    var body: some View {
        TabView {
            NavigationStack {
                DiaryScreen()
            }
            .tabItem { Label("Diary", systemImage: "calendar") }

            NavigationStack {
                LibraryScreen()
            }
            .tabItem { Label("Looks", systemImage: "rectangle.stack") }

            NavigationStack {
                RecreateScreen()
            }
            .tabItem { Label("Recreate", systemImage: "arrow.clockwise") }

            NavigationStack {
                SettingsScreen()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .alert("Lookmira", isPresented: bannerPresented) {
            Button("OK", role: .cancel) { model.banner = nil }
        } message: {
            Text(model.banner ?? "")
        }
    }

    private var bannerPresented: Binding<Bool> {
        Binding(
            get: { model.banner != nil },
            set: { if !$0 { model.banner = nil } }
        )
    }
}
