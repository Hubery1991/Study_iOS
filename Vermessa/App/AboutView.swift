import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            PageColumn {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Vermessa")
                        .font(VermessaFont.display(36))
                        .foregroundStyle(VermessaColor.ink)
                    Text("Vermessa is a private lipstick wardrobe. You catalog the tubes you own, filter them, and get picks from that list. It is not a live makeup mirror.")
                        .font(VermessaFont.body(18))
                        .foregroundStyle(VermessaColor.ink)
                    section("On this device", "Names, brands, finishes, undertones, color families, occasion tags, shade colors, wishlist items, and wear dates stay in the app’s private storage. There is no account and no network call for the wardrobe.")
                    section("Photos", "A tube or swatch picture is optional. You choose it from the photo library. Vermessa does not open the camera, and the picture is not uploaded.")
                    section("Still shade cards", "A few color families show a bundled studio photograph so you can see the mood of a shade. Those pictures are not your face and they are not a try-on.")
                    section("Removing data", "Delete a lipstick inside the app, or delete Vermessa to remove the whole drawer.")
                }
                .padding(20)
            }
        }
        .background(VermessaColor.paper)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(VermessaFont.display(24))
                .foregroundStyle(VermessaColor.ink)
            Text(body)
                .font(VermessaFont.body(18))
                .foregroundStyle(VermessaColor.mist)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
