import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var store: RoutineStore
    @State private var year = 2026
    @State private var month = 1
    @State private var selected = DayKey(year: 2026, month: 1, day: 1)
    @State private var ready = false

    var body: some View {
        NavigationStack {
            SpaScreen {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    weekdayRow
                    grid
                    dayDetail
                }
            }
            .navigationTitle("Month")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !ready else { return }
                year = store.today.year
                month = store.today.month
                selected = store.today
                ready = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    shift(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(DayText.month(year, month, calendar: store.calendar))
                    .font(Theme.serif(.title2))
                    .foregroundColor(Theme.ink)
                Spacer()
                Button {
                    shift(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Next month")
            }
            .foregroundColor(Theme.sageDeep)
            Text("\(DayText.streak(streak)) · longest \(longest)")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
        }
    }

    private var weekdayRow: some View {
        let labels = MonthGrid.weekdayLabels(calendar: store.calendar)
        return HStack {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(String(label.prefix(1)))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let weeks = MonthGrid.weeks(year: year, month: month, calendar: store.calendar)
        return SpaCard {
            VStack(spacing: 2) {
                ForEach(weeks.indices, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(weeks[row].indices, id: \.self) { column in
                            let cell = weeks[row][column]
                            Button {
                                selected = cell.day
                            } label: {
                                MonthDot(
                                    mark: RoutineMath.mark(on: cell.day, steps: store.studio.steps, checks: store.studio.checks),
                                    isToday: cell.day == store.today,
                                    inMonth: cell.inMonth,
                                    day: cell.day.day
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibility(for: cell))
                        }
                    }
                }
            }
        }
    }

    private var dayDetail: some View {
        let morning = RoutineMath.checkedCount(on: selected, steps: store.studio.steps, checks: store.studio.checks, part: .morning)
        let evening = RoutineMath.checkedCount(on: selected, steps: store.studio.steps, checks: store.studio.checks, part: .evening)
        let future = selected > store.today
        return VStack(alignment: .leading, spacing: 12) {
            Text(DayText.full(selected, calendar: store.calendar))
                .font(Theme.serif(.title3))
                .foregroundColor(Theme.ink)
            Text(summary(morning: morning, evening: evening, future: future))
                .font(.subheadline)
                .foregroundColor(Theme.muted)
            if future {
                Text("You can look ahead. Check-ins start when the day arrives.")
                    .font(.footnote)
                    .foregroundColor(Theme.muted)
            } else {
                ForEach(DayPart.allCases, id: \.self) { part in
                    let rows = RoutineMath.activeSteps(store.studio.steps, part: part)
                    if !rows.isEmpty {
                        Text(part.title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.sageDeep)
                            .padding(.top, 4)
                        ForEach(rows) { step in
                            Button {
                                store.toggle(day: selected, stepID: step.id)
                            } label: {
                                StepRow(
                                    title: step.title,
                                    detail: store.studio.product(id: step.productID)?.name ?? "No product linked",
                                    detailColor: Theme.muted,
                                    checked: store.studio.isChecked(day: selected, stepID: step.id),
                                    enabled: true
                                )
                            }
                            .buttonStyle(.plain)
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

    private var longest: Int {
        RoutineMath.longestStreak(steps: store.studio.steps, checks: store.studio.checks, calendar: store.calendar)
    }

    private func shift(_ delta: Int) {
        let first = DayKey(year: year, month: month, day: 1)
        let next = first.adding(months: delta, calendar: store.calendar)
        year = next.year
        month = next.month
        if selected.year != year || selected.month != month {
            if store.today.year == year && store.today.month == month {
                selected = store.today
            } else {
                selected = DayKey(year: year, month: month, day: 1)
            }
        }
    }

    private func summary(morning: (done: Int, total: Int), evening: (done: Int, total: Int), future: Bool) -> String {
        if future { return "Ahead" }
        return "Morning \(morning.done) of \(morning.total) · Evening \(evening.done) of \(evening.total)"
    }

    private func accessibility(for cell: MonthCell) -> String {
        let mark = RoutineMath.mark(on: cell.day, steps: store.studio.steps, checks: store.studio.checks)
        let state: String
        switch mark {
        case .complete: state = "complete"
        case .partial: state = "partial"
        case .none: state = "open"
        }
        return "\(DayText.full(cell.day, calendar: store.calendar)), \(state)"
    }
}
