import LookmiraCore
import SwiftUI

struct LookDetailView: View {
    @EnvironmentObject private var model: DiaryModel
    var lookID: UUID
    @State private var editor: EditorRoute?
    @State private var recreate = false
    @State private var confirmDelete = false
    @Environment(\.dismiss) private var dismiss

    private var look: MakeupLook? {
        model.document.journal.look(lookID)
    }

    var body: some View {
        Group {
            if let look {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        LookPhoto(url: model.photoURL(look.photoFileName), height: 460)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        Text(look.title)
                            .font(DiaryFont.display)
                            .foregroundStyle(DiaryColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(DiaryDates.dayTitle(look.wornOn, calendar: model.calendar))
                            .font(DiaryFont.body)
                            .foregroundStyle(DiaryColor.inkSoft)
                        HStack(spacing: 8) {
                            ForEach(look.styleTags, id: \.self) { tag in
                                Text(tag.title)
                                    .font(DiaryFont.emphasis)
                                    .foregroundStyle(DiaryColor.peachDeep)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(DiaryColor.blush)
                                    .clipShape(Capsule())
                            }
                        }
                        Button {
                            try? model.setFavorite(look.id, !look.isFavorite)
                        } label: {
                            Label(look.isFavorite ? "Favorite" : "Mark as favorite", systemImage: look.isFavorite ? "heart.fill" : "heart")
                                .font(DiaryFont.emphasis)
                                .foregroundStyle(DiaryColor.peachDeep)
                        }
                        .buttonStyle(.plain)

                        Text("Products used")
                            .font(DiaryFont.section)
                            .padding(.top, 8)
                        if look.products.isEmpty {
                            Text("No products listed.")
                                .font(DiaryFont.body)
                                .foregroundStyle(DiaryColor.inkSoft)
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(look.products) { product in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.kind.title)
                                            .font(DiaryFont.body)
                                            .foregroundStyle(DiaryColor.inkSoft)
                                        Text(product.name)
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(DiaryColor.ink)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(DiaryColor.paper)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }

                        if !look.notes.isEmpty {
                            Text("Notes")
                                .font(DiaryFont.section)
                                .padding(.top, 8)
                            Text(look.notes)
                                .font(DiaryFont.body)
                                .foregroundStyle(DiaryColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PrimaryBarButton(title: "Recreate this look") { recreate = true }
                        SecondaryBarButton(title: "Edit") {
                            editor = EditorRoute(existing: look, day: look.wornOn)
                        }
                        Button("Delete this look") { confirmDelete = true }
                            .font(DiaryFont.emphasis)
                            .foregroundStyle(DiaryColor.peachDeep)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            } else {
                Text("That look is no longer in the diary.")
                    .font(DiaryFont.body)
                    .padding(24)
            }
        }
        .diaryScreen()
        .navigationTitle("Look")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editor) { route in
            NavigationStack {
                LookEditorView(existing: route.existing, day: route.day)
            }
        }
        .sheet(isPresented: $recreate) {
            if let look {
                RecreateSheet(look: look)
            }
        }
        .confirmationDialog("Delete this look?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                try? model.delete(lookID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The entry is removed from this iPhone.")
        }
    }
}
