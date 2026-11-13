# Vermessa

Vermessa is an offline lipstick wardrobe for iPhone and iPad. You catalog tubes you already own, filter them by finish, undertone, color family, and occasion, and get picks from that private list. It is not a live makeup mirror.

Bundle ID: `com.jackyliu.vermessa`

## Layout

- `Sources/VermessaCore` — collection rules with no SwiftUI: drafts, filters, undertone and occasion scoring, wear recency, JSON persistence, and the starter drawer.
- `Tests/VermessaCoreTests` — `swift test` for those rules.
- `App` — SwiftUI interface. Optional tube or swatch photos stay on device.
- `AppStore` — listing copy, name search, icon, five screenshots, and a small privacy site.

## App Store art

`AppStore/render_art.py` scales the approved icon and the three studio portraits. It expects these files:

- `/workspace/beauty-assets/vermessa/icon.jpg`
- `/workspace/beauty-assets/vermessa/hero-merlot.jpg`
- `/workspace/beauty-assets/vermessa/nude-pink.jpg`
- `/workspace/beauty-assets/vermessa/coral.jpg`

It writes a 1024 RGB icon, every AppIcon slot, and exactly five 1206×2622 screenshots in `AppStore/screenshots/1206x2622/`.

## Tests

```sh
cd Vermessa
swift test
```

The app target needs Xcode. This repository’s core package does not.

## First launch

An empty install receives a sample drawer (owned shades plus a short wishlist) and a few past wear dates, so the picks and the worn log are not blank. Clearing the drawer later does not restore the samples.
