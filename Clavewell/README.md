# Clavewell

Clavewell is an original puzzle for iPhone and iPad. You drop colored motes into a well. Three or more of the same color that touch along an edge ring and clear, and a chain falls into place if the well settles into another group. It is a complete offline game: three modes, local high scores, sound and haptics you can turn off, a how-to-play guide, and an About screen with the privacy policy and terms of use.

The older Objective-C project in `WeChatStudy/` is a separate demo and is not part of this game.

## What's in this folder

| Path | What it is |
| --- | --- |
| `Clavewell.xcodeproj` | The Xcode project. Open this. |
| `App/` | SwiftUI app: menus, the well, sound, haptics, settings, legal text. |
| `Sources/ClavewellCore/` | Game rules, scoring, and the on-device scorebook. No UI. |
| `Tests/ClavewellCoreTests/` | Tests for matches, chains, sparks, rising rows, the clock, and saved scores. |
| `Package.swift` | Lets `swift test` build the rules without Xcode. The app target compiles those same files itself and does not depend on a package product. |
| `AppStore/` | Icon, screenshots, listing copy, name-search notes, and the support website. |

There are no third-party libraries, ads, purchases, accounts, or network calls.

## Name

**Clavewell** had no exact match on the App Store in the searches recorded in [`AppStore/NAME_UNIQUENESS.md`](AppStore/NAME_UNIQUENESS.md). On November 10, 2026 the iTunes Search API returned zero software results for that term on 18 storefronts, including the United States, the United Kingdom, Japan, and China.

## Suggested bundle ID

`com.jackyliu.clavewell`

Use that unless your Apple Developer account already has it, or you prefer your own reverse-DNS prefix. Change it in the target's Signing & Capabilities tab before you archive. The project does not set a development team; Xcode will ask you to pick one.

## Requirements

- Xcode 15 or later, with an iOS 16 or later SDK
- iPhone or iPad, iOS 16 or later
- Portrait. iPad also allows upside down.
- No other tools. Sound is synthesized with AVAudioEngine. Art is SwiftUI drawing and the app icon in the asset catalog.

## Build and run

1. Open `Clavewell.xcodeproj`.
2. Select the Clavewell target, then Signing & Capabilities, and choose your Team.
3. Choose an iPhone or iPad simulator on iOS 16 or later.
4. Run.

To archive for the store, choose Any iOS Device, then Product → Archive, then Distribute App → App Store Connect.

The first launch shows How to Play. After that, the home screen offers Play, How to Play, Records, Settings, and About. Play opens Cadence, Stillwater, or Flare.

- **Cadence** raises a new row and speeds up as the run lasts. It ends if a rise would pass the rim.
- **Stillwater** never raises a row. It ends when every column is blocked.
- **Flare** lasts 75 seconds. Clears return a little time, up to 2.5 seconds on one drop.

Finished runs are stored on the device with UserDefaults. Settings can turn off sound and haptics, turn on color patterns, turn off the landing guide, and reset records after a confirmation.

## Logic tests

From this directory, with a Swift 5.9 or later toolchain:

```sh
swift test
```

That builds `ClavewellCore` and runs the rules tests. It does not compile the SwiftUI app. On November 10, 2026 those tests were run here with Swift 6.2 on Linux: 18 tests, 0 failures. They cover orthogonal matches (diagonals do not count), chains, two groups in one step, sparks, rejected drops into a full column, rising rows, overflow, the flare clock and its bonus, fair rise rows, the color bag, random play, and the scorebook.

## What was not compiled here

This environment is Linux. It has no Xcode and no iOS Simulator, so the app target was not built with `xcodebuild` and the screenshots were not captured from a simulator. The rules were compiled and tested with `swift test`, as above. The SwiftUI code targets iOS 16 APIs (NavigationStack, no iOS 17-only modifiers).

## App Store kit

Everything for submission lives in `AppStore/`. The paste-ready field values are in [`AppStore/APP_STORE_LISTING.md`](AppStore/APP_STORE_LISTING.md).

| Piece | Where |
| --- | --- |
| App icon, including 1024×1024 RGB with no alpha | `App/Assets.xcassets/AppIcon.appiconset` and `AppStore/icon/AppIcon-1024.png` |
| Screenshots, 5 each | `AppStore/screenshots/iphone-6.9` (1320×2868), `iphone-6.7` (1284×2778), `iphone-6.5` (1242×2688), `ipad-13` (2064×2752) |
| Listing copy | `AppStore/APP_STORE_LISTING.md` |
| Name-search evidence | `AppStore/NAME_UNIQUENESS.md` |
| Support site | `AppStore/website/index.html`, `privacy.html`, `terms.html` |

The screenshots were drawn by `AppStore/render_art.py` from the same colors, copy, and screen structure as the SwiftUI views (home, a Cadence game, a resonance chain, a new-record game over, and Settings with the sound switch). They are faithful layout renders, not device captures. Regenerate them with `python3 AppStore/render_art.py` if you change the layout. Regenerating needs Pillow and the Liberation and Inter fonts used by that script.

### Support and privacy URLs

The HTML site has no external dependencies. Host it with GitHub Pages so the privacy policy URL is public before you submit:

1. On the repository, open Settings → Pages.
2. Deploy from the `master` branch, folder `/` (root).
3. Use these addresses in App Store Connect:
   - Support URL: `https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/`
   - Marketing URL: the same page
   - Privacy Policy URL: `https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/privacy.html`

The app also shows the policy and the terms under About, so a player can read them with no connection. Review will still open the Privacy Policy URL, so turn Pages on before you submit. Until then, the issue list is a working contact: `https://github.com/Hubery1991/Study_iOS/issues`.

## App Store Connect checklist

1. Enroll in the Apple Developer Program if you have not already, and accept the latest agreements in App Store Connect.
2. Turn on GitHub Pages as described above, and open the privacy and terms URLs in a browser to confirm they load.
3. In Xcode, set your Team and confirm the bundle ID. Archive the Release build and upload it with the Organizer or Transporter.
4. In App Store Connect, create the app with the name **Clavewell**, the bundle ID, and the SKU `CLAVEWELL2026` (or another unused SKU).
5. Set the primary category to Games and the secondary category to Puzzle. Price: Free.
6. Paste the subtitle, promotional text, description, and keywords from `AppStore/APP_STORE_LISTING.md`.
7. Enter the support, marketing, and privacy URLs from the table above.
8. Upload the 1024×1024 icon if it is not already inside the archive. Upload the screenshot sets for the 6.9-inch iPhone, the 6.5-inch iPhone (both 1284×2778 and 1242×2688 are accepted sizes; both are included), and the 13-inch iPad.
9. Complete the age-rating questionnaire with the answers in the listing file. Every content item is None or No. The expected rating is 4+.
10. In App Privacy, choose Data Not Collected. Tracking is off.
11. For export compliance, say the app does not use non-exempt encryption. The Info.plist already sets `ITSAppUsesNonExemptEncryption` to false.
12. Paste the review notes from the listing file. They explain how to start a game, where the sound switch is, and that the app never asks for a login.
13. Add the copyright line `2026 Jacky Liu`.
14. Submit for review.

App Privacy answers, the age-rating answers, and the review notes are written out in the listing file so you can follow them field by field.
