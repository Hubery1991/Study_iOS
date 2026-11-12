import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var store: RoutineStore
    @State private var confirmSample = false

    var body: some View {
        SpaScreen {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nimvelle")
                        .font(Theme.serif(.largeTitle))
                        .foregroundColor(Theme.ink)
                    Text("A calm check-in for the routine you already have. Nothing here is a diagnosis, and nothing is uploaded.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                reminders
                SpaCard {
                    Toggle("Haptics", isOn: Binding(
                        get: { store.studio.hapticsEnabled },
                        set: { store.setHaptics($0) }
                    ))
                    .tint(Theme.sage)
                }
                if store.studio.hasSample {
                    SpaCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sample shelf")
                                .font(Theme.serif(.title3))
                                .foregroundColor(Theme.ink)
                            Text("The first launch includes a sample routine, a few products, check-ins, and notes so the calendar is not empty. Removing it leaves anything you added yourself.")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                            Button("Remove the sample") { confirmSample = true }
                                .font(.body.weight(.semibold))
                                .foregroundColor(Theme.rose)
                        }
                    }
                }
                SpaCard {
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink("Privacy Policy") {
                            LegalPage(title: "Privacy Policy", text: LegalCopy.privacy)
                        }
                        Divider().overlay(Theme.line)
                        NavigationLink("Terms of Use") {
                            LegalPage(title: "Terms of Use", text: LegalCopy.terms)
                        }
                        Divider().overlay(Theme.line)
                        Link("Support", destination: AppLinks.support)
                        Divider().overlay(Theme.line)
                        Link("Website", destination: AppLinks.website)
                    }
                    .font(.body)
                    .foregroundColor(Theme.sageDeep)
                }
                Text("Version \(version)")
                    .font(.footnote)
                    .foregroundColor(Theme.muted)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove the sample shelf?",
            isPresented: $confirmSample,
            titleVisibility: .visible
        ) {
            Button("Remove sample", role: .destructive) { store.removeSample() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sample products, steps, check-ins, and notes are deleted from this device. Your own additions stay.")
        }
        .alert(
            "Notifications",
            isPresented: Binding(
                get: { store.notificationMessage != nil },
                set: { if !$0 { store.notificationMessage = nil } }
            )
        ) {
            Button("Settings") { CaptureAccess.openSettings() }
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.notificationMessage ?? "")
        }
    }

    private var reminders: some View {
        SpaCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Reminders")
                    .font(Theme.serif(.title3))
                    .foregroundColor(Theme.ink)
                Text("Optional, on this device only. Nimvelle asks the system to show a gentle note. There is no push server.")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                reminderRow(
                    title: "Morning",
                    enabled: store.studio.reminders.morningEnabled,
                    hour: store.studio.reminders.morningHour,
                    minute: store.studio.reminders.morningMinute,
                    part: .morning
                )
                Divider().overlay(Theme.line)
                reminderRow(
                    title: "Evening",
                    enabled: store.studio.reminders.eveningEnabled,
                    hour: store.studio.reminders.eveningHour,
                    minute: store.studio.reminders.eveningMinute,
                    part: .evening
                )
            }
        }
    }

    private func reminderRow(title: String, enabled: Bool, hour: Int, minute: Int, part: DayPart) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: Binding(
                get: { enabled },
                set: { store.setReminderEnabled(part: part, enabled: $0) }
            ))
            .tint(Theme.sage)
            DatePicker(
                "Time",
                selection: Binding(
                    get: { clock(hour: hour, minute: minute) },
                    set: { date in
                        let parts = store.calendar.dateComponents([.hour, .minute], from: date)
                        store.setReminderClock(part: part, hour: parts.hour ?? hour, minute: parts.minute ?? minute)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .tint(Theme.sageDeep)
        }
    }

    private func clock(hour: Int, minute: Int) -> Date {
        var parts = store.calendar.dateComponents([.year, .month, .day], from: Date())
        parts.hour = hour
        parts.minute = minute
        return store.calendar.date(from: parts) ?? Date()
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}

struct LegalPage: View {
    var title: String
    var text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .foregroundColor(Theme.ink)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(20)
                .padding(.bottom, 24)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
