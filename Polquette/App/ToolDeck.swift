import SwiftUI
import PolquetteCore

enum ToolTab: String, CaseIterable, Identifiable {
    case shape = "Shape"
    case color = "Color"
    case finish = "Finish"
    case french = "French"
    case fade = "Fade"
    case decor = "Decor"

    var id: String { rawValue }
}

struct ToolDeck: View {
    @EnvironmentObject private var model: SalonModel
    @State private var tab: ToolTab = .color
    @State private var decorColorID = Palette.goldID

    private var sample: NailDesign { model.studio.manicure.nail(model.studio.scope.fingers[0]) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ToolTab.allCases) { item in
                        Button {
                            tab = item
                        } label: {
                            ChipLabel(title: item.rawValue, selected: tab == item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Group {
                switch tab {
                case .shape: shapeRow
                case .color: colorRow
                case .finish: finishRow
                case .french: frenchControls
                case .fade: fadeControls
                case .decor: decorControls
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var shapeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NailShape.allCases) { shape in
                    Button {
                        model.setShape(shape)
                    } label: {
                        ChipLabel(title: shape.title, selected: sample.shape == shape)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Palette.colors) { polish in
                    Button {
                        model.setColor(polish.id)
                    } label: {
                        Circle()
                            .fill(SalonTheme.polish(polish.id))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(sample.colorID == polish.id ? SalonTheme.gold : Color.white, lineWidth: sample.colorID == polish.id ? 3 : 1))
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(polish.name)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var finishRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Finish.allCases) { finish in
                        Button {
                            model.setFinish(finish)
                        } label: {
                            ChipLabel(title: finish.title, selected: sample.finish == finish)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text(sample.finish.blurb)
                .font(.footnote)
                .foregroundStyle(SalonTheme.muted)
        }
    }

    private var frenchControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("French tip", isOn: frenchBinding)
                .tint(SalonTheme.rose)
            if sample.french.enabled {
                Text("Tip color")
                    .font(.footnote)
                    .foregroundStyle(SalonTheme.muted)
                colorChoices(selected: sample.french.colorID) { model.setFrench(enabled: true, colorID: $0) }
                Text("Length")
                    .font(.footnote)
                    .foregroundStyle(SalonTheme.muted)
                Slider(value: coverageBinding, in: 0.16...0.48) { editing in
                    if !editing { model.endFrenchCoverage() }
                }
                .tint(SalonTheme.rose)
            }
        }
    }

    private var fadeControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Gradient", isOn: gradientBinding)
                .tint(SalonTheme.rose)
            if sample.gradient.enabled {
                Text("Second color")
                    .font(.footnote)
                    .foregroundStyle(SalonTheme.muted)
                colorChoices(selected: sample.gradient.endColorID) { model.setGradient(enabled: true, endColorID: $0) }
            }
        }
    }

    private var decorControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a piece to place it. Up to four on a nail.")
                .font(.footnote)
                .foregroundStyle(SalonTheme.muted)
            colorChoices(selected: decorColorID) { decorColorID = $0 }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Palette.motifs) { motif in
                        Button {
                            model.addDecoration(motifID: motif.id, colorID: decorColorID)
                        } label: {
                            ChipLabel(title: motif.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Button("Clear decorations") {
                model.clearDecorations()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(SalonTheme.roseDeep)
        }
    }

    private func colorChoices(selected: String, action: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Palette.colors) { polish in
                    Button {
                        action(polish.id)
                    } label: {
                        Circle()
                            .fill(SalonTheme.polish(polish.id))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(selected == polish.id ? SalonTheme.ink : Color.white, lineWidth: selected == polish.id ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(polish.name)
                }
            }
        }
    }

    private var frenchBinding: Binding<Bool> {
        Binding(
            get: { sample.french.enabled },
            set: { model.setFrench(enabled: $0) }
        )
    }

    private var coverageBinding: Binding<Double> {
        Binding(
            get: { sample.french.coverage },
            set: { model.previewFrenchCoverage($0) }
        )
    }

    private var gradientBinding: Binding<Bool> {
        Binding(
            get: { sample.gradient.enabled },
            set: { model.setGradient(enabled: $0) }
        )
    }
}
