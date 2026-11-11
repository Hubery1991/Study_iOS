# Sheenlisse

Sheenlisse is a live makeup mirror for iPhone and iPad. The front camera shows your face, and lipstick, blush, eyeshadow, eyeliner, and brows are drawn on it while you look. Four looks, intensity, a before-and-after swipe, Photos capture, saved looks, and a face-shape and skin-tone suggestion. Everything stays on the device.

Suggested bundle ID: `com.jackyliu.sheenlisse`

The app target is iOS 16 or later, iPhone and iPad, Swift and SwiftUI, with no third-party packages. TrueDepth devices use ARKit face tracking. Other devices use Vision face landmarks on the front camera.

## Build

1. Open `Sheenlisse.xcodeproj` in Xcode 15 or later.
2. Select the Sheenlisse target, then Signing & Capabilities, and choose your team. The bundle ID in the project is `com.jackyliu.sheenlisse`. Change it if that ID is already taken on your account.
3. Pick an iPhone or iPad on iOS 16 or later and run. The camera needs a real device for a useful preview. A simulator with no camera opens the studio, where shades and saved looks still work.
4. Archive with the Release configuration for App Store Connect. Export compliance is already answered in `App/Info.plist` (`ITSAppUsesNonExemptEncryption` is false).

iPhone stays in portrait. iPad supports portrait and upside down. The mirror is full screen.

Allow the camera when asked. The usage strings for the camera and for adding a photo to the library are in `App/Info.plist`. If the camera is denied, the app explains how to turn it on in Settings and still lets you browse shades.

## Logic tests

Shade catalogs, blend math, face-shape and skin-tone classification, suggestions, and the favorites file live in `Sources/SheenlisseCore` and do not depend on SwiftUI. On a Mac with Swift:

```bash
cd Sheenlisse
swift test
```

That suite checks blending, the four looks, region geometry, shape and tone bands, the suggestion table, expression adjustments, compare mapping, and the saved-look file. This repository was checked that way with Swift 6.2.1: 23 tests, 0 failures.

`xcodebuild` was not run here. This environment has no Xcode and no iOS Simulator, so the app target itself was not compiled. The SwiftUI sources are the shipping UI. The package tests cover the rules those screens call.

## App Store kit

`AppStore/` is the submission kit.

- `APP_STORE_LISTING.md` — name, subtitle, promotional text, description, keywords, category, age-rating answers, App Privacy (Data Not Collected), review notes, and the submission checklist.
- `NAME_UNIQUENESS.md` — iTunes Search API evidence. Sheenlisse had no exact `trackName` match on the US, UK, Japan, China, Germany, France, Canada, Australia, or South Korea storefronts on November 11, 2026.
- `icon/AppIcon-1024.png` — 1024×1024 RGB marketing icon, no alpha. The full set is wired in `App/Assets.xcassets/AppIcon.appiconset`.
- `models/` — the four original generated portraits used in the screenshots and on the website.
- `screenshots/` — five images each at 1320×2868, 1284×2778, 1242×2688, and iPad 2064×2752.
- `website/` — `index.html`, `privacy.html`, `terms.html`, and `site.css`.

### Screenshots

They were composed by `AppStore/render_art.py` (Pillow). Each one places a portrait inside the mirror’s look chips, shade row, intensity slider, compare divider, or suggestion card, plus a headline. They are not captures from an iOS Simulator, because none is available in this environment. Regenerate with:

```bash
python3 AppStore/render_art.py
```

### Suggested pages

After GitHub Pages is enabled for this repository from the root of the default branch:

- Support: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/`
- Privacy: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/privacy.html`
- Terms: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/terms.html`

The same policy and terms are inside the app, under About.

## Privacy

No account, no ads, no analytics, no tracking, no purchases, and no network is required. The camera is used only for the live preview. Frames and face geometry are not uploaded. A photo is saved only when you tap the shutter, and only to your Photos library. Favorites and the haptics switch stay in a local file. `App/PrivacyInfo.xcprivacy` declares no collected data types.
