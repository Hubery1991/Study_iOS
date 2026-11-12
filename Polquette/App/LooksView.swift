import SwiftUI
import PolquetteCore

struct LooksView: View {
    @EnvironmentObject private var model: SalonModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Lookbook.looks) { look in
                    SalonCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(look.name)
                                .font(SalonTheme.headline)
                            Text(look.blurb)
                                .font(.footnote)
                                .foregroundStyle(SalonTheme.muted)
                            HandCanvas(manicure: look.manicure, scope: .all, showsSelection: false)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            Button("Use this look") {
                                model.apply(look: look)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SalonTheme.ink)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(ScreenBackground())
        .navigationTitle("Looks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
