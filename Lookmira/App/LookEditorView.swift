import LookmiraCore
import PhotosUI
import SwiftUI

struct LookEditorView: View {
    @EnvironmentObject private var model: DiaryModel
    @Environment(\.dismiss) private var dismiss

    var existing: MakeupLook?
    var day: Date

    @State private var title: String
    @State private var wornOn: Date
    @State private var tags: Set<StyleTag>
    @State private var products: [UsedProduct]
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var photoName: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewData: Data?
    @State private var removedPhoto = false
    @State private var errorMessage: String?

    init(existing: MakeupLook?, day: Date) {
        self.existing = existing
        self.day = day
        _title = State(initialValue: existing?.title ?? "")
        _wornOn = State(initialValue: existing?.wornOn ?? day)
        _tags = State(initialValue: Set(existing?.styleTags ?? []))
        _products = State(initialValue: existing?.products ?? [])
        _notes = State(initialValue: existing?.notes ?? "")
        _isFavorite = State(initialValue: existing?.isFavorite ?? false)
        _photoName = State(initialValue: existing?.photoFileName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                photoBlock
                TextField("Name this look", text: $title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(DiaryColor.ink)
                DatePicker("Worn on", selection: $wornOn, displayedComponents: .date)
                    .font(DiaryFont.body)
                Text("Style")
                    .font(DiaryFont.section)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(StyleTag.allCases, id: \.self) { tag in
                        TagChip(title: tag.title, selected: tags.contains(tag)) {
                            if tags.contains(tag) {
                                tags.remove(tag)
                            } else {
                                tags.insert(tag)
                            }
                        }
                    }
                }
                Text("Products used")
                    .font(DiaryFont.section)
                ForEach($products) { $product in
                    HStack(spacing: 10) {
                        Menu {
                            ForEach(ProductKind.allCases, id: \.self) { kind in
                                Button(kind.title) { product.kind = kind }
                            }
                        } label: {
                            Text(product.kind.title)
                                .font(DiaryFont.emphasis)
                                .foregroundStyle(DiaryColor.peachDeep)
                                .frame(minWidth: 110, minHeight: 48)
                        }
                        TextField("Product name", text: $product.name)
                            .font(DiaryFont.body)
                        Button {
                            products.removeAll { $0.id == product.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(DiaryColor.inkSoft)
                        }
                        .accessibilityLabel("Remove product")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DiaryColor.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button("Add a product") {
                    products.append(UsedProduct(name: "", kind: .lipstick))
                }
                .font(DiaryFont.emphasis)
                .foregroundStyle(DiaryColor.peachDeep)
                .frame(minHeight: 44)

                Text("Notes")
                    .font(DiaryFont.section)
                TextEditor(text: $notes)
                    .font(DiaryFont.body)
                    .frame(minHeight: 140)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(DiaryColor.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Toggle(isOn: $isFavorite) {
                    Text("Favorite")
                        .font(DiaryFont.emphasis)
                }
                .tint(DiaryColor.peachDeep)

                PrimaryBarButton(title: existing == nil ? "Save look" : "Save changes") {
                    save()
                }
            }
            .padding(20)
        }
        .diaryScreen()
        .navigationTitle(existing == nil ? "New look" : "Edit look")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .font(DiaryFont.emphasis)
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await loadPhoto(item)
            }
        }
        .alert("Lookmira", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var photoBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            LookPhoto(
                url: removedPhoto ? nil : model.photoURL(photoName),
                preview: previewData,
                height: 320
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            HStack(spacing: 16) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text(photoName == nil && previewData == nil ? "Choose a photo" : "Change photo")
                        .font(DiaryFont.emphasis)
                        .foregroundStyle(DiaryColor.peachDeep)
                }
                if previewData != nil || (photoName != nil && !removedPhoto) {
                    Button("Remove photo") {
                        previewData = nil
                        removedPhoto = true
                    }
                    .font(DiaryFont.emphasis)
                    .foregroundStyle(DiaryColor.inkSoft)
                }
            }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.9) else {
            errorMessage = "That photo could not be read."
            return
        }
        previewData = jpeg
        removedPhoto = false
    }

    private func save() {
        do {
            var storedName: String? = removedPhoto ? nil : photoName
            if let previewData {
                storedName = try model.importJPEG(previewData)
            }
            let draft = LookDraft(
                title: title,
                wornOn: wornOn,
                styleTags: StyleTag.allCases.filter { tags.contains($0) },
                products: products,
                notes: notes,
                isFavorite: isFavorite,
                photoFileName: storedName
            )
            if let existing {
                try model.update(existing.id, with: draft)
            } else {
                let created = try model.add(draft)
                model.select(day: created.wornOn)
            }
            dismiss()
        } catch let error as JournalError {
            errorMessage = error.message
        } catch {
            errorMessage = "The look could not be saved."
        }
    }
}
