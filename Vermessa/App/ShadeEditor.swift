import PhotosUI
import SwiftUI
import UIKit
import VermessaCore

struct ShadeEditor: View {
    enum Mode {
        case create(Ownership)
        case edit(Lipstick)
    }

    @EnvironmentObject private var drawer: DrawerModel
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name = ""
    @State private var brand = ""
    @State private var finish: Finish = .satin
    @State private var undertone: Undertone = .neutral
    @State private var family: ColorFamily = .rose
    @State private var occasions: Set<Occasion> = []
    @State private var shade = try! ShadeColor(hex: "B15C6C")
    @State private var photoItem: PhotosPickerItem?
    @State private var newPhotoData: Data?
    @State private var removePhoto = false
    @State private var existingFileName: String?
    @State private var localAlert: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ShadeSwatch(shade: shade, height: 140, title: name.isEmpty ? "New shade" : name, subtitle: brand.isEmpty ? nil : brand)
                    labeledField("Name") {
                        TextField("Lipstick name", text: $name)
                            .font(VermessaFont.display(24))
                            .textInputAutocapitalization(.words)
                    }
                    labeledField("Brand, optional") {
                        TextField("House or brand", text: $brand)
                            .font(VermessaFont.body(18))
                            .textInputAutocapitalization(.words)
                    }
                    pickerRow("Finish") {
                        Picker("Finish", selection: $finish) {
                            ForEach(Finish.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                    }
                    pickerRow("Undertone") {
                        Picker("Undertone", selection: $undertone) {
                            ForEach(Undertone.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                    }
                    pickerRow("Color family") {
                        Picker("Color family", selection: $family) {
                            ForEach(ColorFamily.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Occasions")
                            .font(VermessaFont.display(22))
                            .foregroundStyle(VermessaColor.ink)
                        FlowChips(titles: Occasion.allCases.map { occasion in
                            (occasion.title, occasions.contains(occasion), { toggle(occasion) })
                        })
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Shade color")
                            .font(VermessaFont.display(22))
                            .foregroundStyle(VermessaColor.ink)
                        ColorPicker("Pick a shade", selection: shadeBinding, supportsOpacity: false)
                            .font(VermessaFont.body(18))
                        Text("#\(shade.hex)")
                            .font(VermessaFont.label(18))
                            .foregroundStyle(VermessaColor.mist)
                    }
                    photoSection
                }
                .padding(20)
            }
            .background(VermessaColor.paper)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(VermessaFont.label(18))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(VermessaFont.label(18))
                }
            }
            .alert("Vermessa", isPresented: Binding(
                get: { localAlert != nil },
                set: { if !$0 { localAlert = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localAlert ?? "")
            }
            .onAppear(perform: load)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newPhotoData = data
                        removePhoto = false
                    }
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create: return "Add lipstick"
        case .edit: return "Edit lipstick"
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tube or swatch photo")
                .font(VermessaFont.display(22))
                .foregroundStyle(VermessaColor.ink)
            Text("Optional. Chosen from your photo library and kept on this device.")
                .font(VermessaFont.body(17))
                .foregroundStyle(VermessaColor.mist)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(newPhotoData == nil && existingFileName == nil ? "Choose a photo" : "Replace photo", systemImage: "photo")
                    .font(VermessaFont.label(18))
                    .foregroundStyle(VermessaColor.merlot)
            }
            if newPhotoData != nil || (existingFileName != nil && !removePhoto) {
                Button("Remove photo") {
                    newPhotoData = nil
                    photoItem = nil
                    removePhoto = true
                }
                .font(VermessaFont.label(18))
                .foregroundStyle(VermessaColor.merlot)
            }
        }
    }

    private var shadeBinding: Binding<Color> {
        Binding(
            get: { shade.swiftUIColor },
            set: { color in
                if let next = color.asShadeColor() {
                    shade = next
                }
            }
        )
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(VermessaFont.label(16))
                .foregroundStyle(VermessaColor.mist)
            content()
                .foregroundStyle(VermessaColor.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func pickerRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(VermessaFont.body(18))
            Spacer()
            content()
                .font(VermessaFont.label(18))
        }
        .padding(14)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func toggle(_ occasion: Occasion) {
        if occasions.contains(occasion) {
            occasions.remove(occasion)
        } else {
            occasions.insert(occasion)
        }
    }

    private func load() {
        guard case .edit(let lipstick) = mode else { return }
        name = lipstick.name
        brand = lipstick.brand ?? ""
        finish = lipstick.finish
        undertone = lipstick.undertone
        family = lipstick.colorFamily
        occasions = Set(lipstick.occasions)
        shade = lipstick.shade
        existingFileName = lipstick.swatchFileName
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            localAlert = WardrobeError.emptyName.message
            return
        }
        switch mode {
        case .create(let ownership):
            let draft = LipstickDraft(
                name: trimmed,
                brand: brand,
                finish: finish,
                undertone: undertone,
                colorFamily: family,
                occasions: occasions,
                shade: shade,
                ownership: ownership
            )
            _ = drawer.add(draft, photoData: newPhotoData)
        case .edit(let lipstick):
            var next = lipstick
            next.name = trimmed
            next.brand = brand
            next.finish = finish
            next.undertone = undertone
            next.colorFamily = family
            next.occasions = Occasion.allCases.filter { occasions.contains($0) }
            next.shade = shade
            drawer.save(next, photoData: newPhotoData, removePhoto: removePhoto)
        }
        dismiss()
    }
}

private extension Color {
    func asShadeColor() -> ShadeColor? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return try? ShadeColor(
            red: Int((red * 255).rounded()),
            green: Int((green * 255).rounded()),
            blue: Int((blue * 255).rounded())
        )
    }
}
