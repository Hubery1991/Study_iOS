import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: RoutineStore

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max") }
            CalendarScreen()
                .tabItem { Label("Month", systemImage: "calendar") }
            ShelfScreen()
                .tabItem { Label("Shelf", systemImage: "archivebox") }
            JournalScreen()
                .tabItem { Label("Journal", systemImage: "book.closed") }
        }
        .tint(Theme.sageDeep)
        .task { store.refreshReminders() }
    }
}
