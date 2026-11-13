import LookmiraCore
import SwiftUI

struct DiaryScreen: View {
    @EnvironmentObject private var model: DiaryModel
    @State private var editor: EditorRoute?

    var body: some View {
        GeometryReader { geo in
            Group {
                if geo.size.width >= 840 {
                    HStack(alignment: .top, spacing: 8) {
                        ScrollView { calendarBlock.padding(24) }
                            .frame(maxWidth: 560)
                        ScrollView { dayBlock.padding(24) }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            calendarBlock
                            dayBlock
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                    }
                }
            }
        }
        .diaryScreen()
        .navigationTitle("Diary")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editor = EditorRoute(existing: nil, day: model.selectedDay)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                }
                .accessibilityLabel("Add a look")
            }
        }
        .sheet(item: $editor) { route in
            NavigationStack {
                LookEditorView(existing: route.existing, day: route.day)
            }
        }
    }

    private var calendarBlock: some View {
        let page = DiaryDates.page(containing: model.visibleMonth, looks: model.document.journal.looks, calendar: model.calendar)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                monthButton("chevron.left", "Previous month") { model.shiftMonth(by: -1) }
                Spacer()
                Text(page.title)
                    .font(DiaryFont.section)
                    .foregroundStyle(DiaryColor.ink)
                Spacer()
                monthButton("chevron.right", "Next month") { model.shiftMonth(by: 1) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(page.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DiaryColor.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                ForEach(Array(page.cells.enumerated()), id: \.offset) { _, cell in
                    dayCell(cell)
                }
            }
        }
    }

    private var dayBlock: some View {
        let looks = model.document.journal.looks(on: model.selectedDay, calendar: model.calendar)
        return VStack(alignment: .leading, spacing: 16) {
            Text(DiaryDates.dayTitle(model.selectedDay, calendar: model.calendar))
                .font(DiaryFont.section)
                .foregroundStyle(DiaryColor.ink)
            if looks.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("No look on this day yet.")
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.inkSoft)
                    PrimaryBarButton(title: "Add a look") {
                        editor = EditorRoute(existing: nil, day: model.selectedDay)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DiaryColor.paper)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ForEach(looks) { look in
                    NavigationLink {
                        LookDetailView(lookID: look.id)
                    } label: {
                        LookCard(look: look)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayCell(_ cell: MonthCell) -> some View {
        let selected = model.calendar.isDate(cell.date, inSameDayAs: model.selectedDay)
        return Button {
            model.select(day: cell.date)
        } label: {
            VStack(spacing: 4) {
                Text("\(cell.dayNumber)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : (cell.isInMonth ? DiaryColor.ink : DiaryColor.inkSoft.opacity(0.45)))
                    .frame(width: 40, height: 40)
                    .background(selected ? DiaryColor.peachDeep : Color.clear)
                    .clipShape(Circle())
                Circle()
                    .fill(cell.lookCount > 0 ? DiaryColor.peach : Color.clear)
                    .frame(width: 7, height: 7)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cell.dayNumber)")
    }

    private func monthButton(_ system: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }
}

struct EditorRoute: Identifiable {
    let id = UUID()
    var existing: MakeupLook?
    var day: Date
}
