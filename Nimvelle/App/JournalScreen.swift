import SwiftUI

struct JournalScreen: View {
    @EnvironmentObject private var store: RoutineStore
    @State private var section = 0
    @State private var dryness = 3
    @State private var breakouts = 0
    @State private var mood = 3
    @State private var sleep = 3
    @State private var text = ""
    @State private var loaded = false
    @State private var capture: CaptureChoice?
    @State private var permissionAlert: PermissionAlert?
    @State private var earlierID: UUID?
    @State private var laterID: UUID?
    @State private var showAdd = false
    @State private var saveMessage: String?

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Journal", selection: $section) {
                        Text("Notes").tag(0)
                        Text("Progress").tag(1)
                    }
                    .pickerStyle(.segmented)
                    if section == 0 {
                        notes
                    } else {
                        progress
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadToday)
            .sheet(item: $capture) { choice in
                switch choice {
                case .camera:
                    CameraPicker { image in storePhoto(image) }
                case .library:
                    LibraryPicker { image in storePhoto(image) }
                }
            }
            .alert(item: $permissionAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Settings")) { CaptureAccess.openSettings() },
                    secondaryButton: .cancel(Text("Not now"))
                )
            }
            .alert(item: $saveMessageBinding) { message in
                Alert(title: Text("Photos"), message: Text(message.text), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var notes: some View {
        let trend = NoteTrends.summary(notes: store.studio.notes, today: store.today, window: 14, calendar: store.calendar)
        return VStack(alignment: .leading, spacing: 16) {
            Text("A personal note for dryness, spots, mood, and sleep. Nimvelle does not assess your skin or offer care advice.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            SpaCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Last 14 days")
                        .font(Theme.serif(.title3))
                        .foregroundColor(Theme.ink)
                    TrendRow(title: "Dryness", tint: Theme.clay, values: trend.points.map(\.dryness), scale: 5)
                    TrendRow(title: "Mood", tint: Theme.sage, values: trend.points.map(\.mood), scale: 5)
                    TrendRow(title: "Sleep", tint: Theme.dusk, values: trend.points.map(\.sleep), scale: 5)
                    Text(trendCaption(trend))
                        .font(.footnote)
                        .foregroundColor(Theme.muted)
                }
            }
            SpaCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Today")
                        .font(Theme.serif(.title3))
                        .foregroundColor(Theme.ink)
                    ScalePicker(title: "Dryness", labels: Self.drynessLabels, value: $dryness)
                    ScalePicker(title: "Spots", labels: Self.spotLabels, startsAtZero: true, value: $breakouts)
                    ScalePicker(title: "Mood", labels: Self.moodLabels, value: $mood)
                    ScalePicker(title: "Sleep", labels: Self.sleepLabels, value: $sleep)
                    TextEditor(text: $text)
                        .frame(minHeight: 88)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.line, lineWidth: 1)
                        )
                    if text.isEmpty {
                        Text("How did skin feel today? A word is enough.")
                            .font(.footnote)
                            .foregroundColor(Theme.muted)
                    }
                    Button("Save note") { saveNote() }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.card)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Theme.sageDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if store.studio.notes.contains(where: { $0.day == store.today }) {
                        Button("Remove today’s note", role: .destructive) {
                            if let note = store.studio.notes.first(where: { $0.day == store.today }) {
                                store.deleteNote(id: note.id)
                                text = ""
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            recentNotes
        }
    }

    private var recentNotes: some View {
        let recent = store.studio.notes.sorted { $0.day > $1.day }.prefix(6)
        return VStack(alignment: .leading, spacing: 10) {
            if recent.isEmpty {
                EmptyNote(title: "No notes yet", message: "Save one when you want a memory of the day. It stays on this device.")
            } else {
                Text("Recent")
                    .font(Theme.serif(.title3))
                    .foregroundColor(Theme.ink)
                ForEach(Array(recent)) { note in
                    SpaCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(DayText.medium(note.day, calendar: store.calendar))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.sageDeep)
                            Text(noteLine(note))
                                .font(.subheadline)
                                .foregroundColor(Theme.ink)
                            if !note.text.isEmpty {
                                Text(note.text)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Once a week is plenty. Photos stay on this device unless you save a copy to Photos.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            compare
            Button {
                showAdd = true
            } label: {
                Text("Add a photo")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.card)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Theme.sageDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .confirmationDialog("Add a progress photo", isPresented: $showAdd, titleVisibility: .visible) {
                if CaptureAccess.cameraAvailable {
                    Button("Take a photo") { begin(.camera) }
                }
                Button("Choose a photo") { begin(.library) }
                Button("Cancel", role: .cancel) {}
            }
            if !sortedPhotos.isEmpty {
                Text("On this device")
                    .font(Theme.serif(.title3))
                    .foregroundColor(Theme.ink)
                ForEach(sortedPhotos) { photo in
                    photoRow(photo)
                }
            }
        }
        .onAppear(perform: alignCompare)
        .onChange(of: store.studio.photos) { _ in alignCompare() }
    }

    @ViewBuilder
    private var compare: some View {
        let photos = sortedPhotos
        if photos.isEmpty {
            SpaCard {
                EmptyNote(
                    title: "No progress photos",
                    message: "Add two, a week or so apart, and they sit here side by side. Nothing is uploaded."
                )
            }
        } else if photos.count == 1, let only = photos.first {
            SpaCard {
                VStack(alignment: .leading, spacing: 10) {
                    photoFrame(only)
                    Text("Add another when you want a side-by-side.")
                        .font(.footnote)
                        .foregroundColor(Theme.muted)
                }
            }
        } else {
            SpaCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        compareMenu(title: "Earlier", selection: $earlierID, photos: photos)
                        compareMenu(title: "Later", selection: $laterID, photos: photos)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        compareColumn(id: earlierID, caption: "Earlier")
                        compareColumn(id: laterID, caption: "Later")
                    }
                }
            }
        }
    }

    private func compareMenu(title: String, selection: Binding<UUID?>, photos: [ProgressPhoto]) -> some View {
        Picker(title, selection: selection) {
            ForEach(photos) { photo in
                Text(DayText.medium(photo.day, calendar: store.calendar)).tag(Optional(photo.id))
            }
        }
        .pickerStyle(.menu)
        .tint(Theme.sageDeep)
    }

    private func compareColumn(id: UUID?, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let photo = store.studio.photos.first(where: { $0.id == id }) {
                photoFrame(photo)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 180)
            }
            Text(caption)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func photoFrame(_ photo: ProgressPhoto) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let image = PhotoFiles.image(fileName: photo.fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.blush
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(DayText.medium(photo.day, calendar: store.calendar))
                .font(.caption)
                .foregroundColor(Theme.ink)
        }
    }

    private func photoRow(_ photo: ProgressPhoto) -> some View {
        SpaCard {
            HStack(spacing: 12) {
                if let image = PhotoFiles.image(fileName: photo.fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(DayText.medium(photo.day, calendar: store.calendar))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.ink)
                    Button("Save a copy to Photos") {
                        Task { await saveCopy(photo) }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.sageDeep)
                }
                Spacer()
                Button(role: .destructive) {
                    store.deletePhoto(photo)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete photo")
            }
        }
    }

    private var sortedPhotos: [ProgressPhoto] {
        store.studio.photos.sorted { lhs, rhs in
            if lhs.day != rhs.day { return lhs.day < rhs.day }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private func loadToday() {
        guard !loaded else { return }
        loaded = true
        if let note = store.studio.notes.first(where: { $0.day == store.today }) {
            dryness = note.dryness
            breakouts = note.breakouts
            mood = note.mood
            sleep = note.sleep
            text = note.text
        }
    }

    private func saveNote() {
        let note = SkinNote(
            id: UUID(),
            day: store.today,
            dryness: dryness,
            breakouts: breakouts,
            mood: mood,
            sleep: sleep,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.save(note: note)
    }

    private func trendCaption(_ trend: TrendSummary) -> String {
        if trend.notedDays == 0 { return "Notes you save will draw this quiet chart." }
        let spots: String
        if trend.breakoutDays == 0 {
            spots = "No days with spots in this window."
        } else if trend.breakoutDays == 1 {
            spots = "1 day with spots in this window."
        } else {
            spots = "\(trend.breakoutDays) days with spots in this window."
        }
        return "\(trend.notedDays) noted days. \(spots)"
    }

    private func noteLine(_ note: SkinNote) -> String {
        let dry = Self.drynessLabels[max(0, min(4, note.dryness - 1))]
        let mood = Self.moodLabels[max(0, min(4, note.mood - 1))]
        let sleep = Self.sleepLabels[max(0, min(4, note.sleep - 1))]
        let spots = Self.spotLabels[max(0, min(3, note.breakouts))]
        return "\(dry) · spots \(spots.lowercased()) · \(mood.lowercased()) · sleep \(sleep.lowercased())"
    }

    private func alignCompare() {
        let photos = sortedPhotos
        guard photos.count >= 2 else {
            earlierID = photos.first?.id
            laterID = nil
            return
        }
        if earlierID == nil || !photos.contains(where: { $0.id == earlierID }) {
            earlierID = photos.first?.id
        }
        if laterID == nil || !photos.contains(where: { $0.id == laterID }) || laterID == earlierID {
            laterID = photos.last?.id
        }
    }

    private func begin(_ choice: CaptureChoice) {
        Task {
            let allowed: Bool
            if choice == .camera {
                allowed = await CaptureAccess.requestCamera()
            } else {
                allowed = await CaptureAccess.requestLibrary()
            }
            if allowed {
                try? await Task.sleep(nanoseconds: 350_000_000)
                capture = choice
            } else {
                permissionAlert = PermissionAlert(
                    title: choice == .camera ? "Camera is off" : "Photos is off",
                    message: choice == .camera
                        ? "Nimvelle can take a progress photo only if you allow the camera. The rest of the journal still works."
                        : "Nimvelle can choose a photo only if you allow the library. You can still use the camera, and nothing is uploaded."
                )
            }
        }
    }

    private func storePhoto(_ image: UIImage) {
        guard let name = PhotoFiles.save(image) else {
            saveMessage = "That photo could not be saved on this device."
            return
        }
        store.addPhoto(fileName: name, day: store.today)
    }

    private func saveCopy(_ photo: ProgressPhoto) async {
        guard let image = PhotoFiles.image(fileName: photo.fileName) else { return }
        let ok = await CaptureAccess.saveToLibrary(image)
        saveMessage = ok
            ? "A copy is in Photos. Nimvelle did not upload it."
            : "Photos is not allowing new pictures. The copy in Nimvelle is still here."
    }

    private var saveMessageBinding: Binding<Notice?> {
        Binding(
            get: { saveMessage.map { Notice(text: $0) } },
            set: { saveMessage = $0?.text }
        )
    }

    private static let drynessLabels = ["Comfortable", "A little dry", "Dry", "Quite dry", "Very dry"]
    private static let spotLabels = ["None", "A little", "Noticeable", "A lot"]
    private static let moodLabels = ["Low", "Quiet", "Even", "Bright", "Light"]
    private static let sleepLabels = ["Restless", "Light", "Okay", "Sound", "Rested"]
}

private struct TrendRow: View {
    var title: String
    var tint: Color
    var values: [Int?]
    var scale: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(values.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(values[index] == nil ? Theme.line : tint)
                        .frame(height: height(values[index]))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56, alignment: .bottom)
        }
    }

    private func height(_ value: Int?) -> CGFloat {
        guard let value else { return 4 }
        let fraction = CGFloat(value) / CGFloat(max(scale, 1))
        return max(8, 56 * fraction)
    }
}

enum CaptureChoice: Identifiable {
    case camera
    case library
    var id: Int { self == .camera ? 0 : 1 }
}

struct PermissionAlert: Identifiable {
    var title: String
    var message: String
    var id: String { title }
}

private struct Notice: Identifiable {
    var text: String
    var id: String { text }
}
