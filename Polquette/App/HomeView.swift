import SwiftUI
import PolquetteCore

struct HomeView: View {
    @EnvironmentObject private var model: SalonModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                todayCard
                careerCard
                PrimaryButton(title: "Open the studio", systemImage: "paintbrush.pointed") {
                    model.openFreeStudio()
                }
                looksRow
                bookRow
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(ScreenBackground())
        .navigationTitle("Polquette")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.open(.about)
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About")
            }
        }
        .sheet(isPresented: $model.showPrimer) {
            PrimerSheet {
                model.markPrimerSeen()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The salon")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SalonTheme.roseDeep)
                .textCase(.uppercase)
                .tracking(1.2)
            Text("Polquette")
                .font(SalonTheme.largeTitle)
                .foregroundStyle(SalonTheme.ink)
            Text("Design a manicure on an illustrated hand. Save the look. Take today’s chair.")
                .font(.body)
                .foregroundStyle(SalonTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var todayCard: some View {
        Button {
            model.open(.challenge)
        } label: {
            SalonCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today’s chair")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SalonTheme.roseDeep)
                        Text(model.todayBrief.title)
                            .font(SalonTheme.headline)
                            .foregroundStyle(SalonTheme.ink)
                        Text(model.todayBrief.note)
                            .font(.footnote)
                            .foregroundStyle(SalonTheme.muted)
                            .multilineTextAlignment(.leading)
                        StarRow(stars: model.todayStars)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SalonTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var careerCard: some View {
        Button {
            model.open(.challenge)
        } label: {
            SalonCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Salon career")
                            .font(SalonTheme.headline)
                            .foregroundStyle(SalonTheme.ink)
                        Text("\(model.archive.career.unlockedCount) of \(Career.clients.count) chairs open · \(model.archive.career.totalStars) stars")
                            .font(.footnote)
                            .foregroundStyle(SalonTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SalonTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var looksRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Looks")
                    .font(SalonTheme.headline)
                Spacer()
                Button("See all") { model.open(.looks) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SalonTheme.roseDeep)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Lookbook.looks) { look in
                        Button {
                            model.apply(look: look)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HandCanvas(manicure: look.manicure, scope: .all, showsSelection: false)
                                    .frame(width: 150, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                Text(look.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SalonTheme.ink)
                            }
                            .frame(width: 150, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var bookRow: some View {
        Button {
            model.open(.gallery)
        } label: {
            SalonCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your book")
                            .font(SalonTheme.headline)
                            .foregroundStyle(SalonTheme.ink)
                        Text(model.archive.looks.isEmpty ? "Nothing saved yet." : "\(model.archive.looks.count) saved \(model.archive.looks.count == 1 ? "look" : "looks").")
                            .font(.footnote)
                            .foregroundStyle(SalonTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SalonTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct PrimerSheet: View {
    var dismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A short sitting")
                        .font(SalonTheme.largeTitle)
                    Text("Tap a nail to paint that one, or paint all five at once. Shape, color, finish, French tips, gradients, and small decorations are in the tray.")
                    Text("Looks such as Blush Pearl and Burgundy Foil set the whole hand in one tap. Undo and redo sit at the top. Save puts the manicure in your book.")
                    Text("Today’s chair and the salon career score the hand you submit. Three stars means every request was met. Stars stay on this device.")
                }
                .font(.body)
                .foregroundStyle(SalonTheme.ink)
                .padding(24)
            }
            .background(SalonTheme.ivory)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Begin") { dismiss() }
                }
            }
        }
    }
}
