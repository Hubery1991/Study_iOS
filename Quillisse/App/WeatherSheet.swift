import SwiftUI

struct WeatherSheet: View {
    @ObservedObject var model: ClosetModel
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("The closet uses this choice when it builds a look. It does not need a network.")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                    sectionTitle("Weather")
                    chipFlow(WeatherBand.allCases.map { band in
                        (band.displayName, model.document.preferences.weather.band == band)
                    }) { index in
                        model.setManualBand(WeatherBand.allCases[index])
                    }
                    Toggle(isOn: rainingBinding) {
                        Text("Rain")
                            .font(Theme.serif(18))
                    }
                    .tint(Theme.oxblood)
                    sectionTitle("Season")
                    chipFlow(seasonItems) { index in
                        let seasons = Season.allCases.filter { $0 != .allSeason }
                        if index == 0 {
                            model.setSeason(nil)
                        } else {
                            model.setSeason(seasons[index - 1])
                        }
                    }
                    Rule()
                    Toggle(isOn: appleBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Weather")
                                .font(Theme.serif(18))
                            Text("Uses location only while you allow it, then keeps a band such as mild or rain. If it is denied or offline, the choice above stays.")
                                .font(Theme.sans(13, weight: .medium))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .tint(Theme.oxblood)
                    if working {
                        ProgressView()
                            .tint(Theme.oxblood)
                    }
                    if !model.weatherStatus.isEmpty {
                        Text(model.weatherStatus)
                            .font(Theme.serif(15))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var rainingBinding: Binding<Bool> {
        Binding(
            get: { model.document.preferences.weather.isRaining },
            set: { model.setRaining($0) }
        )
    }

    private var appleBinding: Binding<Bool> {
        Binding(
            get: { model.document.preferences.useAppleWeather },
            set: { enabled in
                if enabled {
                    working = true
                    Task {
                        await model.refreshAppleWeather()
                        working = false
                    }
                } else {
                    model.stopAppleWeather()
                }
            }
        )
    }

    private var seasonItems: [(String, Bool)] {
        let seasons = Season.allCases.filter { $0 != .allSeason }
        let current = model.document.preferences.seasonOverride
        var items: [(String, Bool)] = [("From the date", current == nil || current == .allSeason)]
        items += seasons.map { season in
            (season.displayName, current == season)
        }
        return items
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Theme.sans(12, weight: .semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Theme.muted)
    }

    private func chipFlow(_ items: [(String, Bool)], onTap: @escaping (Int) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ChoiceChip(title: item.0, selected: item.1) { onTap(index) }
                }
            }
        }
    }
}
