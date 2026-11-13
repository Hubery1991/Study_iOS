import LookmiraCore
import SwiftUI
import UIKit

enum DiaryColor {
    static let ivory = Color(red: 0.969, green: 0.945, blue: 0.918)
    static let paper = Color(red: 1.0, green: 0.988, blue: 0.973)
    static let ink = Color(red: 0.165, green: 0.129, blue: 0.110)
    static let inkSoft = Color(red: 0.361, green: 0.318, blue: 0.282)
    static let peach = Color(red: 0.788, green: 0.416, blue: 0.333)
    static let peachDeep = Color(red: 0.639, green: 0.294, blue: 0.235)
    static let blush = Color(red: 0.953, green: 0.878, blue: 0.839)
    static let line = Color(red: 0.902, green: 0.863, blue: 0.824)
    static let sage = Color(red: 0.431, green: 0.498, blue: 0.384)
}

enum DiaryFont {
    static let display = Font.system(size: 34, weight: .semibold, design: .serif)
    static let section = Font.system(size: 28, weight: .semibold, design: .serif)
    static let cardTitle = Font.system(size: 24, weight: .semibold, design: .serif)
    static let body = Font.system(size: 18, weight: .regular)
    static let emphasis = Font.system(size: 18, weight: .semibold)
    static let button = Font.system(size: 20, weight: .semibold)
}

struct DiaryScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DiaryColor.ivory.ignoresSafeArea())
    }
}

extension View {
    func diaryScreen() -> some View {
        modifier(DiaryScreenBackground())
    }
}

struct LookPhoto: View {
    var url: URL?
    var preview: Data?
    var height: CGFloat = 280

    var body: some View {
        Group {
            if let image = resolvedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    DiaryColor.blush
                    Text("Lm")
                        .font(.system(size: 42, weight: .semibold, design: .serif))
                        .foregroundStyle(DiaryColor.peachDeep)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var resolvedImage: UIImage? {
        if let preview, let image = UIImage(data: preview) {
            return image
        }
        if let url {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}

struct TagChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DiaryFont.emphasis)
                .foregroundStyle(selected ? Color.white : DiaryColor.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? DiaryColor.peachDeep : DiaryColor.blush)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct LookCard: View {
    @EnvironmentObject private var model: DiaryModel
    var look: MakeupLook

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LookPhoto(url: model.photoURL(look.photoFileName), height: 300)
            VStack(alignment: .leading, spacing: 10) {
                Text(look.title)
                    .font(DiaryCardTitleFont)
                    .foregroundStyle(DiaryColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(DiaryDates.dayTitle(look.wornOn, calendar: model.calendar))
                    .font(DiaryFont.body)
                    .foregroundStyle(DiaryColor.inkSoft)
                HStack(spacing: 8) {
                    ForEach(look.styleTags, id: \.self) { tag in
                        Text(tag.title)
                            .font(DiaryFont.emphasis)
                            .foregroundStyle(DiaryColor.peachDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DiaryColor.blush)
                            .clipShape(Capsule())
                    }
                }
                Text(look.productSummary)
                    .font(DiaryFont.body)
                    .foregroundStyle(DiaryColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(DiaryColor.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(DiaryColor.line, lineWidth: 1)
        )
    }
}

private let DiaryCardTitleFont = Font.system(size: 24, weight: .semibold, design: .serif)

struct PrimaryBarButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DiaryFont.button)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(DiaryColor.peachDeep)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryBarButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DiaryFont.button)
                .foregroundStyle(DiaryColor.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(DiaryColor.paper)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(DiaryColor.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
