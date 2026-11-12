# Quillisse

Quillisse is a daily outfit assistant for iPhone and iPad. Photograph clothes into a closet, tag them, and get a complete look for the occasion and the weather. A journal keeps a recent look from coming back too soon. Favorites and a hand-built atelier are included. Everything stays on the device.

Suggested bundle ID: `com.jackyliu.quillisse`

The app target is iOS 16 or later, iPhone and iPad, Swift and SwiftUI, with no third-party packages. Weather is a manual season and band, so the closet works offline. Apple WeatherKit and location are optional and fall back to that choice when permission is denied or the device is offline.

## Build

1. Open `Quillisse.xcodeproj` in Xcode 15 or later.
2. Select the Quillisse target, then Signing & Capabilities, and choose your team. The bundle ID in the project is `com.jackyliu.quillisse`. Change it if that ID is already taken on your account.
3. Pick an iPhone or iPad on iOS 16 or later and run. A sample closet is created on first launch so Today is not empty.
4. Archive with the Release configuration for App Store Connect. Export compliance is already answered in `App/Info.plist` (`ITSAppUsesNonExemptEncryption` is false).

iPhone stays in portrait. iPad supports portrait and upside down.

Allow the camera when you photograph a piece, and Photos when you choose an existing picture or save a copy. The usage strings are in `App/Info.plist`. If either permission is denied, the app explains how to turn it on in Settings and the rest of the closet still works.

Apple Weather is a switch on the weather sheet. To make that call succeed, add the WeatherKit capability to the App ID. Without it, the request fails and Quillisse keeps the weather you chose. Location is not stored either way.

## Logic tests

The closet model, tags, color harmony, outfit scoring, the repeat window, weather bands, the month grid, and the closet file live in `Sources/QuillisseCore` and do not depend on SwiftUI. On a Mac with Swift:

```bash
cd Quillisse
swift test
```

That suite checks the seed closet, day math, seasons, temperature bands, harmony, work and weekend and formal and cold suggestions, the repeat penalty, builder issues, favorites, and the JSON file. This repository was checked that way with Swift 6.0.3: 21 tests, 0 failures.

`xcodebuild` was not run here. This environment has no Xcode and no iOS Simulator, so the app target itself was not compiled. The SwiftUI sources are the shipping UI. The package tests cover the rules those screens call.

## App Store kit

`AppStore/` is the submission kit.

- `APP_STORE_LISTING.md` — name, subtitle, promotional text, description, keywords, category, age-rating answers, App Privacy (Data Not Collected), review notes, and the submission checklist.
- `NAME_UNIQUENESS.md` — iTunes Search API evidence. Quillisse had no exact `trackName` match on the US, UK, Japan, China, Germany, France, Canada, Australia, or South Korea storefronts on November 11, 2026.
- `icon/AppIcon-1024.png` — 1024×1024 RGB marketing icon, no alpha. The full set is wired in `App/Assets.xcassets/AppIcon.appiconset`.
- `models/` — the four approved portraits used in the screenshots and on the website: office, weekend, winter, and evening.
- `garments/` — the illustrated stills that also ship in the asset catalog as the sample closet.
- `screenshots/iphone-1206x2622/` — five images, each exactly 1206×2622.
- `website/` — `index.html`, `privacy.html`, `terms.html`, and `site.css`.

### Screenshots

They were composed by `AppStore/render_art.py` (Pillow). Each one is 1206×2622 and places one approved portrait with the Today suggestion, the closet grid, the journal, the weather sheet, or the Atelier inside an iPhone bezel, plus a headline. They are not captures from an iOS Simulator, because none is available in this environment. Regenerate with:

```bash
python3 AppStore/render_art.py
```

### Suggested pages

After GitHub Pages is enabled for this repository from the root of the default branch:

- Support: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/`
- Privacy: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/privacy.html`
- Terms: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/terms.html`

The same policy and terms are inside the app, under About.

## Privacy

No account, no ads, no analytics, no tracking, and no purchases. Closet photos stay in the app container unless you tap Save to Photos. Weather is chosen in the app. Location is used only for optional Apple Weather and is not stored. `App/PrivacyInfo.xcprivacy` declares no collected data types.
