import SwiftUI
import VermessaCore

struct WardrobeScreen: View {
    @EnvironmentObject private var drawer: DrawerModel
    @State private var filter = WardrobeFilter()
    @State private var showFilters = false
    @State private var showEditor = false

    private var lipsticks: [Lipstick] {
        drawer.owned(matching: filter)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PageColumn {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        searchField
                        if filter.isNarrowed {
                            activeFilters
                        }
                        if filter.isNarrowed {
                            Text(lipsticks.isEmpty ? "No lipsticks match these filters." : "\(lipsticks.count) matching lipsticks")
                                .font(VermessaFont.body(17))
                                .foregroundStyle(VermessaColor.mist)
                        }
                        if lipsticks.isEmpty && !filter.isNarrowed {
                            emptyDrawer
                        } else {
                            grid
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .background(VermessaColor.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("About Vermessa")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: filter.isNarrowed ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Filter the drawer")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Add a lipstick")
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filter: $filter)
            }
            .sheet(isPresented: $showEditor) {
                ShadeEditor(mode: .create(.owned))
            }
            .navigationDestination(for: UUID.self) { id in
                ShadeDetailView(lipstickID: id)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            VermessaColor.merlotDeep
            Image("PortraitMerlot")
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("The drawer")
                    .font(VermessaFont.display(40))
                Text("\(drawer.owned(matching: WardrobeFilter()).count) lipsticks at home. Still photographs only — no camera.")
                    .font(VermessaFont.body(18))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The drawer. Lipsticks you already own.")
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
            TextField("Search name, brand, or family", text: $filter.text)
                .font(VermessaFont.body(18))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(VermessaColor.ink)
    }

    private var activeFilters: some View {
        let labels = filter.finishes.map(\.title)
            + filter.undertones.map(\.title)
            + filter.families.map(\.title)
            + filter.occasions.map(\.title)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(VermessaFont.label(16))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(VermessaColor.merlot, in: Capsule())
                }
                Button("Clear") {
                    let text = filter.text
                    filter = WardrobeFilter(text: text)
                }
                .font(VermessaFont.label(16))
                .foregroundStyle(VermessaColor.merlot)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 168), spacing: 14)], spacing: 14) {
            ForEach(lipsticks) { lipstick in
                NavigationLink(value: lipstick.id) {
                    LipstickCard(lipstick: lipstick)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The drawer is empty")
                .font(VermessaFont.display(28))
            Text("Add the lipsticks you already own. Vermessa will suggest from this list, not from a store catalog.")
                .font(VermessaFont.body(18))
                .foregroundStyle(VermessaColor.mist)
        }
    }
}

struct FilterSheet: View {
    @Binding var filter: WardrobeFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    chipSection("Finish", Finish.allCases.map { finish in
                        (finish.title, filter.finishes.contains(finish), { toggle(&filter.finishes, finish) })
                    })
                    chipSection("Undertone", Undertone.allCases.map { tone in
                        (tone.title, filter.undertones.contains(tone), { toggle(&filter.undertones, tone) })
                    })
                    chipSection("Color family", ColorFamily.allCases.map { family in
                        (family.title, filter.families.contains(family), { toggle(&filter.families, family) })
                    })
                    chipSection("Occasion", Occasion.allCases.map { occasion in
                        (occasion.title, filter.occasions.contains(occasion), { toggle(&filter.occasions, occasion) })
                    })
                }
                .padding(20)
            }
            .background(VermessaColor.paper)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        let text = filter.text
                        filter = WardrobeFilter(text: text)
                    }
                    .font(VermessaFont.label(18))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(VermessaFont.label(18))
                }
            }
        }
    }

    private func chipSection(_ title: String, _ chips: [(String, Bool, () -> Void)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(VermessaFont.display(24))
                .foregroundStyle(VermessaColor.ink)
            FlowChips(titles: chips)
        }
    }

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ value: T) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}
