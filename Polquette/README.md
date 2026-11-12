# Polquette

Polquette is a nail-design game for iPhone and iPad. An illustrated hand is the canvas: six shapes, a color palette, six finishes, French tips, gradients, and small decorations. Paint one nail or all five. Eight curated looks, undo and redo, a book of saved looks, a daily design chair, and a twelve-chair salon career with star ratings. Everything stays on the device.

Suggested bundle ID: `com.jackyliu.polquette`

The app target is iOS 16 or later, iPhone and iPad, Swift and SwiftUI, with no third-party packages.

## Build

1. Open `Polquette.xcodeproj` in Xcode 15 or later.
2. Select the Polquette target, then Signing & Capabilities, and choose your team. The bundle ID in the project is `com.jackyliu.polquette`. Change it if that ID is already taken on your account.
3. Pick an iPhone or iPad on iOS 16 or later and run. No permission is requested.
4. Archive with the Release configuration for App Store Connect. Export compliance is already answered in `App/Info.plist` (`ITSAppUsesNonExemptEncryption` is false).

iPhone stays in portrait. iPad supports portrait and upside down. On a wide iPad the studio places the hand beside the tools.

## Logic tests

Palette, manicure state, per-nail edits, undo and redo, curated looks, daily chairs, career stars, and the saved-look file live in `Sources/PolquetteCore` and do not depend on SwiftUI. On a Mac with Swift:

```bash
cd Polquette
swift test
```

That suite checks the palette, five-nail edits, clamps, the decoration cap, undo and redo, the eight looks against their chairs, star bands, daily rotation, career unlocks, and the JSON file. This repository was checked that way with Swift 6.2.1: 21 tests, 0 failures.

`xcodebuild` was not run here. This environment has no Xcode and no iOS Simulator, so the app target itself was not compiled. The SwiftUI sources are the shipping UI. The package tests cover the rules those screens call.

## App Store kit

`AppStore/` is the submission kit.

- `APP_STORE_LISTING.md` — name, subtitle, promotional text, description, keywords, category, age-rating answers, App Privacy (Data Not Collected), review notes, and the submission checklist.
- `NAME_UNIQUENESS.md` — iTunes Search API evidence. Polquette had no exact `trackName` match on the US, UK, Japan, China, Germany, France, Canada, Australia, or South Korea storefronts on November 11, 2026.
- `icon/AppIcon-1024.png` — 1024×1024 RGB marketing icon, no alpha, the approved full-bleed artwork. The same image is scaled into `App/Assets.xcassets/AppIcon.appiconset` and into the website favicon and Apple touch icon.
- `models/` — four original generated portraits: cherry red, lavender flowers, gold glitter, and French tips. They are used in the screenshots and on the website.
- `screenshots/iphone-1206x2622/` — five images, each exactly 1206×2622. No other screenshot sizes are included.
- `website/` — `index.html`, `privacy.html`, `terms.html`, `site.css`, `favicon-32.png`, and `apple-touch-icon.png`.

### Screenshots

They were composed by `AppStore/render_art.py` (Pillow). Each one puts a headline and subhead above one of the portraits, then draws the studio, the looks list, or the chair list inside an iPhone frame. They are not captures from an iOS Simulator, because none is available in this environment. Regenerate with:

```bash
python3 AppStore/render_art.py
```

### Suggested pages

After GitHub Pages is enabled for this repository from the root of the default branch:

- Support: `https://hubery1991.github.io/Study_iOS/Polquette/AppStore/website/`
- Privacy: `https://hubery1991.github.io/Study_iOS/Polquette/AppStore/website/privacy.html`
- Terms: `https://hubery1991.github.io/Study_iOS/Polquette/AppStore/website/terms.html`

The same policy and terms are inside the app, under About.

## Privacy

No account, no ads, no analytics, no tracking, no purchases, and no network is required. The app does not ask for the camera or Photos. Saved looks and star ratings stay in a local file. `App/PrivacyInfo.xcprivacy` declares no collected data types.
