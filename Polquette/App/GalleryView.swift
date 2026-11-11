import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var model: SalonModel

    var body: some View {
        Group {
            if model.archive.looks.isEmpty {
                VStack(spacing: 12) {
                    Text("Your book is empty")
                        .font(SalonTheme.headline)
                    Text("Save a manicure from the studio and it will wait here.")
                        .font(.body)
                        .foregroundStyle(SalonTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(model.archive.looks) { look in
                            SalonCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(look.name)
                                            .font(SalonTheme.headline)
                                        Spacer()
                                        Button(role: .destructive) {
                                            model.deleteLook(id: look.id)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .accessibilityLabel("Delete \(look.name)")
                                    }
                                    HandCanvas(manicure: look.manicure, scope: .all, showsSelection: false)
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    Button("Open in the studio") {
                                        model.load(saved: look)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SalonTheme.roseDeep)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(ScreenBackground())
        .navigationTitle("Your book")
        .navigationBarTitleDisplayMode(.inline)
    }
}
