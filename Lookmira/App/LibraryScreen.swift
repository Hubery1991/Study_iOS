import LookmiraCore
import SwiftUI

struct LibraryScreen: View {
    @EnvironmentObject private var model: DiaryModel
    @State private var query = ""
    @State private var tag: StyleTag?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TextField("Search a tag or a product", text: $query)
                    .font(DiaryFont.body)
                    .padding(16)
                    .background(DiaryColor.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(DiaryColor.line, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TagChip(title: "All", selected: tag == nil) { tag = nil }
                        ForEach(StyleTag.allCases, id: \.self) { item in
                            TagChip(title: item.title, selected: tag == item) {
                                tag = tag == item ? nil : item
                            }
                        }
                    }
                }

                switch model.document.journal.library(text: query, tag: tag) {
                case .emptyDiary:
                    Text("The diary is empty. Add a look from the Diary tab.")
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.inkSoft)
                case .noMatches:
                    Text("Nothing matches that search.")
                        .font(DiaryFont.body)
                        .foregroundStyle(DiaryColor.inkSoft)
                case .matches(let looks):
                    Text(looks.count == 1 ? "1 look" : "\(looks.count) looks")
                        .font(DiaryFont.emphasis)
                        .foregroundStyle(DiaryColor.inkSoft)
                    ForEach(looks) { look in
                        NavigationLink {
                            LookDetailView(lookID: look.id)
                        } label: {
                            LookCard(look: look)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .diaryScreen()
        .navigationTitle("Looks")
        .navigationBarTitleDisplayMode(.large)
    }
}
