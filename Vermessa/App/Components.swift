import SwiftUI
import VermessaCore

struct PageColumn<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: sizeClass == .regular ? 920 : .infinity, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

struct ShadeSwatch: View {
    var shade: ShadeColor
    var height: CGFloat = 132
    var title: String?
    var subtitle: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(shade.swiftUIColor)
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let title {
                        Text(title)
                            .font(VermessaFont.display(28))
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(VermessaFont.body(17))
                    }
                }
                .foregroundStyle(shade.prefersLightText ? Color.white : VermessaColor.ink)
                .padding(18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

struct LipstickCard: View {
    var lipstick: Lipstick

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(lipstick.shade.swiftUIColor)
                .frame(height: 112)
                .overlay(alignment: .bottomLeading) {
                    Text(lipstick.finish.title)
                        .font(VermessaFont.label(16))
                        .foregroundStyle(lipstick.shade.prefersLightText ? Color.white : VermessaColor.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(lipstick.shade.prefersLightText ? 0.18 : 0.06), in: Capsule())
                        .padding(12)
                }
            Text(lipstick.name)
                .font(VermessaFont.display(22))
                .foregroundStyle(VermessaColor.ink)
                .lineLimit(2)
            if let brand = lipstick.brand {
                Text(brand)
                    .font(VermessaFont.body(16))
                    .foregroundStyle(VermessaColor.mist)
                    .lineLimit(1)
            }
            Text("\(lipstick.undertone.title) · \(lipstick.colorFamily.title)")
                .font(VermessaFont.body(16))
                .foregroundStyle(VermessaColor.mist)
        }
        .padding(12)
        .background(VermessaColor.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct ChoiceChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VermessaFont.label(17))
                .foregroundStyle(isSelected ? Color.white : VermessaColor.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? VermessaColor.merlot : VermessaColor.card, in: Capsule())
                .overlay(Capsule().stroke(VermessaColor.line, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct WideButton: View {
    var title: String
    var systemImage: String
    var filled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(VermessaFont.label(18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(filled ? Color.white : VermessaColor.merlot)
                .background(filled ? VermessaColor.merlot : VermessaColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(VermessaColor.merlot, lineWidth: filled ? 0 : 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FlowChips: View {
    var titles: [(String, Bool, () -> Void)]

    var body: some View {
        FlexibleWrap(spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { _, item in
                ChoiceChip(title: item.0, isSelected: item.1, action: item.2)
            }
        }
    }
}

struct FlexibleWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = place(subviews: subviews, width: width)
        let height = rows.last.map { $0.maxY } ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = place(subviews: subviews, width: bounds.width)
        for row in rows {
            for item in row.items {
                item.view.place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private struct Item {
        var view: LayoutSubview
        var x: CGFloat
        var y: CGFloat
        var size: CGSize
    }

    private struct Row {
        var items: [Item]
        var maxY: CGFloat
    }

    private func place(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var items: [Item] = []
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                rows.append(Row(items: items, maxY: y + rowHeight))
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
                items = []
            }
            items.append(Item(view: view, x: x, y: y, size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        if !items.isEmpty {
            rows.append(Row(items: items, maxY: y + rowHeight))
        }
        return rows
    }
}
