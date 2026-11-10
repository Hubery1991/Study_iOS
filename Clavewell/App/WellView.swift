import SwiftUI

struct WellView: View {
    @ObservedObject var model: PlayModel
    var showPatterns: Bool
    var showGuide: Bool

    var body: some View {
        GeometryReader { geo in
            let inset: CGFloat = 12
            let columns = CGFloat(WellBoard.columns)
            let rows = CGFloat(WellBoard.rows)
            let availableWidth = max(0, geo.size.width - inset * 2)
            let availableHeight = max(0, geo.size.height - inset * 2)
            let cell = min(availableWidth / columns, availableHeight / rows, 92)
            let boardWidth = cell * columns
            let boardHeight = cell * rows
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.shaft)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.brass.opacity(0.9), lineWidth: 3)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.brass.opacity(0.25), lineWidth: 1)
                    .padding(7)
                HStack(spacing: 0) {
                    ForEach(0..<WellBoard.columns, id: \.self) { column in
                        columnStack(column: column, cell: cell)
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
            }
            .frame(width: boardWidth + inset * 2, height: boardHeight + inset * 2)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityElement(children: .contain)
    }

    private func columnStack(column: Int, cell: CGFloat) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(0..<WellBoard.rows, id: \.self) { row in
                    cellView(row: row, column: column, cell: cell)
                }
            }
            if let landing = model.landing, landing.column == column {
                MoteView(hue: model.board.hue(landing) ?? model.now, showPattern: showPatterns)
                    .frame(width: cell * 0.84, height: cell * 0.84)
                    .offset(y: moteY(row: landing.row, cell: cell, settled: model.landingSettled))
            }
            Button {
                model.drop(in: column)
            } label: {
                Color.clear
                    .frame(width: cell, height: cell * CGFloat(WellBoard.rows))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label(for: column))
            .accessibilityHint("Drops the \(model.now.name) mote")
        }
        .frame(width: cell, height: cell * CGFloat(WellBoard.rows))
        .modifier(ShakeEffect(shakes: model.shake, active: model.rejectedColumn == column))
    }

    private func cellView(row: Int, column: Int, cell: CGFloat) -> some View {
        let coord = CellCoord(row: row, column: column)
        let hidden = model.landing == coord
        let clearing = model.clearing.contains(coord)
        let guide = showGuide && !hidden && model.board.hue(coord) == nil && model.board.lowestEmptyRow(in: column) == row
        return ZStack {
            if guide {
                Circle()
                    .strokeBorder(Theme.brass.opacity(0.28), lineWidth: 1.5)
                    .padding(cell * 0.16)
            }
            if let hue = model.board.hue(coord), !hidden {
                MoteView(hue: hue, showPattern: showPatterns)
                    .frame(width: cell * 0.84, height: cell * 0.84)
                    .scaleEffect(clearing ? 1.2 : 1)
                    .opacity(clearing ? 0.12 : 1)
            }
        }
        .frame(width: cell, height: cell)
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.28), value: clearing)
    }

    private func moteY(row: Int, cell: CGFloat, settled: Bool) -> CGFloat {
        let mote = cell * 0.84
        let padding = (cell - mote) / 2
        if settled {
            return CGFloat(row) * cell + padding
        }
        return padding * 0.2
    }

    private func label(for column: Int) -> String {
        let number = column + 1
        if model.board.lowestEmptyRow(in: column) == nil {
            return "Column \(number), full"
        }
        let landing = model.board.lowestEmptyRow(in: column).map { WellBoard.rows - $0 } ?? 0
        return "Column \(number), \(model.now.name), lands \(landing) from the floor"
    }
}
