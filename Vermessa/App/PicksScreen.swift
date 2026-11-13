import SwiftUI
import VermessaCore

struct PicksScreen: View {
    @EnvironmentObject private var drawer: DrawerModel
    @State private var occasion: Occasion? = .date
    @State private var undertone: Undertone? = .warm

    private var picks: [ShadeRecommendation] {
        drawer.library.recommendations(
            RecommendationQuery(occasion: occasion, undertone: undertone, day: drawer.today, limit: 8)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                PageColumn {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Picks")
                            .font(VermessaFont.display(40))
                            .foregroundStyle(VermessaColor.ink)
                        Text("Ranked from lipsticks you own. A matching occasion, a close undertone, and a long quiet stretch all raise a shade.")
                            .font(VermessaFont.body(18))
                            .foregroundStyle(VermessaColor.mist)
                            .fixedSize(horizontal: false, vertical: true)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Occasion")
                                .font(VermessaFont.display(22))
                            FlowChips(titles: occasionChips)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Undertone")
                                .font(VermessaFont.display(22))
                            FlowChips(titles: undertoneChips)
                        }
                        if picks.isEmpty {
                            Text("Add lipsticks to the drawer before asking for a pick.")
                                .font(VermessaFont.body(18))
                                .foregroundStyle(VermessaColor.mist)
                        } else {
                            ForEach(Array(picks.enumerated()), id: \.element.id) { index, pick in
                                NavigationLink(value: pick.lipstick.id) {
                                    pickRow(rank: index + 1, pick: pick)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(VermessaColor.paper)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                ShadeDetailView(lipstickID: id)
            }
        }
    }

    private var occasionChips: [(String, Bool, () -> Void)] {
        var chips: [(String, Bool, () -> Void)] = [("Any", occasion == nil, { occasion = nil })]
        for item in Occasion.allCases {
            let choice = item
            chips.append((choice.title, occasion == choice, { occasion = choice }))
        }
        return chips
    }

    private var undertoneChips: [(String, Bool, () -> Void)] {
        var chips: [(String, Bool, () -> Void)] = [("Any", undertone == nil, { undertone = nil })]
        for item in Undertone.allCases {
            let choice = item
            chips.append((choice.title, undertone == choice, { undertone = choice }))
        }
        return chips
    }

    private func pickRow(rank: Int, pick: ShadeRecommendation) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(pick.lipstick.shade.swiftUIColor)
                .frame(width: 64, height: 64)
                .overlay {
                    Text("\(rank)")
                        .font(VermessaFont.label(18))
                        .foregroundStyle(pick.lipstick.shade.prefersLightText ? Color.white : VermessaColor.ink)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(pick.lipstick.name)
                    .font(VermessaFont.display(22))
                    .foregroundStyle(VermessaColor.ink)
                Text(pick.score.reasons.joined(separator: " · "))
                    .font(VermessaFont.body(17))
                    .foregroundStyle(VermessaColor.mist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
