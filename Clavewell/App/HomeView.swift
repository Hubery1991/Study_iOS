import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            WellBackground()
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 18) {
                        Spacer(minLength: 12)
                        VStack(spacing: 8) {
                            Text("A WELL OF COLORED LIGHT")
                                .font(Theme.rounded(12, .bold))
                                .tracking(1.8)
                                .foregroundStyle(Theme.brass)
                            Text("Clavewell")
                                .font(Theme.serif(58))
                                .foregroundStyle(Theme.parchment)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            ClaveRule()
                            Text("Drop motes. Match three. Keep the rim clear.")
                                .font(Theme.rounded(16, .medium))
                                .foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                        }

                        WellMark(size: 168)
                            .padding(.vertical, 6)

                        VStack(spacing: 10) {
                            Button {
                                router.path.append(AppRoute.modes)
                            } label: {
                                BrassLabel(title: "Play")
                            }
                            .buttonStyle(PressStyle())
                            Button {
                                router.path.append(AppRoute.howTo)
                            } label: {
                                GhostLabel(title: "How to Play")
                            }
                            .buttonStyle(PressStyle())
                            Button {
                                router.path.append(AppRoute.records)
                            } label: {
                                GhostLabel(title: "Records")
                            }
                            .buttonStyle(PressStyle())
                        }

                        HStack(spacing: 12) {
                            footerLink("Settings", route: .settings, symbol: "gearshape")
                            footerLink("About", route: .about, symbol: "info.circle")
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func footerLink(_ title: String, route: AppRoute, symbol: String) -> some View {
        Button {
            router.path.append(route)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title)
                    .font(Theme.rounded(15, .semibold))
            }
            .foregroundStyle(Theme.parchment)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
            )
        }
        .buttonStyle(PressStyle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { HomeView() }
            .environmentObject(Router())
            .preferredColorScheme(.dark)
    }
}
