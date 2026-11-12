import SwiftUI

struct MirrorView: View {
    @ObservedObject var model: MirrorModel
    @ObservedObject var session: FaceSession
    var studio: Bool

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 800
            if wide {
                HStack(spacing: 0) {
                    stage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    sidePanel
                        .frame(width: min(420, geo.size.width * 0.38))
                }
            } else {
                ZStack(alignment: .bottom) {
                    stage
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        Spacer()
                        if !model.document.preferences.hasSeenCoach {
                            coach
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                        ControlDeck(model: model, studio: liveStudio, onCapture: capture)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Theme.ivory.opacity(0.96))
                                    .shadow(color: .black.opacity(0.16), radius: 18, y: 6)
                            )
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .background(Theme.ink)
        .overlay(alignment: .top) { banner }
        .sheet(isPresented: $model.showSuggest) {
            SuggestView(model: model, session: session)
        }
        .sheet(isPresented: $model.showFavorites) {
            FavoritesView(model: model)
        }
        .sheet(isPresented: $model.showAbout) {
            AboutView(model: model)
        }
        .sheet(isPresented: $model.showSave) {
            SaveLookSheet(model: model)
        }
        .onChange(of: model.banner) { message in
            guard message != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                if model.banner == message { model.banner = nil }
            }
        }
    }

    private var liveStudio: Bool {
        studio || session.hardwareMissing
    }

    private var stage: some View {
        GeometryReader { geo in
            ZStack {
                if liveStudio {
                    StudioBackdrop()
                } else {
                    CameraPreview(session: session)
                    MakeupCanvasView(
                        landmarks: session.landmarks,
                        imageSize: session.orientedImageSize,
                        recipe: model.recipe,
                        expression: session.expression,
                        compare: model.compareOn ? CompareSplit(position: model.comparePosition) : nil
                    )
                }
                LinearGradient(
                    colors: [Color.black.opacity(0.38), Color.black.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
                if model.compareOn && !liveStudio {
                    compareChrome(in: geo.size)
                }
                if !liveStudio && !session.faceVisible {
                    Text("Look straight, in even light.")
                        .font(Theme.sans(15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.bottom, 120)
                }
            }
            .contentShape(Rectangle())
            .gesture(compareGesture(width: geo.size.width))
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text("Sheenlisse")
                .font(Theme.serif(28, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Text(liveStudio ? "Studio" : session.mode.label)
                .font(Theme.sans(12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.18)))
            iconButton("sparkles") { model.showSuggest = true }
            iconButton("heart") { model.showFavorites = true }
            iconButton("info.circle") { model.showAbout = true }
        }
    }

    private var sidePanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sheenlisse")
                    .font(Theme.serif(32, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(liveStudio ? "Studio" : session.mode.label)
                    .font(Theme.sans(12, weight: .bold))
                    .foregroundStyle(Theme.plum)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.champagne))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            HStack(spacing: 12) {
                iconButton("sparkles", ink: true) { model.showSuggest = true }
                iconButton("heart", ink: true) { model.showFavorites = true }
                iconButton("info.circle", ink: true) { model.showAbout = true }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            ScrollView {
                ControlDeck(model: model, studio: liveStudio, onCapture: capture)
            }
            if !model.document.preferences.hasSeenCoach {
                coach
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(Theme.ivory)
    }

    private var coach: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Color stays on this iPhone. Nothing is uploaded.")
                .font(Theme.sans(14, weight: .medium))
                .foregroundStyle(Theme.plum)
                .fixedSize(horizontal: false, vertical: true)
            Button("OK") { model.dismissCoach() }
                .font(Theme.sans(14, weight: .bold))
                .foregroundStyle(Theme.rose)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.champagne)
        )
    }

    private var banner: some View {
        Group {
            if let banner = model.banner {
                Text(banner)
                    .font(Theme.sans(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.ivory))
                    .padding(.top, 12)
            }
        }
    }

    private func compareChrome(in size: CGSize) -> some View {
        let x = CGFloat(model.comparePosition) * size.width
        return ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 2)
                .position(x: x, y: size.height / 2)
            Circle()
                .fill(Theme.ivory)
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Theme.gold, lineWidth: 2))
                .overlay(Image(systemName: "arrow.left.and.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.plum))
                .position(x: x, y: size.height * 0.42)
            if x > 70 {
                label("Before", x: x / 2, y: size.height * 0.22)
            }
            if size.width - x > 70 {
                label("After", x: x + (size.width - x) / 2, y: size.height * 0.22)
            }
        }
        .allowsHitTesting(false)
    }

    private func label(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(Theme.sans(13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .position(x: x, y: y)
    }

    private func compareGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard model.compareOn, width > 0 else { return }
                model.comparePosition = min(1, max(0, value.location.x / width))
            }
    }

    private func iconButton(_ name: String, ink: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ink ? Theme.plum : Color.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(ink ? Theme.champagne : Color.white.opacity(0.16)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }

    private func capture() {
        guard !liveStudio else {
            model.banner = "The camera is off, so there is no photo to save."
            return
        }
        guard session.faceVisible else {
            model.banner = "Find your face in the light, then try the shutter again."
            return
        }
        let compare = model.compareOn ? CompareSplit(position: model.comparePosition) : nil
        session.capture(
            recipe: model.recipe,
            expression: session.expression,
            compare: compare
        ) { image in
            guard let image else {
                model.banner = "Could not take the photo. Hold still and try again."
                return
            }
            PhotoLibrarySaver.save(image) { result in
                switch result {
                case .success:
                    model.banner = "Saved to Photos"
                    Haptics.success(enabled: model.document.preferences.hapticsEnabled)
                case .failure(PhotoSaveError.denied):
                    model.banner = "Photos access is off. You can allow it in Settings."
                default:
                    model.banner = "Could not save the photo."
                }
            }
        }
    }
}

struct StudioBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.blush.opacity(0.85), Theme.ivory, Theme.champagne],
                startPoint: .top,
                endPoint: .bottom
            )
            Ellipse()
                .stroke(Theme.gold.opacity(0.85), lineWidth: 1.5)
                .frame(width: 230, height: 300)
                .offset(y: -30)
            VStack(spacing: 6) {
                Text("Studio")
                    .font(Theme.serif(28, weight: .semibold))
                    .foregroundStyle(Theme.plum)
                Text("Build a look without the camera.")
                    .font(Theme.sans(14))
                    .foregroundStyle(Theme.plum.opacity(0.75))
            }
            .offset(y: 180)
        }
    }
}

struct SaveLookSheet: View {
    @ObservedObject var model: MirrorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("This saves the shades and intensities on this device. It does not upload them.")
                    .font(Theme.sans(15))
                    .foregroundStyle(Theme.plum.opacity(0.8))
                TextField("Name", text: $model.draftName)
                    .textFieldStyle(.roundedBorder)
                    .font(Theme.sans(17))
                shadeDots
                Spacer()
            }
            .padding(20)
            .background(Theme.ivory)
            .navigationTitle("Save look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.commitSave() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var shadeDots: some View {
        HStack(spacing: 8) {
            ForEach(MakeupRegion.allCases, id: \.self) { region in
                let setting = model.recipe.setting(for: region)
                Circle()
                    .fill((ShadeCatalog.shade(id: setting.shadeID)?.color.swiftUI) ?? Theme.line)
                    .frame(width: 22, height: 22)
                    .opacity(setting.enabled && setting.intensity > 0 ? 1 : 0.25)
            }
        }
    }
}
