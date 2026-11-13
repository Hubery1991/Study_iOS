import LookmiraCore
import SwiftUI

struct RecreateScreen: View {
    @EnvironmentObject private var model: DiaryModel
    @State private var pending: MakeupLook?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("Favorites", looks: model.document.journal.favorites(), empty: "No favorites yet. Open a look and mark it.")
                section("Recents", looks: model.document.journal.recents(limit: 8), empty: "Looks you wear will show up here.")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .diaryScreen()
        .navigationTitle("Recreate")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $pending) { look in
            RecreateSheet(look: look)
        }
    }

    private func section(_ title: String, looks: [MakeupLook], empty: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(DiaryFont.section)
                .foregroundStyle(DiaryColor.ink)
            if looks.isEmpty {
                Text(empty)
                    .font(DiaryFont.body)
                    .foregroundStyle(DiaryColor.inkSoft)
            } else {
                ForEach(looks) { look in
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink {
                            LookDetailView(lookID: look.id)
                        } label: {
                            LookCard(look: look)
                        }
                        .buttonStyle(.plain)
                        PrimaryBarButton(title: "Recreate this look") {
                            pending = look
                        }
                    }
                }
            }
        }
    }
}

struct RecreateSheet: View {
    @EnvironmentObject private var model: DiaryModel
    @Environment(\.dismiss) private var dismiss
    var look: MakeupLook
    @State private var day = Date()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(look.title)
                    .font(DiaryFont.section)
                    .foregroundStyle(DiaryColor.ink)
                Text("This writes the same products, tags, notes, and photo onto another day. The original stays where it is.")
                    .font(DiaryFont.body)
                    .foregroundStyle(DiaryColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                DatePicker("Wear it on", selection: $day, displayedComponents: .date)
                    .font(DiaryFont.body)
                Spacer()
                PrimaryBarButton(title: "Log this look again") {
                    do {
                        _ = try model.recreate(look.id, on: day)
                        dismiss()
                    } catch let error as JournalError {
                        errorMessage = error.message
                    } catch {
                        errorMessage = "The look could not be logged again."
                    }
                }
            }
            .padding(20)
            .diaryScreen()
            .navigationTitle("Recreate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(DiaryFont.emphasis)
                }
            }
            .alert("Lookmira", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}
