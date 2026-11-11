import SwiftUI
import PolquetteCore

struct ChallengeView: View {
    @EnvironmentObject private var model: SalonModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Today’s chair")
                    .font(SalonTheme.headline)
                SalonCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(model.todayBrief.title)
                                .font(SalonTheme.headline)
                            Spacer()
                            StarRow(stars: model.todayStars)
                        }
                        Text(model.todayBrief.client)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SalonTheme.roseDeep)
                        Text(model.todayBrief.note)
                            .font(.body)
                            .foregroundStyle(SalonTheme.ink)
                        Button("Design this") { model.beginDaily() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SalonTheme.ink)
                            .clipShape(Capsule())
                    }
                }

                Text("The book of chairs")
                    .font(SalonTheme.headline)
                Text("A short salon career. One star opens the next chair. Your best score is kept.")
                    .font(.footnote)
                    .foregroundStyle(SalonTheme.muted)

                ForEach(Career.clients) { client in
                    let unlocked = Career.isUnlocked(index: client.index, progress: model.archive.career)
                    SalonCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(client.index + 1). \(client.brief.title)")
                                    .font(.body.weight(.semibold))
                                Spacer()
                                if unlocked {
                                    StarRow(stars: model.archive.career.stars(for: client.id))
                                } else {
                                    Image(systemName: "lock")
                                        .foregroundStyle(SalonTheme.muted)
                                }
                            }
                            Text(client.brief.client)
                                .font(.footnote)
                                .foregroundStyle(SalonTheme.muted)
                            if unlocked {
                                Text(client.brief.note)
                                    .font(.footnote)
                                    .foregroundStyle(SalonTheme.ink)
                                Button("Take this chair") { model.beginCareer(index: client.index) }
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(SalonTheme.roseDeep)
                            }
                        }
                    }
                    .opacity(unlocked ? 1 : 0.72)
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(ScreenBackground())
        .navigationTitle("Chairs")
        .navigationBarTitleDisplayMode(.inline)
    }
}
