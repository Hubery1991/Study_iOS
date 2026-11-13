import SwiftUI
import VermessaCore

struct ShadeDetailView: View {
    @EnvironmentObject private var drawer: DrawerModel
    let lipstickID: UUID
    @State private var showEditor = false
    @State private var showDelete = false

    private var lipstick: Lipstick? {
        drawer.library.lipstick(id: lipstickID)
    }

    var body: some View {
        Group {
            if let lipstick {
                content(lipstick)
            } else {
                Text("This lipstick has been removed.")
                    .font(VermessaFont.body(20))
                    .foregroundStyle(VermessaColor.ink)
                    .padding(24)
            }
        }
        .background(VermessaColor.paper)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ lipstick: Lipstick) -> some View {
        ScrollView {
            PageColumn {
                VStack(alignment: .leading, spacing: 16) {
                    ShadeSwatch(
                        shade: lipstick.shade,
                        height: 210,
                        title: lipstick.name,
                        subtitle: lipstick.brand
                    )
                    if let image = drawer.photos.image(named: lipstick.swatchFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .accessibilityLabel("Photo of \(lipstick.name)")
                    }
                    if let portrait = StudioPortrait.assetName(for: lipstick.colorFamily) {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                VermessaColor.merlotDeep
                                Image(portrait)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(height: 340)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            Text("Still shade card. Vermessa never opens the camera.")
                                .font(VermessaFont.body(16))
                                .foregroundStyle(VermessaColor.mist)
                        }
                    }
                    fact("Finish", lipstick.finish.title)
                    fact("Undertone", lipstick.undertone.title)
                    fact("Color family", lipstick.colorFamily.title)
                    fact("Shade", "#\(lipstick.shade.hex)")
                    fact(
                        "Occasions",
                        lipstick.occasions.isEmpty ? "Not set" : lipstick.occasions.map(\.title).joined(separator: ", ")
                    )
                    if lipstick.ownership == .owned {
                        WideButton(
                            title: drawer.isWornToday(lipstick.id) ? "Worn today" : "Log as worn today",
                            systemImage: drawer.isWornToday(lipstick.id) ? "checkmark.circle.fill" : "calendar.badge.plus"
                        ) {
                            if drawer.isWornToday(lipstick.id) {
                                drawer.clearWorn(id: lipstick.id, on: drawer.today)
                            } else {
                                drawer.logWorn(id: lipstick.id)
                            }
                        }
                        WideButton(title: "Move to wishlist", systemImage: "heart", filled: false) {
                            drawer.setOwnership(id: lipstick.id, to: .wishlist)
                        }
                    } else {
                        WideButton(title: "Move into the drawer", systemImage: "square.grid.2x2") {
                            drawer.setOwnership(id: lipstick.id, to: .owned)
                        }
                    }
                    WideButton(title: "Edit", systemImage: "pencil", filled: false) {
                        showEditor = true
                    }
                    Button(role: .destructive) {
                        showDelete = true
                    } label: {
                        Text("Delete lipstick")
                            .font(VermessaFont.label(18))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showEditor) {
            ShadeEditor(mode: .edit(lipstick))
        }
        .confirmationDialog("Delete \(lipstick.name)?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                drawer.delete(id: lipstick.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The shade and its wear notes leave this device. This cannot be undone.")
        }
    }

    private func fact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(VermessaFont.label(16))
                .foregroundStyle(VermessaColor.mist)
            Text(value)
                .font(VermessaFont.body(20))
                .foregroundStyle(VermessaColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
