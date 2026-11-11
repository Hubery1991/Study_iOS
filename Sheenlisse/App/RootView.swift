import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = FaceSession()
    @StateObject private var model = MirrorModel()
    @State private var studio = false

    var body: some View {
        Group {
            switch session.authorization {
            case .authorized:
                MirrorView(model: model, session: session, studio: studio)
            case .denied, .restricted:
                if studio {
                    MirrorView(model: model, session: session, studio: true)
                } else {
                    PermissionView(noCamera: false, onBrowse: { studio = true }, onSettings: session.openSettings)
                }
            case .notDetermined:
                LaunchHold()
            @unknown default:
                LaunchHold()
            }
        }
        .onAppear { session.prepare() }
        .onChange(of: session.hardwareMissing) { missing in
            if missing { studio = true }
        }
        .onChange(of: scenePhase) { phase in
            guard session.authorization == .authorized else { return }
            if phase == .active {
                session.start()
            } else {
                session.stop()
            }
        }
    }
}
