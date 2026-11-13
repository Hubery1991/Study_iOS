import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var model: DiaryModel
    @State private var legal: LegalPage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("A diary of finished looks. Photos, products, and notes stay on this iPhone.")
                    .font(DiaryFont.body)
                    .foregroundStyle(DiaryColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: Binding(
                        get: { model.document.reminder.isEnabled },
                        set: { model.setReminderEnabled($0) }
                    )) {
                        Text("Remind me to log today's look")
                            .font(DiaryFont.emphasis)
                            .foregroundStyle(DiaryColor.ink)
                    }
                    .tint(DiaryColor.peachDeep)
                    Text("Off until you turn it on. The reminder is scheduled on this iPhone and is not sent anywhere.")
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.document.reminder.isEnabled {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                            .font(DiaryFont.body)
                    }
                }
                .padding(18)
                .background(DiaryColor.paper)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples")
                        .font(DiaryFont.section)
                    Text("Three example looks are added the first time you open Lookmira, so the diary is not empty. They are ordinary entries. Delete them whenever you like.")
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    legalButton("Privacy", page: .privacy)
                    legalButton("Terms", page: .terms)
                }
            }
            .padding(20)
        }
        .diaryScreen()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $legal) { page in
            NavigationStack {
                ScrollView {
                    Text(page.body)
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
                .diaryScreen()
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { legal = nil }
                            .font(DiaryFont.emphasis)
                    }
                }
            }
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var parts = model.calendar.dateComponents([.year, .month, .day], from: Date())
                parts.hour = model.document.reminder.hour
                parts.minute = model.document.reminder.minute
                return model.calendar.date(from: parts) ?? Date()
            },
            set: { value in
                let parts = model.calendar.dateComponents([.hour, .minute], from: value)
                model.setReminderTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
            }
        )
    }

    private func legalButton(_ title: String, page: LegalPage) -> some View {
        Button {
            legal = page
        } label: {
            HStack {
                Text(title)
                    .font(DiaryFont.emphasis)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(DiaryColor.ink)
            .padding(16)
            .background(DiaryColor.paper)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum LegalPage: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }
    var title: String { self == .privacy ? "Privacy" : "Terms" }
    var body: String { self == .privacy ? LegalCopy.privacy : LegalCopy.terms }
}

enum LegalCopy {
    static let privacy = """
    Lookmira keeps a private diary of makeup looks you have already finished. It does not require an account, and the diary works without a network connection.

    What stays on this device
    A look can include a date, a title, style tags, product names you type, notes, a favorite mark, and a photo you choose from your library. Lookmira copies that photo into the app’s storage on this iPhone or iPad. The copy is not uploaded. Lookmira does not operate a server for your diary.

    Photos
    The system photo picker is used only when you choose a picture. Lookmira does not use the camera, and it does not analyze a face. If you deny photo access, you can still write a look without a picture.

    Reminder
    A daily reminder is off until you turn it on. If you opt in, iOS schedules a local notification on this device at the time you pick. The reminder is not sent to Lookmira or to anyone else. You can turn it off in Lookmira, or turn notifications off for Lookmira in iOS Settings.

    What Lookmira does not collect
    There is no account, no advertising identifier, no analytics SDK, and no tracking. Lookmira does not sell personal information, because it does not receive any.

    Removing your diary
    Delete a look inside the app to remove that entry. Deleting the app removes the diary stored on the device.

    Children
    Lookmira is a general-audience journal. It is not directed at children, and it does not ask for an account.

    Contact
    Questions about this policy can be sent through the support link on the App Store listing.
    """

    static let terms = """
    Lookmira is a personal journal for makeup looks you choose to record. It is a notebook, not a makeup artist, not a medical device, and not a promise about any cosmetic product.

    You decide what to write. Product names are notes you type next to a look. They are not an inventory, a shop, or a recommendation to buy anything.

    Photos you add remain yours. You are responsible for having the right to keep them in your own diary. The three example looks shipped with the app are samples so the first open is not empty. You can delete them.

    The optional reminder only notifies this device. Lookmira does not guarantee that a notification will arrive if iOS notifications are off, Focus is on, or the device is unavailable.

    The app is provided as is. A saved look is your record of what you wore. It is not advice, and it is not a guarantee of how a product will look.

    If you use the app, you also agree to Apple’s licensed application end user license agreement where it applies: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

    These terms are governed by ordinary consumer rules where you live. If a term cannot be enforced, the rest still apply.
    """
}
