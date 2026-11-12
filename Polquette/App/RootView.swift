import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: SalonModel

    var body: some View {
        NavigationStack(path: $model.path) {
            HomeView()
                .navigationDestination(for: SalonRoute.self) { route in
                    switch route {
                    case .studio:
                        StudioView()
                    case .looks:
                        LooksView()
                    case .gallery:
                        GalleryView()
                    case .challenge:
                        ChallengeView()
                    case .about:
                        AboutView()
                    }
                }
        }
        .tint(SalonTheme.roseDeep)
    }
}
