import SwiftUI

struct TodayScreen: View {
    @EnvironmentObject private var store: RoutineStore
    @State private var part: DayPart = .morning
    @State private var chosePart = false
    @State private var editor: StepEditorRoute?

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    Picker("Routine", selection: $part) {
                        ForEach(DayPart.allCases, id: \.self) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: part) { _ in chosePart = true }
                    progress
                    steps
                    if canMarkRest {
                        Button("Mark the rest done") {
                            store.markRemaining(day: store.today, part: part)
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.sageDeep)
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Image(systemName: "leaf")
                    }
                    .accessibilityLabel("About")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editor = .new(part)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a step")
                }
            }
            .sheet(item: $editor) { route in
                StepEditor(route: route)
                    .environmentObject(store)
            }
            .onAppear {
                guard !chosePart else { return }
                let hour = store.calendar.component(.hour, from: Date())
                part = hour >= 17 ? .evening : .morning
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DayText.full(store.today, calendar: store.calendar))
                .font(.subheadline)
                .foregroundColor(Theme.muted)
            Text(DayText.greeting(at: Date(), calendar: store.calendar))
                .font(Theme.serif(.largeTitle))
                .foregroundColor(Theme.ink)
            Text(DayText.streak(streak))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.sageDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.blush.opacity(0.55))
                .clipShape(Capsule())
        }
    }

    private var progress: some View {
        let counts = RoutineMath.checkedCount(
            on: store.today,
            steps: store.studio.steps,
            checks: store.studio.checks,
            part: part
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text(counts.total == 0 ? "No \(part.title.lowercased()) steps yet" : "\(counts.done) of \(counts.total)")
                .font(Theme.serif(.title2))
                .foregroundColor(Theme.ink)
            if counts.total > 0 {
                ProgressBar(fraction: Double(counts.done) / Double(counts.total))
            }
        }
    }

    @ViewBuilder
    private var steps: some View {
        let rows = RoutineMath.activeSteps(store.studio.steps, part: part)
        if rows.isEmpty {
            SpaCard {
                EmptyNote(
                    title: "A quiet \(part.title.lowercased())",
                    message: "Add a cleanser, a serum, or whatever you actually use. Inactive steps stay off the streak."
                )
            }
        } else {
            SpaCard {
                VStack(spacing: 0) {
                    ForEach(rows) { step in
                        Button {
                            store.toggle(day: store.today, stepID: step.id)
                        } label: {
                            StepRow(
                                title: step.title,
                                detail: detail(for: step),
                                detailColor: detailColor(for: step),
                                checked: store.studio.isChecked(day: store.today, stepID: step.id),
                                enabled: true
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit step") { editor = .edit(step.id) }
                            Button("Delete step", role: .destructive) { store.deleteStep(id: step.id) }
                        }
                        if step.id != rows.last?.id {
                            Divider().overlay(Theme.line)
                        }
                    }
                }
            }
        }
    }

    private var streak: Int {
        RoutineMath.currentStreak(
            today: store.today,
            steps: store.studio.steps,
            checks: store.studio.checks,
            calendar: store.calendar
        )
    }

    private var canMarkRest: Bool {
        let counts = RoutineMath.checkedCount(
            on: store.today,
            steps: store.studio.steps,
            checks: store.studio.checks,
            part: part
        )
        return counts.total > 0 && counts.done < counts.total
    }

    private func detail(for step: RoutineStep) -> String {
        guard let product = store.studio.product(id: step.productID) else {
            return "No product linked"
        }
        let freshness = product.freshness(today: store.today, calendar: store.calendar)
        switch freshness {
        case .soon, .past:
            return "\(product.name) · \(product.statusLine(today: store.today, calendar: store.calendar))"
        default:
            return product.name
        }
    }

    private func detailColor(for step: RoutineStep) -> Color {
        guard let product = store.studio.product(id: step.productID) else { return Theme.muted }
        switch product.freshness(today: store.today, calendar: store.calendar) {
        case .soon, .past:
            return FreshnessColor.color(product.freshness(today: store.today, calendar: store.calendar))
        default:
            return Theme.muted
        }
    }
}

enum StepEditorRoute: Identifiable {
    case new(DayPart)
    case edit(UUID)

    var id: String {
        switch self {
        case .new(let part): return "new-\(part.rawValue)"
        case .edit(let id): return id.uuidString
        }
    }
}
