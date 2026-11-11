import SwiftUI

struct AtelierView: View {
    @ObservedObject var model: ClosetModel
    @State private var slots = LookSlots.empty
    @State private var name = ""
    @State private var notice = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Masthead(kicker: "By hand", title: "Atelier")
                    Text("A dress stands in for a top and a bottom. Shoes can wait.")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                    slotRow("Top", category: .top, selected: slots.top) { id in
                        slots.top = slots.top == id ? nil : id
                        if id != nil { slots.dress = nil }
                    }
                    slotRow("Bottom", category: .bottom, selected: slots.bottom) { id in
                        slots.bottom = slots.bottom == id ? nil : id
                        if id != nil { slots.dress = nil }
                    }
                    slotRow("Dress", category: .dress, selected: slots.dress) { id in
                        slots.dress = slots.dress == id ? nil : id
                        if id != nil {
                            slots.top = nil
                            slots.bottom = nil
                        }
                    }
                    slotRow("Outerwear", category: .outerwear, selected: slots.outerwear) { id in
                        slots.outerwear = slots.outerwear == id ? nil : id
                    }
                    slotRow("Shoes", category: .shoes, selected: slots.shoes) { id in
                        slots.shoes = slots.shoes == id ? nil : id
                    }
                    slotRow("Accessory", category: .accessory, selected: slots.accessory) { id in
                        slots.accessory = slots.accessory == id ? nil : id
                    }
                    ForEach(issues, id: \.message) { issue in
                        Text(issue.message)
                            .font(Theme.serif(15))
                            .foregroundStyle(issue.isBlocking ? Theme.oxblood : Theme.muted)
                    }
                    TextField("Name this look", text: $name)
                        .font(Theme.serif(18))
                        .padding(12)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    EditorialButton(title: "Save look") { save(favorite: true) }
                        .disabled(blocking)
                        .opacity(blocking ? 0.4 : 1)
                    EditorialButton(title: "Wear this today", filled: false) { wearNow() }
                        .disabled(blocking)
                        .opacity(blocking ? 0.4 : 1)
                    if !notice.isEmpty {
                        Text(notice)
                            .font(Theme.sans(13, weight: .medium))
                            .foregroundStyle(Theme.muted)
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
                    Button("Clear") {
                        slots = .empty
                        name = ""
                        notice = ""
                    }
                    .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var pieces: [Garment] {
        OutfitEngine.pieces(in: slots, garments: model.document.garments)
    }

    private var issues: [LookIssue] {
        OutfitEngine.issues(for: slots)
    }

    private var blocking: Bool {
        issues.contains(where: \.isBlocking)
    }

    private func slotRow(
        _ title: String,
        category: GarmentCategory,
        selected: UUID?,
        onPick: @escaping (UUID) -> Void
    ) -> some View {
        let options = model.document.garments.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(Theme.sans(12, weight: .semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text(selected.flatMap { model.document.garment($0)?.name } ?? "None")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            if options.isEmpty {
                Text("Nothing in this category yet.")
                    .font(Theme.serif(14))
                    .foregroundStyle(Theme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(options) { garment in
                            Button {
                                onPick(garment.id)
                            } label: {
                                VStack(spacing: 6) {
                                    GarmentPhoto(token: garment.imageToken)
                                        .frame(width: 72, height: 84)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(selected == garment.id ? Theme.oxblood : Theme.line, lineWidth: selected == garment.id ? 2 : 1)
                                        )
                                    Text(garment.name)
                                        .font(Theme.sans(11, weight: .medium))
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                        .frame(width: 76)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            Rule()
        }
    }

    private func save(favorite: Bool) {
        guard !blocking else { return }
        model.saveLook(
            name: name,
            pieces: pieces,
            occasion: model.occasion,
            handbuilt: true,
            favorite: favorite
        )
        notice = "Saved on this device."
    }

    private func wearNow() {
        guard !blocking else { return }
        model.wear(pieces: pieces, occasion: model.occasion)
        notice = "Logged for today."
    }
}
