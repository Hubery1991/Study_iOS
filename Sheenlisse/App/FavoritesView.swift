import SwiftUI

struct FavoritesView: View {
    @ObservedObject var model: MirrorModel
    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: SavedLook?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            Group {
                if model.document.favorites.isEmpty {
                    VStack(spacing: 10) {
                        Text("No saved looks yet")
                            .font(Theme.serif(28, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Build one in the mirror, then tap Save. Favorites stay on this device.")
                            .font(Theme.sans(16))
                            .foregroundStyle(Theme.plum.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(model.document.favorites) { saved in
                            Button {
                                model.applyFavorite(saved)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(saved.name)
                                            .font(Theme.serif(20, weight: .semibold))
                                            .foregroundStyle(Theme.ink)
                                        Spacer()
                                        Text(saved.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(Theme.sans(12))
                                            .foregroundStyle(Theme.plum.opacity(0.6))
                                    }
                                    HStack(spacing: 6) {
                                        ForEach(MakeupRegion.allCases, id: \.self) { region in
                                            let setting = saved.recipe.setting(for: region)
                                            Circle()
                                                .fill((ShadeCatalog.shade(id: setting.shadeID)?.color.swiftUI) ?? Theme.line)
                                                .frame(width: 14, height: 14)
                                                .opacity(setting.enabled ? 1 : 0.25)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .contextMenu {
                                Button("Rename") {
                                    renameTarget = saved
                                    renameText = saved.name
                                }
                            }
                        }
                        .onDelete { model.deleteFavorites(at: $0) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.ivory)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Rename look", isPresented: renamePresented) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let renameTarget {
                    model.renameFavorite(id: renameTarget.id, to: renameText)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }
}
