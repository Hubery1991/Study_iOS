import SwiftUI

struct CameraPreview: View {
    @ObservedObject var session: FaceSession

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                if let preview = session.preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}
