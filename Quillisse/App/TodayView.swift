import SwiftUI

struct TodayView: View {
    @ObservedObject var model: ClosetModel
    @State private var showWeather = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Masthead(kicker: weekday, title: dayMonth)
                    occasionRow
                    weatherButton
                    if showsSampleNote {
                        sampleNote
                    }
                    if let worn = model.document.wear(on: model.today) {
                        loggedCard(worn)
                    }
                    if let look = model.currentSuggestion {
                        suggestionCard(look)
                    } else {
                        emptyCard
                    }
                    favoriteStrip
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QUILLISSE")
                        .font(Theme.sans(12, weight: .semibold))
                        .tracking(2.4)
                        .foregroundStyle(Theme.ink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Theme.ink)
                    }
                    .accessibilityLabel("About")
                }
            }
            .sheet(isPresented: $showWeather) {
                WeatherSheet(model: model)
            }
            .sheet(isPresented: $showAbout) {
                AboutView(model: model)
            }
        }
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var dayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: Date())
    }

    private var showsSampleNote: Bool {
        !model.document.preferences.hasDismissedSampleNote
            && model.document.garments.contains(where: \.isSample)
    }

    private var occasionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Occasion.allCases, id: \.self) { occasion in
                    ChoiceChip(title: occasion.displayName, selected: model.occasion == occasion) {
                        model.setOccasion(occasion)
                    }
                }
            }
        }
    }

    private var weatherButton: some View {
        Button {
            showWeather = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: model.document.preferences.weather.isRaining ? "cloud.rain" : "sun.max")
                    .foregroundStyle(Theme.oxblood)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.document.preferences.weather.label)
                        .font(Theme.serif(18))
                        .foregroundStyle(Theme.ink)
                    Text(weatherSubtitle)
                        .font(Theme.sans(12, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Text("Change")
                    .font(Theme.sans(13, weight: .semibold))
                    .foregroundStyle(Theme.oxblood)
            }
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var weatherSubtitle: String {
        let season = model.document.preferences.season(on: model.today).displayName
        if model.document.preferences.weatherIsFromDevice, !model.document.preferences.weatherNote.isEmpty {
            return "\(season) · Apple Weather · \(model.document.preferences.weatherNote)"
        }
        return "\(season) · chosen on this device"
    }

    private var sampleNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A sample closet is here so the first day is not empty. Pieces you add stay on this device.")
                .font(Theme.serif(15))
                .foregroundStyle(Theme.ink)
            Button("Dismiss") { model.dismissSampleNote() }
                .font(Theme.sans(13, weight: .semibold))
                .foregroundStyle(Theme.oxblood)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func loggedCard(_ wear: WearEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Worn today")
                .font(Theme.sans(11, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Theme.oxblood)
            Text(OutfitEngine.title(for: model.document.resolved(wear.pieceIDs)))
                .font(Theme.serif(22))
                .foregroundStyle(Theme.ink)
            tileRow(model.document.resolved(wear.pieceIDs))
            Button("Clear today’s log") { model.clearToday() }
                .font(Theme.sans(13, weight: .semibold))
                .foregroundStyle(Theme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func suggestionCard(_ look: SuggestedLook) -> some View {
        let already = model.document.wear(on: model.today).map {
            OutfitEngine.signature(for: $0.pieceIDs) == look.signature
        } ?? false
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested")
                    .font(Theme.sans(11, weight: .semibold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.oxblood)
                Spacer()
                Button {
                    model.toggleFavorite(look: look)
                } label: {
                    Image(systemName: model.isFavorite(look) ? "heart.fill" : "heart")
                        .foregroundStyle(Theme.oxblood)
                }
                .accessibilityLabel(model.isFavorite(look) ? "Remove favorite" : "Save favorite")
            }
            Text(look.title)
                .font(Theme.serif(26))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(look.reasons, id: \.self) { reason in
                    Text(reason)
                        .font(Theme.serif(15))
                        .foregroundStyle(Theme.muted)
                }
            }
            tileRow(look.pieces)
            EditorialButton(title: already ? "Worn today" : "Wear this today") {
                guard !already else { return }
                model.wear(pieces: look.pieces, occasion: model.occasion)
            }
            .opacity(already ? 0.45 : 1)
            .disabled(already)
            if model.suggestions.count > 1 {
                Button("Another look") { model.showAnother() }
                    .font(Theme.sans(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    private func tileRow(_ pieces: [Garment]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(pieces) { piece in
                    PieceTile(garment: piece, compact: true)
                        .frame(width: 108)
                }
            }
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing to wear yet")
                .font(Theme.serif(24))
            Text("Add a top and a bottom, or a dress, from the Closet tab. Shoes make the suggestion complete.")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var favoriteStrip: some View {
        let favorites = model.document.looks.filter(\.isFavorite)
        if !favorites.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Favorites")
                    .font(Theme.serif(22))
                ForEach(favorites) { look in
                    Button {
                        let pieces = model.document.resolved(look.pieceIDs)
                        model.wear(pieces: pieces, occasion: look.occasion ?? model.occasion, lookID: look.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(look.name)
                                    .font(Theme.serif(17))
                                    .foregroundStyle(Theme.ink)
                                Text(look.occasion?.displayName ?? "Saved")
                                    .font(Theme.sans(12, weight: .medium))
                                    .foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text("Wear")
                                .font(Theme.sans(13, weight: .semibold))
                                .foregroundStyle(Theme.oxblood)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    Rule()
                }
            }
        }
    }
}
