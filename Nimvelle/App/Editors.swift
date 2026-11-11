import SwiftUI

struct StepEditor: View {
    @EnvironmentObject private var store: RoutineStore
    @Environment(\.dismiss) private var dismiss
    var route: StepEditorRoute

    @State private var title = ""
    @State private var kind: StepKind = .cleanser
    @State private var part: DayPart = .morning
    @State private var productID: UUID?
    @State private var isActive = true
    @State private var existingID: UUID?
    @State private var isSample = false
    @State private var position = 0
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 16) {
                    field("Name") {
                        TextField("Cleanse", text: $title)
                            .textInputAutocapitalization(.words)
                    }
                    field("Kind") {
                        Picker("Kind", selection: $kind) {
                            ForEach(StepKind.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.sageDeep)
                    }
                    field("When") {
                        Picker("When", selection: $part) {
                            ForEach(DayPart.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    field("Product") {
                        Picker("Product", selection: $productID) {
                            Text("None").tag(Optional<UUID>.none)
                            ForEach(store.studio.products) { product in
                                Text(product.name).tag(Optional(product.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.sageDeep)
                    }
                    Toggle("Count this step", isOn: $isActive)
                        .tint(Theme.sage)
                    Text("Turn this off to keep a step without it affecting the day’s completion or the streak.")
                        .font(.footnote)
                        .foregroundColor(Theme.muted)
                    if existingID != nil {
                        Button("Delete step", role: .destructive) {
                            if let existingID {
                                store.deleteStep(id: existingID)
                            }
                            dismiss()
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle(existingID == nil ? "New step" : "Edit step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        switch route {
        case .new(let chosen):
            part = chosen
            title = "Cleanse"
            kind = .cleanser
        case .edit(let id):
            guard let step = store.studio.steps.first(where: { $0.id == id }) else {
                dismiss()
                return
            }
            existingID = step.id
            title = step.title
            kind = step.kind
            part = step.part
            productID = step.productID
            isActive = step.isActive
            isSample = step.isSample
            position = step.position
        }
    }

    private func save() {
        let step = RoutineStep(
            id: existingID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind,
            part: part,
            productID: productID,
            position: position,
            isActive: isActive,
            isSample: isSample
        )
        store.save(step: step)
        dismiss()
    }
}

struct ProductEditor: View {
    @EnvironmentObject private var store: RoutineStore
    @Environment(\.dismiss) private var dismiss
    var route: ProductEditorRoute

    @State private var name = ""
    @State private var brand = ""
    @State private var kind: StepKind = .moisturizer
    @State private var sealed = false
    @State private var opened = Date()
    @State private var paoMonths = 12
    @State private var fill: FillLevel = .full
    @State private var note = ""
    @State private var existingID: UUID?
    @State private var isSample = false
    @State private var loaded = false

    private let paoChoices = [0, 3, 6, 9, 12, 18, 24]

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 16) {
                    labeled("Name") {
                        TextField("Veil Cream", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    labeled("Brand") {
                        TextField("Optional", text: $brand)
                            .textInputAutocapitalization(.words)
                    }
                    labeled("Kind") {
                        Picker("Kind", selection: $kind) {
                            ForEach(StepKind.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.sageDeep)
                    }
                    Toggle("Still sealed", isOn: $sealed)
                        .tint(Theme.sage)
                    if !sealed {
                        DatePicker(
                            "Opened",
                            selection: $opened,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .tint(Theme.sageDeep)
                        Picker("Period after opening", selection: $paoMonths) {
                            ForEach(paoChoices, id: \.self) { months in
                                Text(paoLabel(months)).tag(months)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.sageDeep)
                    }
                    Picker("How much is left", selection: $fill) {
                        ForEach(FillLevel.allCases, id: \.self) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.sageDeep)
                    labeled("Note") {
                        TextField("Texture, scent, where you keep it", text: $note)
                    }
                    Text("The open-jar window counts forward from the day you opened it, by the months printed on the pack. It is a storage guide, not advice about your skin.")
                        .font(.footnote)
                        .foregroundColor(Theme.muted)
                    if existingID != nil {
                        Button("Delete product", role: .destructive) {
                            if let existingID {
                                store.deleteProduct(id: existingID)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existingID == nil ? "New product" : "Edit product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func paoLabel(_ months: Int) -> String {
        if months == 0 { return "Not printed" }
        if months == 1 { return "1 month" }
        return "\(months) months"
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard case .edit(let id) = route else { return }
        guard let product = store.studio.products.first(where: { $0.id == id }) else {
            dismiss()
            return
        }
        existingID = product.id
        name = product.name
        brand = product.brand
        kind = product.kind
        fill = product.fill
        note = product.note
        isSample = product.isSample
        paoMonths = paoChoices.contains(product.paoMonths) ? product.paoMonths : 12
        if let openedOn = product.openedOn {
            sealed = false
            opened = openedOn.date(calendar: store.calendar)
        } else {
            sealed = true
        }
    }

    private func save() {
        let openedOn = sealed ? nil : DayKey.from(opened, calendar: store.calendar)
        let product = Product(
            id: existingID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind,
            openedOn: openedOn,
            paoMonths: sealed ? paoMonths : paoMonths,
            fill: fill,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            isSample: isSample
        )
        store.save(product: product)
        dismiss()
    }
}
