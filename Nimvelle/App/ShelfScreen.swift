import SwiftUI

struct ShelfScreen: View {
    @EnvironmentObject private var store: RoutineStore
    @State private var editor: ProductEditorRoute?

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A jar’s period after opening is the maker’s guide for how long to keep it once the seal is broken. It is not a medical date.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let banner = store.studio.attentionSummary(today: store.today, calendar: store.calendar) {
                        Text(banner)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.ink)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.blush.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    if orderedProducts.isEmpty {
                        SpaCard {
                            EmptyNote(
                                title: "Nothing on the shelf",
                                message: "Add a cleanser, a cream, or a sunscreen. You can note when you opened it and how much is left."
                            )
                        }
                    } else {
                        ForEach(orderedProducts) { product in
                            Button {
                                editor = .edit(product.id)
                            } label: {
                                productCard(product)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") { editor = .edit(product.id) }
                                Button("Delete", role: .destructive) { store.deleteProduct(id: product.id) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shelf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editor = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a product")
                }
            }
            .sheet(item: $editor) { route in
                ProductEditor(route: route)
                    .environmentObject(store)
            }
        }
    }

    private var orderedProducts: [Product] {
        store.studio.products.enumerated().sorted { lhs, rhs in
            let left = rank(lhs.element)
            let right = rank(rhs.element)
            if left != right { return left < right }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func rank(_ product: Product) -> Int {
        switch product.freshness(today: store.today, calendar: store.calendar) {
        case .past: return 0
        case .soon: return 1
        default: return 2
        }
    }

    private func productCard(_ product: Product) -> some View {
        let freshness = product.freshness(today: store.today, calendar: store.calendar)
        return SpaCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.name)
                            .font(Theme.serif(.title3))
                            .foregroundColor(Theme.ink)
                        Text(product.brand.isEmpty ? product.kind.title : "\(product.brand) · \(product.kind.title)")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(product.fill.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.sageDeep)
                }
                ProgressBar(fraction: product.fill.fraction, tint: Theme.clay)
                Text(openedLine(product))
                    .font(.footnote)
                    .foregroundColor(Theme.muted)
                Text(product.statusLine(today: store.today, calendar: store.calendar))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FreshnessColor.color(freshness))
            }
        }
    }

    private func openedLine(_ product: Product) -> String {
        guard let opened = product.openedOn else { return "Still sealed" }
        let date = DayText.medium(opened, calendar: store.calendar)
        if product.paoMonths <= 0 { return "Opened \(date)" }
        let months = product.paoMonths == 1 ? "1 month" : "\(product.paoMonths) months"
        return "Opened \(date) · \(months)"
    }
}

enum ProductEditorRoute: Identifiable {
    case new
    case edit(UUID)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let id): return id.uuidString
        }
    }
}
