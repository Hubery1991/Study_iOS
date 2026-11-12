# Mallowcrate

Mallowcrate is a cozy crate-pushing puzzle for iPhone and iPad. Mallow, a round marshmallow courier, nudges chunky honey crates onto daisy pads. Thirty-six original levels, stars, undo, and a move counter. The art is drawn in SwiftUI. Nothing is downloaded, and nothing is collected.

Suggested bundle ID: `com.jackyliu.mallowcrate`

The app target is iOS 16 or later, iPhone and iPad, Swift and SwiftUI, with no third-party packages.

## Build

1. Open `Mallowcrate.xcodeproj` in Xcode 15 or later.
2. Select the Mallowcrate target, then Signing & Capabilities, and choose your team. The bundle ID in the project is `com.jackyliu.mallowcrate`. Change it if that ID is already taken on your account.
3. Pick an iPhone or iPad simulator on iOS 16 or later, or a device, and run.
4. Archive with the Release configuration for App Store Connect. Export compliance is already answered in `App/Info.plist` (`ITSAppUsesNonExemptEncryption` is false).

iPhone stays in portrait. iPad supports portrait and upside down. The game is full screen.

## Rules tests

The pushing rules live in `Sources/MallowcrateCore` and do not depend on SwiftUI. On a Mac or a Linux machine with Swift:

```bash
cd Mallowcrate
swift test
```

That suite replays an optimal solution for every level, checks illegal pushes, undo, stars, and the local save format. This repository was checked that way with Swift 6.2: 8 tests, 0 failures.

`xcodebuild` was not run here. This environment has no Xcode and no iOS Simulator, so the app target itself was not compiled. The SwiftUI sources are the shipping UI; the package tests cover the rules those screens call.

## Levels

There are 36 handcrafted levels, six worlds of six. Difficulty climbs from 1 step to a 30-step optimum.

`AppStore/solve_levels.py` is a breadth-first solver over the same rules: one step at a time, push a single crate, no pulling. It refuses a push onto a square a lone crate could never bring to a daisy, and it refuses permanent freezes. Every catalog `par` is the length of that optimal solution. `AppStore/SOLUTIONS.md` lists the lengths. `swift test` replays those move strings through the Swift engine, so the solver and the app agree.

Regenerate the catalog after a layout edit:

```bash
python3 AppStore/solve_levels.py
```

## App Store kit

`AppStore/` is the submission kit.

- `APP_STORE_LISTING.md` — name, subtitle, promotional text, description, keywords, category, age-rating answers, URLs, App Privacy (Data Not Collected), and review notes.
- `NAME_UNIQUENESS.md` — iTunes Search API evidence. Mallowcrate had `resultCount: 0` on the US, UK, Japan, and China storefronts (and several others) on November 10, 2026.
- `icon/approved-source.jpg` — the approved candy-crate artwork. `icon/AppIcon-1024.png` is that file as a 1024×1024 RGB PNG with no alpha. The same pixels fill `App/Assets.xcassets/AppIcon.appiconset`, plus the website favicon.
- `screenshots/iphone-1206/` — five marketing shots at 1206×2622, the source size. The same compositions are in `iphone-6.9` (1320×2868), `iphone-6.7` (1284×2778), `iphone-6.5` (1242×2688), and `ipad-13` (2064×2752, adapted so the phone is not stretched).
- `website/` — `index.html`, `privacy.html`, `terms.html`, and `site.css`. No external assets. Cross-linked and readable on a phone.

### Screenshots

Each shot is the game UI inside an iPhone bezel, with a headline and a one-line subhead on a coral-to-magenta background. `AppStore/render_art.py` draws the UI from the same palette, copy, and level maps as the SwiftUI screens, then frames it. They are not captures from an iOS Simulator, because none is available in this environment. The 1206×2622 set is the master. Regenerate with:

```bash
python3 AppStore/render_art.py
```

### Suggested pages

After GitHub Pages is enabled for this repository from the root of the default branch:

- Support: `https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/`
- Privacy: `https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/privacy.html`
- Terms: `https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/terms.html`

The same policy and terms are inside the app, under About.

## App Store Connect checklist

- [ ] Apple Developer Program membership is active.
- [ ] Create the App Store Connect record with bundle ID `com.jackyliu.mallowcrate` (or your replacement) and SKU `mallowcrate-ios`.
- [ ] Set the signing team, archive Release, and upload the build.
- [ ] Confirm the 1024 marketing icon uploaded with the build.
- [ ] Paste the name, subtitle, promotional text, description, and keywords from `AppStore/APP_STORE_LISTING.md`.
- [ ] Category: Games. Subcategory: Puzzle.
- [ ] Upload the five 1206×2622 screenshots from `AppStore/screenshots/iphone-1206/`, plus the matching sets in `iphone-6.9`, `iphone-6.7`, `iphone-6.5`, and `ipad-13`.
- [ ] Age rating: answer from the table in the listing. Expect 4+. Do not enroll in Made for Kids.
- [ ] Privacy Policy URL: the `privacy.html` page above, once Pages is on.
- [ ] Support URL: the website index above.
- [ ] App Privacy: Data Not Collected. Tracking off.
- [ ] Price: Free. No in-app purchases. No ads.
- [ ] Review notes: paste the testing steps from the listing. No demo account.
- [ ] Export compliance: already declared as exempt in Info.plist.

## Privacy

No account, no ads, no analytics, no tracking, no purchases, and no network is required to play. Progress and the two settings switches stay in UserDefaults on the device. `App/PrivacyInfo.xcprivacy` declares no collected data types.
