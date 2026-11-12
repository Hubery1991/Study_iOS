import SwiftUI

struct ClosetView: View {
    @ObservedObject var model: ClosetModel
    @State private var filter: GarmentCategory?
    @State private var query = ""
    @State private var showAdd = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var editorID: UUID?
    @State private var permissionAlert: PermissionAlert?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Masthead(kicker: "Wardrobe", title: "Closet")
                    filterRow
                    if filtered.isEmpty {
                        Text(emptyLine)
                            .font(Theme.serif(17))
                            .foregroundStyle(Theme.muted)
                            .padding(.top, 12)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filtered) { garment in
                                Button {
                                    editorID = garment.id
                                } label: {
                                    PieceTile(garment: garment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QUILLISSE")
                        .font(Theme.sans(12, weight: .semibold))
                        .tracking(2.4)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.ink)
                    }
                    .accessibilityLabel("Add a piece")
                }
            }
            .searchable(text: $query, prompt: "Search the closet")
            .confirmationDialog("Add a piece", isPresented: $showAdd, titleVisibility: .visible) {
                Button("Take a photo") { Task { await openCamera() } }
                Button("Choose from Photos") { Task { await openLibrary() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The picture is copied into Quillisse and is not uploaded.")
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    if let id = model.addPhoto(image) {
                        editorID = id
                    }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                LibraryPicker { image in
                    if let id = model.addPhoto(image) {
                        editorID = id
                    }
                }
            }
            .sheet(item: editorBinding) { garment in
                PieceEditor(model: model, garmentID: garment.id)
            }
            .alert(item: $permissionAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Settings"), action: CaptureAccess.openSettings),
                    secondaryButton: .cancel(Text("Not now"))
                )
            }
        }
    }

    private var editorBinding: Binding<Garment?> {
        Binding(
            get: { editorID.flatMap { model.document.garment($0) } },
            set: { editorID = $0?.id }
        )
    }

    private var filtered: [Garment] {
        model.document.garments.filter { garment in
            let categoryOK = filter == nil || garment.category == filter
            let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let textOK = text.isEmpty
                || garment.name.localizedCaseInsensitiveContains(text)
                || garment.primaryColor.displayName.localizedCaseInsensitiveContains(text)
            return categoryOK && textOK
        }
    }

    private var emptyLine: String {
        if model.document.garments.isEmpty {
            return "The closet is empty. Add a photograph of something you own."
        }
        return "Nothing in this filter."
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChoiceChip(title: "All", selected: filter == nil) { filter = nil }
                ForEach(GarmentCategory.allCases, id: \.self) { category in
                    ChoiceChip(title: category.displayName, selected: filter == category) {
                        filter = category
                    }
                }
            }
        }
    }

    private func openCamera() async {
        guard CaptureAccess.cameraAvailable else {
            permissionAlert = PermissionAlert(
                title: "No camera",
                message: "This device has no camera. Choose a picture from Photos instead. Tagging and suggestions still work."
            )
            return
        }
        let allowed = await CaptureAccess.requestCamera()
        if allowed {
            showCamera = true
        } else {
            permissionAlert = PermissionAlert(
                title: "Camera is off",
                message: "Quillisse uses the camera only to photograph clothes. Turn it on in Settings, or choose a picture you already have. Nothing is uploaded."
            )
        }
    }

    private func openLibrary() async {
        let status = await CaptureAccess.requestLibrary()
        switch status {
        case .authorized, .limited:
            showLibrary = true
        case .denied, .restricted:
            permissionAlert = PermissionAlert(
                title: "Photos are off",
                message: "Quillisse needs the photo library only to copy a picture of clothing into the closet on this device. You can turn it on in Settings, or take a photo instead."
            )
        default:
            permissionAlert = PermissionAlert(
                title: "Photos are unavailable",
                message: "The photo library could not be opened. You can take a photo, or try again later."
            )
        }
    }
}

struct PermissionAlert: Identifiable {
    var id = UUID()
    var title: String
    var message: String
}
