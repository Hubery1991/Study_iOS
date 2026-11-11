import SwiftUI

struct ControlDeck: View {
    @ObservedObject var model: MirrorModel
    var studio: Bool
    var onCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            lookRow
            regionRow
            shadeRow
            intensityRow
            actionRow
        }
        .padding(16)
    }

    private var lookRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Looks")
                .font(Theme.sans(12, weight: .semibold))
                .foregroundStyle(Theme.plum.opacity(0.62))
                .textCase(.uppercase)
                .tracking(0.8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CuratedLooks.all) { look in
                        Button {
                            model.apply(look: look)
                        } label: {
                            Text(look.chip)
                                .font(Theme.sans(15, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(model.activeLookID == look.id ? Color.white : Theme.plum)
                                .background(
                                    Capsule().fill(model.activeLookID == look.id ? Theme.rose : Color.white)
                                )
                                .overlay(
                                    Capsule().stroke(model.activeLookID == look.id ? Theme.rose : Theme.line, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(look.name) look")
                    }
                }
            }
        }
    }

    private var regionRow: some View {
        HStack(spacing: 6) {
            ForEach(MakeupRegion.allCases, id: \.self) { region in
                Button {
                    model.region = region
                } label: {
                    Text(region.chip)
                        .font(Theme.sans(13, weight: model.region == region ? .bold : .medium))
                        .foregroundStyle(model.region == region ? Theme.plum : Theme.plum.opacity(0.55))
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(model.region == region ? Theme.gold : Color.clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var shadeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.selectedShade?.name ?? "Shade")
                    .font(Theme.serif(20, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(model.selectedShade?.finish.rawValue.capitalized ?? "")
                    .font(Theme.sans(12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShadeCatalog.shades(for: model.region)) { shade in
                        let selected = model.recipe.setting(for: model.region).shadeID == shade.id
                        Button {
                            model.select(shade: shade)
                        } label: {
                            Circle()
                                .fill(shade.color.swiftUI)
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Circle().stroke(selected ? Theme.gold : Color.white, lineWidth: selected ? 3 : 2)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(shade.name) \(model.region.title)")
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
    }

    private var intensityRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Intensity")
                    .font(Theme.sans(14, weight: .semibold))
                    .foregroundStyle(Theme.plum)
                Spacer()
                Toggle("On", isOn: Binding(
                    get: { model.regionEnabled },
                    set: { model.setRegionEnabled($0) }
                ))
                .labelsHidden()
                .tint(Theme.rose)
                .accessibilityLabel("Show \(model.region.title)")
                Text("\(Int((model.intensity * 100).rounded()))%")
                    .font(Theme.sans(14, weight: .bold))
                    .foregroundStyle(Theme.rose)
                    .frame(width: 44, alignment: .trailing)
            }
            Slider(
                value: Binding(
                    get: { model.intensity },
                    set: { model.setIntensity($0, commit: false) }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing { model.persist() }
                }
            )
            .tint(Theme.rose)
            .accessibilityLabel("Intensity")
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            deckButton(
                title: model.compareOn ? "Comparing" : "Compare",
                system: "rectangle.split.2x1",
                active: model.compareOn
            ) {
                model.toggleCompare()
            }
            deckButton(title: "Save", system: "heart", active: false) {
                model.beginSave()
            }
            deckButton(title: studio ? "No camera" : "Capture", system: "camera", active: false) {
                onCapture()
            }
        }
    }

    private func deckButton(title: String, system: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: system)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(Theme.sans(12, weight: .semibold))
            }
            .foregroundStyle(active ? Color.white : Theme.plum)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(active ? Theme.rose : Theme.champagne.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }
}
