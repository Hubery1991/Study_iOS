import SwiftUI

struct BoardView: View {
    var puzzle: Puzzle
    var facing: Direction
    var spark: SparkEvent?
    var bumpCrateID: Int?
    var blockedToken: Int
    var moveToken: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var squash: CGFloat = 1
    @State private var shake: CGFloat = 0
    @State private var bumping = false

    var body: some View {
        GeometryReader { geo in
            let cell = cellSize(in: geo.size)
            let boardWidth = cell * CGFloat(puzzle.width)
            let boardHeight = cell * CGFloat(puzzle.height)
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.board)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Theme.boardRim, lineWidth: 6)
                    )
                    .shadow(color: Theme.shadow, radius: 12, y: 8)
                    .frame(width: boardWidth + 22, height: boardHeight + 22)

                ZStack(alignment: .topLeading) {
                    ForEach(0..<puzzle.height, id: \.self) { row in
                        ForEach(0..<puzzle.width, id: \.self) { col in
                            let point = GridPoint(row: row, col: col)
                            tile(point)
                                .frame(width: cell, height: cell)
                                .position(center(point, cell: cell))
                        }
                    }
                    ForEach(puzzle.crates) { crate in
                        CrateView(onGoal: puzzle.goals.contains(crate.point))
                            .frame(width: cell * 0.86, height: cell * 0.86)
                            .scaleEffect(crate.id == bumpCrateID && bumping ? 1.14 : 1)
                            .position(center(crate.point, cell: cell))
                            .animation(motion, value: crate.point)
                            .zIndex(2)
                    }
                    if let spark {
                        SparkleBurst()
                            .frame(width: cell, height: cell)
                            .position(center(spark.point, cell: cell))
                            .id(spark.token)
                            .zIndex(3)
                    }
                    MallowCharacter(facing: facing, squash: squash)
                        .frame(width: cell * 0.86, height: cell * 0.86)
                        .position(center(puzzle.player, cell: cell))
                        .offset(x: shake)
                        .animation(motion, value: puzzle.player)
                        .zIndex(4)
                }
                .frame(width: boardWidth, height: boardHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(summary)
        }
        .onChange(of: blockedToken) { _ in
            nudge()
        }
        .onChange(of: moveToken) { _ in
            squish()
        }
    }

    private var motion: Animation? {
        reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72)
    }

    private func tile(_ point: GridPoint) -> some View {
        ZStack {
            if puzzle.walls.contains(point) {
                WallBlock()
            } else {
                FloorTile(alt: (point.row + point.col).isMultiple(of: 2))
                if puzzle.goals.contains(point) {
                    DaisyPad(filled: puzzle.crates.contains { $0.point == point })
                        .padding(2)
                }
            }
        }
    }

    private func center(_ point: GridPoint, cell: CGFloat) -> CGPoint {
        CGPoint(
            x: (CGFloat(point.col) + 0.5) * cell,
            y: (CGFloat(point.row) + 0.5) * cell
        )
    }

    private func cellSize(in size: CGSize) -> CGFloat {
        let raw = min(size.width / CGFloat(puzzle.width), size.height / CGFloat(puzzle.height))
        return min(max(raw, 24), 96)
    }

    private func squish() {
        guard !reduceMotion else { return }
        squash = 1.14
        withAnimation(.spring(response: 0.24, dampingFraction: 0.45)) {
            squash = 1
        }
        if bumpCrateID != nil {
            bumping = true
            withAnimation(.spring(response: 0.32, dampingFraction: 0.42)) {
                bumping = false
            }
        }
    }

    private func nudge() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.06)) { shake = 7 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            withAnimation(.easeInOut(duration: 0.06)) { shake = -5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.08)) { shake = 0 }
        }
    }

    private var summary: String {
        let placed = puzzle.crates.filter { puzzle.goals.contains($0.point) }.count
        return "Meadow board. \(puzzle.moves) moves. \(placed) of \(puzzle.goals.count) crates on a daisy."
    }
}
