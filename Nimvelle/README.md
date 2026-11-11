# Nimvelle

Nimvelle is a skincare routine check-in for iPhone and iPad. You build a morning routine and an evening routine from the steps you actually use, link each step to a product on your shelf, and tick the day off. The month shows what you finished and keeps a streak. The shelf remembers when a jar was opened and the period after opening printed on the pack, and you can note how much is left. Optional progress photos and skin notes stay on the device. Reminders are local and opt-in.

Suggested bundle ID: `com.jackyliu.nimvelle`

The app target is iOS 16 or later, iPhone and iPad, Swift and SwiftUI, with no third-party packages. There is no account, no analytics, and no network use for the routine itself.

Nimvelle is a cosmetic journal. It does not diagnose skin, recommend treatment, or act as a medical device. A period after opening is a maker’s storage guide. A note about dryness or spots is only a memory.

## Build

1. Open `Nimvelle.xcodeproj` in Xcode 15 or later.
2. Select the Nimvelle target, then Signing & Capabilities, and choose your team. The bundle ID in the project is `com.jackyliu.nimvelle`. Change it if that ID is already taken on your account.
3. Pick an iPhone or iPad on iOS 16 or later and run. A sample shelf and a few checked days are created on first launch so Today is not empty. Remove them in About when you want only your own routine.
4. Archive with the Release configuration for App Store Connect. Export compliance is already answered in `App/Info.plist` (`ITSAppUsesNonExemptEncryption` is false).

iPhone stays in portrait. iPad supports portrait and upside down. The interface is light, so the spa palette stays as designed.

The camera and Photos are optional, for progress pictures only. The usage strings are in `App/Info.plist`. If you deny the camera, you can still choose a photo. If you deny Photos, you can still use the camera. If you deny both, the routine, the calendar, the shelf, and notes still work. Notifications are optional and use the system prompt. iOS does not provide an Info.plist usage string for local notifications; Nimvelle explains a denial in About and leaves the rest of the app usable.

## Logic tests

Routines, check-ins, streaks, the month grid, period-after-opening dates, note trends, reminder scheduling, the sample shelf, and the JSON file live in `Sources/NimvelleCore` and do not depend on SwiftUI. On a Mac with Swift:

```bash
cd Nimvelle
swift test
```

That suite checks day and month arithmetic, the open-jar window (including the 30-day warning and the last day), inactive steps, partial days, the streak while today is still open, the longest streak, the November 2026 grid, trend averages, reminder rules, the sample story, archive round-trip, and removing the sample without deleting a product you added. This repository was checked with Swift 6.0.3: 11 test cases, 0 failures.

`xcodebuild` was not run here. This environment has no Xcode and no iOS Simulator, so the app target itself was not compiled. The SwiftUI sources are the shipping UI. The package tests cover the rules those screens call.

## App Store kit

`AppStore/` is the submission kit.

- `APP_STORE_LISTING.md` — name, subtitle, promotional text, description, keywords, category, age-rating answers, App Privacy (Data Not Collected), review notes, and the submission checklist.
- `NAME_UNIQUENESS.md` — iTunes Search API evidence. Nimvelle had no results on the US, UK, Japan, China, Germany, France, Canada, Australia, or South Korea storefronts on November 11, 2026.
- `icon/AppIcon-1024.png` — 1024×1024 RGB marketing icon, no alpha. The full set is wired in `App/Assets.xcassets/AppIcon.appiconset`.
- `models/` — the four original generated portraits used in the screenshots and on the website.
- `screenshots/` — five images each at 1320×2868, 1284×2778, 1242×2688, and iPad 2064×2752.
- `website/` — `index.html`, `privacy.html`, `terms.html`, and `site.css`.

### Screenshots

They were composed by `AppStore/render_art.py` (Pillow). Each one places a portrait with Today’s checklist, the month, the shelf, the progress compare, or the notes chart, plus a headline. They are not captures from an iOS Simulator, because none is available in this environment. The controls and the sample numbers match the app: a 5-day streak, morning 3 of 5, Veil Cream with 10 days left, Night Repair Cream 40 days past its open-jar window. Regenerate with:

```bash
python3 AppStore/render_art.py
```

### Suggested pages

After GitHub Pages is enabled for this repository from the root of the default branch:

- Support: `https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/`
- Privacy: `https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/privacy.html`
- Terms: `https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/terms.html`

The same policy and terms are inside the app, under About.

## Privacy

No account, no ads, no analytics, no tracking, and no purchases. Progress photos stay in the app container unless you tap Save a copy to Photos. Reminders are scheduled on the device. `App/PrivacyInfo.xcprivacy` declares no collected data types.
