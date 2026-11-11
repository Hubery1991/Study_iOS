import SwiftUI

struct CheckCircle: View {
    var on: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(on ? Theme.sage : Color.clear)
            Circle()
                .stroke(on ? Theme.sage : Theme.line, lineWidth: 1.5)
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 28, height: 28)
    }
}

struct StepRow: View {
    var title: String
    var detail: String
    var detailColor: Color
    var checked: Bool
    var enabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            CheckCircle(on: checked)
                .opacity(enabled ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.serif(.title3))
                    .foregroundColor(Theme.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(detailColor)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(enabled ? 1 : 0.7)
    }
}

struct ProgressBar: View {
    var fraction: Double
    var tint: Color = Theme.sage

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line.opacity(0.7))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * proxy.size.width)
            }
        }
        .frame(height: 7)
        .accessibilityLabel("Progress")
    }
}

struct MonthDot: View {
    var mark: DayMark
    var isToday: Bool
    var inMonth: Bool
    var day: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("\(day)")
                .font(.system(.body, design: .serif))
                .foregroundColor(inMonth ? Theme.ink : Theme.muted.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(
                    Circle().stroke(isToday ? Theme.sageDeep : Color.clear, lineWidth: 1.5)
                )
            Circle()
                .fill(fill)
                .overlay(Circle().stroke(stroke, lineWidth: mark == .partial ? 2 : 0))
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var fill: Color {
        switch mark {
        case .complete: return Theme.sage
        case .partial: return Color.clear
        case .none: return Color.clear
        }
    }

    private var stroke: Color {
        mark == .partial ? Theme.clay : Color.clear
    }
}

struct ScalePicker: View {
    var title: String
    var labels: [String]
    var startsAtZero: Bool = false
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.ink)
                Spacer()
                Text(current)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
            }
            HStack(spacing: 8) {
                ForEach(labels.indices, id: \.self) { index in
                    let number = index + offset
                    let selected = value == number
                    Button {
                        value = number
                    } label: {
                        Text("\(number)")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selected ? Theme.sageDeep : Theme.paper)
                            .foregroundColor(selected ? Theme.card : Theme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(labels[index])")
                }
            }
        }
    }

    private var offset: Int { startsAtZero ? 0 : 1 }

    private var current: String {
        let index = value - offset
        guard labels.indices.contains(index) else { return "" }
        return labels[index]
    }
}

struct FreshnessColor {
    static func color(_ freshness: ShelfFreshness) -> Color {
        switch freshness {
        case .past: return Theme.rose
        case .soon: return Theme.amber
        case .good: return Theme.sageDeep
        case .sealed, .untracked: return Theme.muted
        }
    }
}

struct EmptyNote: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.serif(.title3))
                .foregroundColor(Theme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
