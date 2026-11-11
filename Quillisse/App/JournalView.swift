import SwiftUI

struct JournalView: View {
    @ObservedObject var model: ClosetModel
    @State private var monthAnchor = Date()
    @State private var selected: DayStamp?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Masthead(kicker: "Worn", title: "Journal")
                    Text("A look you wore inside the repeat window is ranked lower the next time.")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                    monthHeader
                    weekdayHeader
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                            dayCell(cell)
                        }
                    }
                    if let selected {
                        dayDetail(selected)
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
            }
            .onAppear {
                if selected == nil {
                    selected = model.today
                }
            }
        }
    }

    private var calendar: Calendar { .current }

    private var cells: [DayStamp?] {
        let parts = calendar.dateComponents([.year, .month], from: monthAnchor)
        return MonthGrid.cells(year: parts.year ?? 2026, month: parts.month ?? 1, calendar: calendar)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthTitle)
                .font(Theme.serif(22))
            Spacer()
            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityLabel("Next month")
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthAnchor)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        let start = max(0, calendar.firstWeekday - 1)
        let ordered = Array(symbols[start...] + symbols[..<start])
        return HStack {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                    .font(Theme.sans(10, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }

    @ViewBuilder
    private func dayCell(_ day: DayStamp?) -> some View {
        if let day {
            let wear = model.document.wear(on: day)
            let isSelected = selected == day
            Button {
                selected = day
            } label: {
                VStack(spacing: 4) {
                    Text("\(day.day)")
                        .font(Theme.serif(16))
                        .foregroundStyle(isSelected ? Theme.card : Theme.ink)
                    HStack(spacing: 2) {
                        ForEach(Array(dotPieces(wear).prefix(3))) { piece in
                            Circle().fill(Theme.swatch(piece.primaryColor)).frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.ink : Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(height: 44)
        }
    }

    private func dotPieces(_ wear: WearEntry?) -> [Garment] {
        guard let wear else { return [] }
        return model.document.resolved(wear.pieceIDs)
    }

    private func dayDetail(_ day: DayStamp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detailTitle(day))
                .font(Theme.serif(22))
            if let wear = model.document.wear(on: day) {
                Text(wear.occasion.displayName)
                    .font(Theme.sans(12, weight: .semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.oxblood)
                let pieces = model.document.resolved(wear.pieceIDs)
                if pieces.isEmpty {
                    Text("The pieces from this day have been removed.")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(pieces) { piece in
                                PieceTile(garment: piece, compact: true)
                                    .frame(width: 108)
                            }
                        }
                    }
                }
                Button("Remove this day") {
                    model.clearWear(on: day)
                }
                .font(Theme.sans(13, weight: .semibold))
                .foregroundStyle(Theme.muted)
            } else {
                Text("Nothing logged.")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func detailTitle(_ day: DayStamp) -> String {
        var parts = DateComponents()
        parts.year = day.year
        parts.month = day.month
        parts.day = day.day
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        if let date = calendar.date(from: parts) {
            return formatter.string(from: date)
        }
        return day.key
    }
}
