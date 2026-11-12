import SwiftUI

struct GarmentPhoto: View {
    var token: String

    var body: some View {
        Group {
            if token.hasPrefix("seed-") {
                Image(token)
                    .resizable()
                    .scaledToFit()
            } else if let image = PhotoStore.image(for: token) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "tshirt")
                    .font(.title2)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.card)
    }
}

struct ChoiceChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.sans(13, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Theme.card : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Theme.ink : Theme.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.line, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct EditorialButton: View {
    var title: String
    var filled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.sans(16, weight: .semibold))
                .foregroundStyle(filled ? Theme.card : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(filled ? Theme.oxblood : Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(filled ? Color.clear : Theme.ink, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PieceTile: View {
    var garment: Garment
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                GarmentPhoto(token: garment.imageToken)
                    .frame(height: compact ? 92 : 148)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Circle()
                    .fill(Theme.swatch(garment.primaryColor))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Theme.card, lineWidth: 1))
                    .padding(8)
            }
            Text(garment.name)
                .font(Theme.serif(compact ? 13 : 16))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(garment.formality.displayName)
                .font(Theme.sans(11, weight: .medium))
                .foregroundStyle(Theme.muted)
                .tracking(0.6)
                .textCase(.uppercase)
        }
    }
}

struct Rule: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
    }
}

struct Masthead: View {
    var kicker: String
    var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kicker)
                .font(Theme.sans(11, weight: .semibold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Theme.oxblood)
            Text(title)
                .font(Theme.serif(34))
                .foregroundStyle(Theme.ink)
        }
    }
}
