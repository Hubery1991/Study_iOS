import SwiftUI

final class MirrorModel: ObservableObject {
    @Published var recipe: MakeupRecipe
    @Published var activeLookID: String?
    @Published var region: MakeupRegion = .lipstick
    @Published var compareOn = false
    @Published var comparePosition = 0.5
    @Published var document: MirrorDocument
    @Published var banner: String?
    @Published var showSave = false
    @Published var draftName = ""
    @Published var showSuggest = false
    @Published var showFavorites = false
    @Published var showAbout = false

    init() {
        let loaded = DocumentStore.load()
        document = loaded
        recipe = loaded.lastRecipe
        activeLookID = loaded.lastLookID
    }

    var intensity: Double {
        recipe.setting(for: region).intensity
    }

    var regionEnabled: Bool {
        recipe.setting(for: region).enabled
    }

    var selectedShade: Shade? {
        ShadeCatalog.shade(id: recipe.setting(for: region).shadeID)
    }

    func apply(look: Look) {
        recipe = look.recipe
        activeLookID = look.id
        region = .lipstick
        persist()
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func select(shade: Shade) {
        var setting = recipe.setting(for: shade.region)
        setting.shadeID = shade.id
        setting.enabled = true
        if setting.intensity < 0.35 { setting.intensity = 0.62 }
        recipe = recipe.updating(shade.region, setting)
        region = shade.region
        activeLookID = nil
        persist()
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func setIntensity(_ value: Double, commit: Bool) {
        var setting = recipe.setting(for: region)
        setting.intensity = min(1, max(0, value))
        setting.enabled = setting.intensity > 0.02
        recipe = recipe.updating(region, setting)
        activeLookID = nil
        if commit { persist() }
    }

    func setRegionEnabled(_ enabled: Bool) {
        var setting = recipe.setting(for: region)
        setting.enabled = enabled
        if enabled && setting.intensity < 0.2 { setting.intensity = 0.55 }
        recipe = recipe.updating(region, setting)
        activeLookID = nil
        persist()
    }

    func applySuggestion(shape: FaceShape, tone: SkinTone) {
        recipe = SuggestionEngine.tunedRecipe(shape: shape, tone: tone)
        activeLookID = SuggestionEngine.lookID(shape: shape, tone: tone)
        persist()
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func applyFavorite(_ saved: SavedLook) {
        recipe = saved.recipe
        activeLookID = CuratedLooks.all.first { $0.recipe == saved.recipe }?.id
        persist()
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func beginSave() {
        if let id = activeLookID, let look = CuratedLooks.look(id: id) {
            draftName = look.name
        } else if let shade = selectedShade {
            draftName = shade.name
        } else {
            draftName = "My look"
        }
        showSave = true
    }

    func commitSave() {
        document.save(SavedLook(name: draftName, recipe: recipe))
        persist()
        showSave = false
        banner = "Saved to favorites"
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func deleteFavorites(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard document.favorites.indices.contains(index) else { continue }
            document.remove(id: document.favorites[index].id)
        }
        persist()
    }

    func renameFavorite(id: UUID, to name: String) {
        document.rename(id: id, to: name)
        persist()
    }

    func deleteAllFavorites() {
        document.favorites = []
        persist()
    }

    func setHaptics(_ enabled: Bool) {
        document.preferences.hapticsEnabled = enabled
        persist()
    }

    func dismissCoach() {
        document.preferences.hasSeenCoach = true
        persist()
    }

    func toggleCompare() {
        compareOn.toggle()
        if compareOn && (comparePosition < 0.08 || comparePosition > 0.92) {
            comparePosition = 0.5
        }
        Haptics.tap(enabled: document.preferences.hapticsEnabled)
    }

    func persist() {
        document.lastRecipe = recipe
        document.lastLookID = activeLookID
        DocumentStore.save(document)
    }
}
