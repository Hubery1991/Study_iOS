import SwiftUI

struct PieceEditor: View {
    @ObservedObject var model: ClosetModel
    var garmentID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Garment?
    @State private var saveMessage: String?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Group {
                if draft != nil {
                    form
                } else {
                    Text("This piece is no longer in the closet.")
                        .font(Theme.serif(18))
                        .padding()
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commit() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Saved to Photos", isPresented: savedBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveMessage ?? "")
            }
            .confirmationDialog("Delete this piece?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    model.deleteGarment(garmentID)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It leaves the closet on this device. The journal drops it from past days.")
            }
        }
        .onAppear {
            draft = model.document.garment(garmentID)
        }
    }

    private var savedBinding: Binding<Bool> {
        Binding(get: { saveMessage != nil }, set: { if !$0 { saveMessage = nil } })
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let token = draft?.imageToken {
                    GarmentPhoto(token: token)
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                field("Name") {
                    TextField("Name", text: nameBinding)
                        .font(Theme.serif(22))
                }
                chipSection("Category", items: GarmentCategory.allCases.map { ($0.displayName, draft?.category == $0) }) { index in
                    draft?.category = GarmentCategory.allCases[index]
                }
                chipSection("Formality", items: Formality.allCases.map { ($0.displayName, draft?.formality == $0) }) { index in
                    draft?.formality = Formality.allCases[index]
                }
                chipSection("Weight", items: GarmentWeight.allCases.map { ($0.displayName, draft?.weight == $0) }) { index in
                    draft?.weight = GarmentWeight.allCases[index]
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(Theme.sans(12, weight: .semibold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.muted)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                        ForEach(GarmentColor.allCases, id: \.self) { color in
                            Button {
                                toggle(color)
                            } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(Theme.swatch(color)).frame(width: 12, height: 12)
                                    Text(color.displayName)
                                        .font(Theme.sans(12, weight: .medium))
                                        .foregroundStyle(Theme.ink)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .background((draft?.colors.contains(color) ?? false) ? Theme.card : Color.clear)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("The first color is the one suggestions use.")
                        .font(Theme.sans(12, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Season")
                        .font(Theme.sans(12, weight: .semibold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.muted)
                    chipFlow(Season.allCases.map { season in
                        (season.displayName, draft?.seasons.contains(season) ?? false)
                    }) { index in
                        toggleSeason(Season.allCases[index])
                    }
                }
                Toggle(isOn: favoriteBinding) {
                    Text("Favorite")
                        .font(Theme.serif(18))
                }
                .tint(Theme.oxblood)
                field("Note") {
                    TextField("Optional note", text: noteBinding)
                        .font(Theme.serif(16))
                }
                EditorialButton(title: "Save a copy to Photos", filled: false) {
                    Task { await saveCopy() }
                }
                Button("Delete piece", role: .destructive) {
                    confirmDelete = true
                }
                .font(Theme.sans(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    private var nameBinding: Binding<String> {
        Binding(get: { draft?.name ?? "" }, set: { draft?.name = $0 })
    }

    private var noteBinding: Binding<String> {
        Binding(get: { draft?.note ?? "" }, set: { draft?.note = $0 })
    }

    private var favoriteBinding: Binding<Bool> {
        Binding(get: { draft?.isFavorite ?? false }, set: { draft?.isFavorite = $0 })
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.sans(12, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
            content()
        }
    }

    private func chipSection(_ title: String, items: [(String, Bool)], onTap: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.sans(12, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
            chipFlow(items, onTap: onTap)
        }
    }

    private func chipFlow(_ items: [(String, Bool)], onTap: @escaping (Int) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ChoiceChip(title: item.0, selected: item.1) { onTap(index) }
                }
            }
        }
    }

    private func toggle(_ color: GarmentColor) {
        guard var draft else { return }
        if let index = draft.colors.firstIndex(of: color) {
            if draft.colors.count == 1 { return }
            draft.colors.remove(at: index)
        } else if draft.colors.count < 3 {
            draft.colors.append(color)
        } else {
            draft.colors.removeLast()
            draft.colors.append(color)
        }
        self.draft = draft
    }

    private func toggleSeason(_ season: Season) {
        guard var draft else { return }
        if season == .allSeason {
            draft.seasons = [.allSeason]
        } else {
            draft.seasons.removeAll { $0 == .allSeason }
            if let index = draft.seasons.firstIndex(of: season) {
                draft.seasons.remove(at: index)
            } else {
                draft.seasons.append(season)
            }
            if draft.seasons.isEmpty { draft.seasons = [.allSeason] }
        }
        self.draft = draft
    }

    private func commit() {
        guard let draft else { return }
        model.save(draft)
        dismiss()
    }

    private func saveCopy() async {
        guard let token = draft?.imageToken, let image = PhotoStore.uiImage(for: token) else {
            saveMessage = "There is no picture to save."
            return
        }
        let saved = await CaptureAccess.saveToLibrary(image)
        saveMessage = saved
            ? "A copy is in your Photos library. Quillisse did not upload it."
            : "Photos access for saving is off. The closet copy is unchanged. You can allow adding photos in Settings."
    }
}
