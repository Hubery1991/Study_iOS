import SwiftUI

struct StarRow: View {
    var stars: Int
    var total: Int = 3

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(index < stars ? SalonTheme.gold : SalonTheme.muted.opacity(0.45))
            }
        }
        .accessibilityLabel("\(stars) of \(total) stars")
    }
}

struct SalonCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SalonTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SalonTheme.line, lineWidth: 1)
            )
    }
}

struct ChipLabel: View {
    var title: String
    var selected: Bool = false

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? Color.white : SalonTheme.ink)
            .background(selected ? SalonTheme.rose : SalonTheme.paper)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(selected ? SalonTheme.rose : SalonTheme.line, lineWidth: 1))
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color.white)
            .background(SalonTheme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [SalonTheme.blush.opacity(0.55), SalonTheme.ivory, SalonTheme.ivory],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
