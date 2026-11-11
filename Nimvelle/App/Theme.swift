import SwiftUI
import UIKit

enum Theme {
    static let paper = Color(red: 0.965, green: 0.949, blue: 0.925)
    static let card = Color(red: 0.992, green: 0.980, blue: 0.965)
    static let ink = Color(red: 0.165, green: 0.149, blue: 0.133)
    static let muted = Color(red: 0.431, green: 0.396, blue: 0.361)
    static let line = Color(red: 0.855, green: 0.816, blue: 0.765)
    static let sage = Color(red: 0.494, green: 0.561, blue: 0.471)
    static let sageDeep = Color(red: 0.243, green: 0.325, blue: 0.267)
    static let blush = Color(red: 0.894, green: 0.780, blue: 0.745)
    static let clay = Color(red: 0.769, green: 0.643, blue: 0.541)
    static let amber = Color(red: 0.769, green: 0.541, blue: 0.290)
    static let rose = Color(red: 0.659, green: 0.353, blue: 0.322)
    static let dusk = Color(red: 0.557, green: 0.478, blue: 0.573)

    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif).weight(weight)
    }

    static func install() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = UIColor(red: 0.965, green: 0.949, blue: 0.925, alpha: 1)
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [.foregroundColor: UIColor(red: 0.165, green: 0.149, blue: 0.133, alpha: 1)]
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.165, green: 0.149, blue: 0.133, alpha: 1)]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 1)
        tab.shadowColor = UIColor(red: 0.855, green: 0.816, blue: 0.765, alpha: 1)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct SpaCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }
}

struct SpaScreen<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
        }
        .background(Theme.paper.ignoresSafeArea())
    }
}

enum DayText {
    static func full(_ day: DayKey, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter.string(from: day.date(calendar: calendar))
    }

    static func medium(_ day: DayKey, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: day.date(calendar: calendar))
    }

    static func month(_ year: Int, _ month: Int, calendar: Calendar) -> String {
        let day = DayKey(year: year, month: month, day: 1)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: day.date(calendar: calendar))
    }

    static func greeting(at date: Date, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    static func streak(_ count: Int) -> String {
        if count == 0 { return "No streak yet" }
        if count == 1 { return "1-day streak" }
        return "\(count)-day streak"
    }
}
