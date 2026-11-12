# Quillisse App Store listing

English copy for App Store Connect. Counts were checked against the limits below.

## Name

Quillisse

## Subtitle (30 characters max)

A daily edit from your closet

(29 characters)

## Promotional text (170 characters max)

Photograph the clothes you own, tag them, and get a full look for the occasion and the weather. A journal keeps you from repeating it too soon. Nothing is uploaded.

(164 characters)

## Description (4000 characters max)

Quillisse is a closet you keep yourself.

Photograph a shirt, a dress, a pair of shoes. Or choose a picture you already took. Tag the piece: top, bottom, dress, outerwear, shoes, or accessory; a color; a season; casual, smart, or formal. The photo is copied into the app and stays there.

Each morning, pick the occasion. Work, casual, a date, the weekend, or formal. Pick the weather, too: hot, warm, mild, cool, cold, or wet, and whether it is raining. Quillisse assembles a complete look from what you own. A dress can stand in for a top and a bottom. Shoes are preferred. A coat is preferred when you said it is cold, and left off when you said it is hot.

Wear this today writes the look on the calendar. For the next week, that same combination is ranked lower, so you are not handed yesterday’s outfit again. The window can be from three days to three weeks. Favorites keep a look you want back. Atelier lets you build one by hand, piece by piece, and wear that instead.

A sample closet is packed for the first launch, so the day is not empty. Remove it in About when your own pieces are enough. Your photographs are not part of the sample.

Weather does not need an account and does not need a network. The manual choice is the one the closet uses. If you turn on Apple Weather, the app asks for location, requests today’s conditions, and keeps only a band, a rain flag, and a short note. The place is not saved. If you deny location, or you are offline, Quillisse says so and keeps the choice you set.

What you will find:

- A closet of tops, bottoms, dresses, outerwear, shoes, and accessories
- Tags for color, season, formality, and weight
- A suggestion for work, casual, date, weekend, or formal
- A weather and season choice that works offline
- Optional Apple Weather, with a clear fallback
- Wear this today, and a journal of what you wore
- A repeat window so a recent look ranks lower
- Favorites
- Atelier, to build a look by hand
- A sample closet you can remove
- Haptics you can turn off
- The privacy policy and the terms, readable in the app

Quillisse has no account, no ads, no tracking, and no purchases. If you deny the camera, you can still choose a photo or use the sample closet. If you deny Photos, you can still use the camera. If you deny both, the closet you already have still suggests looks.

A suggestion is a sorting of your clothes. It is not a stylist, not a dress code, and not a shopping list.

## Keywords (100 characters max)

wardrobe,outfit,closet,clothes,weather,calendar,style,daily,offline,looks

(73 characters, including commas. The app name is not repeated.)

## Category

- Primary: Lifestyle
- Secondary: Photo & Video

## Age rating

Suggested rating: 4+

| Question | Answer |
|---|---|
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Prolonged graphic or sadistic realistic violence | None |
| Profanity or crude humor | None |
| Mature or suggestive themes | None |
| Horror or fear themes | None |
| Medical or treatment information | None |
| Alcohol, tobacco, or drug use or references | None |
| Simulated gambling | None |
| Sexual content or nudity | None. Clothing photographs are of garments. Marketing portraits are modest editorial portraits. |
| Graphic sexual content and nudity | None |
| Contests | None |
| Unrestricted web access | No. About can open this app’s own privacy page, terms page, and project page. It does not browse the open web. |
| Gambling | No |
| Made for Kids (the Kids category) | No. The app is for a general audience and is not enrolled in Made for Kids. |
| User-generated content | No. Closet photos and the journal stay on the device. There is no public profile. |
| Messaging and chat | No |
| Advertising | No |

## URLs

Host the site in `AppStore/website/` with GitHub Pages from the repository root, then use:

- Support URL: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/`
- Marketing URL: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/`
- Privacy Policy URL: `https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/privacy.html`

The same privacy policy and terms are included in the app, so they can be read with no network.

Until Pages is enabled, a working support contact is the repository issue list: `https://github.com/Hubery1991/Study_iOS/issues`

## App Privacy

Data Not Collected.

- No data is collected by the developer
- No data is used for tracking
- Tracking: No
- Identifiers, contact info, purchases, usage data, diagnostics, photos, and audio: not collected
- Privacy Nutrition Label: Data Not Collected
- The privacy manifest (`App/PrivacyInfo.xcprivacy`) declares no tracking and no collected data types

The camera and the photo library are used only on device to catalog the user’s own clothes. Pictures are stored in the app container. A photo is written to the Photos library only when the user taps Save to Photos. Nothing is uploaded to a developer server.

Location is used only if the user turns on Apple Weather. The app asks WeatherKit for conditions and does not store coordinates. If location is denied or the device is offline, the manual weather choice is used. That choice is a label such as “mild” or “rain,” kept in the local closet file.

## Review notes

Quillisse is a complete offline closet. No sign-in, no purchase, and no network is required for suggestions.

The camera and Photos are used only to add pictures of the user’s own clothes. Those pictures stay in the app container. They are not uploaded. Save to Photos writes a copy only when the reviewer taps that button.

Location is optional. The default weather is a manual picker. Apple Weather is a switch in that sheet. If the reviewer denies location, or the device is offline, the sheet explains that and the manual band is what the closet uses. Enabling Apple Weather in a signed build needs the WeatherKit capability on the App ID. Without it, the call fails and the app falls back to the manual choice. The rest of the app does not depend on it.

How to test:

1. Launch the app. A sample closet is already there, with a few journal days. Today opens on Work. Change the occasion. The suggested pieces change. Tap Wear this today. The day is logged.
2. Tap Another look. A different combination appears. The heart saves a favorite. Favorites are listed under the suggestion and can be worn again.
3. Open the weather control. Choose Cold, then go back. The suggestion prefers a coat. Choose Hot. The coat drops off. Turn Rain on. A layer ranks higher. Leave Apple Weather off to confirm the app never asks for location.
4. If you turn Apple Weather on, allow location. A band replaces the manual one, or the sheet explains that location is off or the weather could not be reached. Deny location in Settings and open the sheet again. The manual controls still work.
5. Closet shows the pieces. Filter by category. Tap a piece and change its color, season, or formality. Save.
6. Tap + and Take a photo. Allow the camera. The new piece opens in the editor. Deny the camera instead: the alert explains Settings, and Choose from Photos still works. Deny Photos: the alert explains that, and the camera path still works. Pictures are not uploaded.
7. On a piece, tap Save a copy to Photos. Allow adding. The picture is saved by the system. Quillisse does not upload it. If adding is denied, the editor says so and the closet copy remains.
8. Atelier: choose a top and a bottom, or a dress. A dress together with trousers shows a blocking note. Wear this today logs the hand-built look.
9. Journal shows the month. Days with a log have a mark. Tap one to see the pieces. Remove this day clears it. Wear the same look again within the repeat window and the next suggestion for that occasion prefers something else. The window is in About.
10. About has the privacy policy and the terms inside the app, the haptics switch, and Remove the sample closet. The support link is optional and needs a network only if the reviewer taps it.

iPhone is portrait. iPad is portrait, including upside down. There is no account and nothing to restore.

## Screenshots to upload

Five images, one size only, in `AppStore/screenshots/iphone-1206x2622/`. Each file is exactly 1206 × 2622. Each one places an original generated portrait with the app’s Today, Closet, Journal, weather, or Atelier screen drawn inside an iPhone bezel, plus a short headline that sits above the phone. The controls match the app: occasion chips, Wear this today, closet filters, the month grid, the weather bands, and the Atelier slots.

| Folder | Pixel size | App Store slot |
| --- | --- | --- |
| `iphone-1206x2622` | 1206 × 2622 | iPhone 6.3-inch (1206 × 2622) |

Order: 01 today’s look, 02 the closet, 03 the journal, 04 weather, 05 the atelier.

The portraits are original generated images made for this app, not photographs of real people. Copies are in `AppStore/models/` (`model-office.jpg`, `model-weekend.jpg`, `model-winter.jpg`, `model-evening.jpg`).

The 1024 × 1024 marketing icon is `AppStore/icon/AppIcon-1024.png` and is also in the Xcode asset catalog. It is RGB with no alpha channel.

## Submission checklist

- [ ] Apple Developer Program membership is active.
- [ ] Create the App Store Connect record with bundle ID `com.jackyliu.quillisse` and SKU `quillisse-ios`.
- [ ] Set the signing team, archive Release, and upload the build.
- [ ] Confirm the 1024 marketing icon uploaded with the build.
- [ ] Paste the name, subtitle, promotional text, description, and keywords from this file.
- [ ] Category: Lifestyle. Secondary: Photo & Video.
- [ ] Upload the five 1206 × 2622 screenshots from `AppStore/screenshots/iphone-1206x2622/`.
- [ ] Age rating: answer from the table above. Expect 4+. Do not enroll in Made for Kids.
- [ ] Privacy Policy URL: the `privacy.html` page above, once Pages is on.
- [ ] Support URL: the website index above.
- [ ] App Privacy: Data Not Collected. Tracking off. Camera, Photos, and optional location are permissions, not collected data.
- [ ] Price: Free. No in-app purchases. No ads.
- [ ] Review notes: paste the testing steps above. No demo account. Explain that closet photos stay on device, and that weather works with the manual picker if location is denied.
- [ ] Optional: add the WeatherKit capability before relying on Apple Weather. The manual picker already works without it.
- [ ] Export compliance: already declared as exempt in Info.plist.

## Other Connect fields

- Bundle ID: `com.jackyliu.quillisse`
- SKU: `quillisse-ios`
- Copyright: 2026 Jacky Liu
- Price: Free
- Primary language: English (U.S.)
- Version: 1.0.0
- Content rights: the app does not use third-party content. Marketing portraits are original generated images made for this app. Seed garment drawings are original illustrations.
- Encryption: `ITSAppUsesNonExemptEncryption` is false. The app does not use encryption beyond what the system provides. The only optional network call is WeatherKit, which uses the system.
