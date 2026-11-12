import SwiftUI
import PolquetteCore

struct StudioView: View {
    @EnvironmentObject private var model: SalonModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(spacing: 0) {
                    stage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    tools
                        .frame(width: 420)
                        .background(SalonTheme.paper.opacity(0.92))
                }
            } else {
                VStack(spacing: 0) {
                    stage
                    tools
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .background(SalonTheme.paper.opacity(0.94))
                }
            }
        }
        .background(SalonTheme.ivory)
        .navigationTitle("Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $model.showSave) { saveSheet }
        .alert("The chair", isPresented: $model.showScore) {
            Button("Keep painting", role: .cancel) {}
        } message: {
            Text(model.scoreMessage)
        }
    }

    private var stage: some View {
        VStack(spacing: 12) {
            scopeBar
            if let brief = model.activeBrief {
                briefBanner(brief)
            }
            ZStack {
                HandCanvas(manicure: model.studio.manicure, scope: model.studio.scope)
                HandTapOverlay(scope: model.studio.scope) { model.select($0) }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, 8)
    }

    private var tools: some View {
        ToolDeck()
            .padding(sizeClass == .regular ? 20 : 0)
    }

    private var scopeBar: some View {
        HStack {
            Text(model.studio.scope == .all ? "Painting all five" : "Painting the \(model.studio.scope.title.lowercased())")
                .font(SalonTheme.headline)
                .foregroundStyle(SalonTheme.ink)
            Spacer()
            Button(model.studio.scope == .all ? "All five" : "Paint all five") {
                model.selectAll()
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(model.studio.scope == .all ? SalonTheme.ink : SalonTheme.blush)
            .foregroundStyle(model.studio.scope == .all ? Color.white : SalonTheme.ink)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
    }

    private func briefBanner(_ brief: DesignBrief) -> some View {
        SalonCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(brief.title)
                    .font(SalonTheme.headline)
                Text(brief.note)
                    .font(.footnote)
                    .foregroundStyle(SalonTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Submit this set") { model.submitActive() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(SalonTheme.rose)
                        .clipShape(Capsule())
                    Button("Paint freely") { model.dismissBrief() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SalonTheme.ink)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                model.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!model.studio.canUndo)
            .accessibilityLabel("Undo")
            Button {
                model.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!model.studio.canRedo)
            .accessibilityLabel("Redo")
            Button {
                model.prepareSave()
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("Save look")
        }
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section("Name this look") {
                    TextField("Blush Pearl", text: $model.saveName)
                }
                Section {
                    Text("It stays in your book on this device.")
                        .font(.footnote)
                        .foregroundStyle(SalonTheme.muted)
                }
            }
            .navigationTitle("Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.showSave = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.confirmSave() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
