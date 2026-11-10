import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var store: ProgressStore

    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12)]

    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                ScreenColumn(maxWidth: 720) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(LevelCatalog.worlds, id: \.self) { world in
                            worldCard(world)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
        .meadowNavigation()
    }

    private func worldCard(_ world: Int) -> some View {
        let levels = LevelCatalog.levels.filter { $0.world == world }
        let stars = levels.reduce(0) { $0 + (store.save.records[$1.index]?.stars ?? 0) }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LevelCatalog.worldName(world))
                        .font(Theme.rounded(24))
                        .foregroundStyle(Theme.ink)
                    Text(WorldBlurb.line(world))
                        .font(Theme.rounded(14, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text("\(stars)/\(levels.count * 3)")
                    .font(Theme.rounded(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(levels) { level in
                    levelCell(level)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.cream.opacity(0.94))
                .shadow(color: Theme.shadow, radius: 8, y: 4)
        )
    }

    private func levelCell(_ level: LevelDefinition) -> some View {
        let unlocked = store.save.isUnlocked(level.index, levelCount: LevelCatalog.levels.count)
        let record = store.save.records[level.index]
        return NavigationLink(value: AppRoute.game(level.index)) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(unlocked ? Theme.floor : Theme.creamDeep)
                    if unlocked {
                        Text("\(level.index)")
                            .font(Theme.rounded(26))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .frame(height: 64)
                Text(level.title)
                    .font(Theme.rounded(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                StarRow(filled: record?.stars ?? 0, size: 12)
                Text(record.map { $0.bestMoves == 1 ? "1 move" : "\($0.bestMoves) moves" } ?? " ")
                    .font(Theme.rounded(11, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            )
        }
        .buttonStyle(PressStyle())
        .disabled(!unlocked)
        .accessibilityLabel(accessibility(level, unlocked: unlocked, record: record))
    }

    private func accessibility(_ level: LevelDefinition, unlocked: Bool, record: LevelRecord?) -> String {
        if !unlocked {
            return "Level \(level.index), \(level.title), locked"
        }
        if let record {
            return "Level \(level.index), \(level.title), \(record.stars) stars, best \(record.bestMoves) moves"
        }
        return "Level \(level.index), \(level.title), not cleared"
    }
}
