import SwiftUI
import VermessaCore

struct WishScreen: View {
    @EnvironmentObject private var drawer: DrawerModel
    @State private var text = ""
    @State private var showEditor = false

    private var wishes: [Lipstick] {
        drawer.wishlist(matching: text)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PageColumn {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Wishlist")
                            .font(VermessaFont.display(40))
                            .foregroundStyle(VermessaColor.ink)
                        Text("Shades you want, kept apart from the ones you can wear today.")
                            .font(VermessaFont.body(18))
                            .foregroundStyle(VermessaColor.mist)
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                            TextField("Search the wishlist", text: $text)
                                .font(VermessaFont.body(18))
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(VermessaColor.ink)
                        if wishes.isEmpty {
                            Text(text.isEmpty ? "No shades on the wishlist yet." : "Nothing on the wishlist matches that search.")
                                .font(VermessaFont.body(18))
                                .foregroundStyle(VermessaColor.mist)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 168), spacing: 14)], spacing: 14) {
                                ForEach(wishes) { lipstick in
                                    NavigationLink(value: lipstick.id) {
                                        LipstickCard(lipstick: lipstick)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(VermessaColor.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Add a wishlist shade")
                }
            }
            .sheet(isPresented: $showEditor) {
                ShadeEditor(mode: .create(.wishlist))
            }
            .navigationDestination(for: UUID.self) { id in
                ShadeDetailView(lipstickID: id)
            }
        }
    }
}
