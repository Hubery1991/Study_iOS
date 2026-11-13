import SwiftUI

struct RootView: View {
    @EnvironmentObject private var drawer: DrawerModel

    var body: some View {
        TabView {
            WardrobeScreen()
                .tabItem { Label("Drawer", systemImage: "square.grid.2x2.fill") }
            PicksScreen()
                .tabItem { Label("Picks", systemImage: "wand.and.stars") }
            WornScreen()
                .tabItem { Label("Worn", systemImage: "calendar") }
            WishScreen()
                .tabItem { Label("Wish", systemImage: "heart.fill") }
        }
        .alert("Vermessa", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(drawer.alertMessage ?? "")
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { drawer.alertMessage != nil },
            set: { if !$0 { drawer.alertMessage = nil } }
        )
    }
}
