import SwiftUI
import VermessaCore

struct WornScreen: View {
    @EnvironmentObject private var drawer: DrawerModel
    @State private var showChooser = false

    private var todayLipsticks: [Lipstick] {
        drawer.library.wornLipsticks(on: drawer.today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PageColumn {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Worn")
                            .font(VermessaFont.display(40))
                            .foregroundStyle(VermessaColor.ink)
                        Text("A short log of lip color. Not a full makeup diary.")
                            .font(VermessaFont.body(18))
                            .foregroundStyle(VermessaColor.mist)
                        todayCard
                        WideButton(title: "Choose a lipstick for today", systemImage: "plus") {
                            showChooser = true
                        }
                        let history = drawer.library.history().filter { $0.day != drawer.today }
                        if history.isEmpty && todayLipsticks.isEmpty {
                            Text("Nothing has been logged yet.")
                                .font(VermessaFont.body(18))
                                .foregroundStyle(VermessaColor.mist)
                        } else if !history.isEmpty {
                            Text("Earlier")
                                .font(VermessaFont.display(26))
                                .foregroundStyle(VermessaColor.ink)
                            ForEach(history, id: \.day) { entry in
                                dayBlock(entry)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(VermessaColor.paper)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showChooser) {
                WornChooser()
            }
            .navigationDestination(for: UUID.self) { id in
                ShadeDetailView(lipstickID: id)
            }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DayText.title(for: drawer.today, today: drawer.today))
                .font(VermessaFont.display(28))
                .foregroundStyle(VermessaColor.ink)
            if todayLipsticks.isEmpty {
                Text("Nothing logged for today.")
                    .font(VermessaFont.body(18))
                    .foregroundStyle(VermessaColor.mist)
            } else {
                ForEach(todayLipsticks) { lipstick in
                    wornRow(lipstick, day: drawer.today)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func dayBlock(_ entry: WearDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(DayText.title(for: entry.day, today: drawer.today))
                .font(VermessaFont.display(24))
                .foregroundStyle(VermessaColor.ink)
            ForEach(entry.lipsticks) { lipstick in
                wornRow(lipstick, day: entry.day)
            }
        }
    }

    private func wornRow(_ lipstick: Lipstick, day: CalendarDay) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: lipstick.id) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(lipstick.shade.swiftUIColor)
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lipstick.name)
                            .font(VermessaFont.label(18))
                            .foregroundStyle(VermessaColor.ink)
                        Text(lipstick.finish.title)
                            .font(VermessaFont.body(16))
                            .foregroundStyle(VermessaColor.mist)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button("Remove") {
                drawer.clearWorn(id: lipstick.id, on: day)
            }
            .font(VermessaFont.label(16))
            .foregroundStyle(VermessaColor.merlot)
        }
    }
}

struct WornChooser: View {
    @EnvironmentObject private var drawer: DrawerModel
    @Environment(\.dismiss) private var dismiss

    private var owned: [Lipstick] {
        drawer.owned(matching: WardrobeFilter())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Which lip color is on today?")
                        .font(VermessaFont.body(18))
                        .foregroundStyle(VermessaColor.mist)
                    ForEach(owned) { lipstick in
                        Button {
                            drawer.logWorn(id: lipstick.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(lipstick.shade.swiftUIColor)
                                    .frame(width: 48, height: 48)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lipstick.name)
                                        .font(VermessaFont.display(20))
                                    Text(drawer.isWornToday(lipstick.id) ? "Already logged today" : lipstick.finish.title)
                                        .font(VermessaFont.body(16))
                                        .foregroundStyle(VermessaColor.mist)
                                }
                                Spacer()
                            }
                            .foregroundStyle(VermessaColor.ink)
                            .padding(12)
                            .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(VermessaColor.paper)
            .navigationTitle("Log today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(VermessaFont.label(18))
                }
            }
        }
    }
}
