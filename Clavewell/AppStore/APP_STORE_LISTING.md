# App Store listing — Clavewell

Copy is in English and ready to paste into App Store Connect. Character counts were checked against Apple's limits.

## Identity

| Field | Value |
| --- | --- |
| Name | Clavewell |
| Subtitle | Match motes. Clear the well. |
| Subtitle length | 28 (limit 30) |
| Bundle ID suggestion | `com.jackyliu.clavewell` |
| SKU suggestion | `CLAVEWELL2026` |
| Primary category | Games |
| Secondary category | Puzzle |
| Primary language | English (U.S.) |
| Price | Free |
| Version | 1.0.0 |
| Copyright | 2026 Jacky Liu |
| Age rating | 4+ |

## Promotional text

Limit 170. This draft is 150 characters.

Drop motes into a quiet well. Match three of a color, chain the resonance, and stay ahead of the rising dark. Three modes. Scores stay on your device.

## Description

Limit 4000.

Clavewell is a puzzle about light in a well.

A mote drops when you tap a column. It falls to the lowest open cell. Three or more motes of the same color that touch along an edge ring, clear, and pull everything above them down. If that fall makes another group, it rings too. Each step in the chain multiplies the points. Every 12th mote is a spark: it bursts the colors touching it, and the well settles again.

There are three ways to play.

Cadence. A new row climbs out of the deep every few drops. The pace quickens the longer you last. The run ends if a rise would push a mote past the rim.

Stillwater. Nothing rises. Clear space and chase a score until no column can take another mote.

Flare. You have 75 seconds. Each mote you clear returns a little time.

Your five best finished runs in each well are kept on this device, along with a lifetime count of motes cleared and your best chain. Sound, haptics, color patterns, and a landing guide can be changed in Settings. Patterns put a distinct shape on every mote, so a match does not depend on color alone.

Clavewell is original. The artwork is drawn in the app. The tones are synthesized on your device when you play. There is no account, no advertising, no purchase, and no network connection. You can play with the phone in airplane mode.

Open About for the privacy policy and the terms of use. Both are also inside the app, so you do not need a connection to read them.

## Keywords

Limit 100. This list is 83 characters. Do not repeat the app name. Apple separates keywords with commas, and spaces are included in the count, so this list has none.

```
puzzle,matching,color,offline,cascade,arcade,logic,combo,casual,motes,brain,columns
```

## URLs

Turn on GitHub Pages for this repository from the `master` branch at the repository root (folder `/`). After that, these addresses serve the pages in `Clavewell/AppStore/website/`.

| Field | URL |
| --- | --- |
| Support URL | https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/ |
| Marketing URL | https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/ |
| Privacy Policy URL | https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/privacy.html |
| Terms of Use (optional marketing link) | https://hubery1991.github.io/Study_iOS/Clavewell/AppStore/website/terms.html |

Until Pages is enabled, a working support contact is the repository issue list: https://github.com/Hubery1991/Study_iOS/issues

The privacy policy URL must be live before you submit. Apple's review opens it. The same policy is also written into the app under About, so the game itself does not depend on the website.

## Age rating questionnaire

Answer every item **None** or **No**. Clavewell has no violence, no fear content, no profanity, no sexual content, no nudity, no alcohol, tobacco, or drugs, no gambling, no contests, no unrestricted web access, no user-generated content, and no mature themes. It does not offer in-app purchases or advertising. Recommended rating: **4+**.

| Topic | Answer |
| --- | --- |
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Prolonged graphic or sadistic violence | None |
| Sexual content or nudity | None |
| Profanity or crude humor | None |
| Alcohol, tobacco, or drug use | None |
| Mature or suggestive themes | None |
| Horror or fear themes | None |
| Gambling or contests | None |
| Unrestricted web access | No |
| User-generated content | No |
| Messaging or chat | No |
| Medical or treatment information | None |
| Made for kids | No (general audience; the app does not collect data) |

## App Privacy

**Data Not Collected.**

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | No |
| Tracking | No. The app does not track users and does not use the advertising identifier. |
| Data types | None |
| Privacy nutrition label | Data Not Collected |
| Privacy manifest | `App/PrivacyInfo.xcprivacy` declares no tracking, no collected data types, and no required-reason API access |

High scores and settings are stored in UserDefaults on the device. They are not transmitted. UserDefaults is not a required-reason API.

## Encryption

`ITSAppUsesNonExemptEncryption` is false. In App Store Connect, answer that the app does not use non-exempt encryption. The game does not implement its own cryptography.

## Review notes

Clavewell is a complete offline puzzle. No login, no network, no ads, and no purchases.

To play: open the app, tap Play, choose Cadence, Stillwater, or Flare, then tap a column to drop the mote shown as Now. Match three or more of the same color along an edge. A short how-to-play sheet appears the first time the app is opened. It can also be opened from the home screen and from the pause menu.

Sound can be muted from the speaker button on the game screen or from Settings. Haptics, color patterns, and the landing guide are in Settings. Finished runs are saved on the device and listed under Records. Reset records is in Settings and asks for confirmation.

The privacy policy and terms of use are in About, and they match the pages at the Privacy Policy URL and the support site. The app does not request permissions.

Suggested devices to try: iPhone (portrait) and iPad (portrait). The deployment target is iOS 16.

## Screenshots to upload

Five images in each folder under `AppStore/screenshots/`. Upload the set that matches the slot in App Store Connect.

| Folder | Pixel size | App Store slot |
| --- | --- | --- |
| `iphone-6.9` | 1320 × 2868 | 6.9-inch iPhone |
| `iphone-6.7` | 1284 × 2778 | 6.5-inch display (accepted size) |
| `iphone-6.5` | 1242 × 2688 | 6.5-inch display (accepted size) |
| `ipad-13` | 2064 × 2752 | 13-inch iPad |

Order: 01 home, 02 gameplay, 03 resonance, 04 game over with a new record, 05 settings with the sound switch.

The 1024 × 1024 marketing icon is `AppStore/icon/AppIcon-1024.png` and is also in the Xcode asset catalog. It is RGB with no alpha channel.
