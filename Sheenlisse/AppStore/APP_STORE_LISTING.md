# Sheenlisse App Store listing

English copy for App Store Connect. Counts were checked against the limits below.

## Name

Sheenlisse

## Subtitle (30 characters max)

Live makeup in your mirror

(26 characters)

## Promotional text (170 characters max)

Try lipstick, blush, eyeshadow, liner, and brows on your face, live. Four looks, a before-and-after swipe, and every frame stays on your device.

(144 characters)

## Description (4000 characters max)

Sheenlisse is a mirror for color.

The front camera shows your face, and makeup is drawn on it while you look. Try lipstick, blush, eyeshadow, eyeliner, and brows. Change a shade, move the intensity, or tap a whole look. Natural, Evening Glam, Vibrant, and Fresh are the four starting points. You can turn any region off.

A divider slides across the picture. One side is the bare camera. The other side is the color. Tap the shutter and the photo you see is saved to your Photos library. Nothing is uploaded. Save a combination of shades as a favorite and it stays on this iPhone or iPad, ready to apply again.

If the camera can see you, Sheenlisse reads a simple face shape and a skin-tone band and suggests one of the four looks, with a short note about why. You can change the shape or the tone yourself. The suggestion is a starting point. It is not a measurement of you, not a match to a product you can buy, and not advice from a makeup artist.

On a TrueDepth camera, Apple’s face tracking follows you and notices a blink or an open mouth, so liner and shadow ease off when an eye closes and an open mouth keeps the teeth clear. On other devices the same preview uses Vision landmarks on the camera image. Both paths run on the device.

What you will find:

- A live front-camera mirror
- Lipstick, blush, eyeshadow, eyeliner, and brows
- Four one-tap looks: Natural, Evening Glam, Vibrant, and Fresh
- An intensity slider for the region you are editing
- A before-and-after swipe
- Capture to the Photos library, only when you tap the shutter
- Favorites of saved looks, kept on the device
- A face-shape and skin-tone suggestion you can override
- Haptics you can turn off
- The privacy policy and the terms, readable in the app

Sheenlisse is offline. It has no account, no ads, no tracking, and no purchases. If you deny the camera, the app explains how to turn it on in Settings, and you can still browse shades and save a look. If you deny Photos, the mirror still works and the shutter tells you the picture could not be saved.

Color on a screen changes with the light and the display. Sheenlisse is a preview, not a cosmetic and not a medical device.

## Keywords (100 characters max)

lipstick,blush,eyeshadow,makeup,mirror,beauty,shades,offline,looks,camera

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
| Medical or treatment information | None. The suggestion is a cosmetic starting point, not treatment or diagnosis. |
| Alcohol, tobacco, or drug use or references | None |
| Simulated gambling | None |
| Sexual content or nudity | None |
| Graphic sexual content and nudity | None |
| Contests | None |
| Unrestricted web access | No. About can open this app’s own privacy page, terms page, and project page. It does not browse the open web. |
| Gambling | No |
| Made for Kids (the Kids category) | No. The app is for a general audience and is not enrolled in Made for Kids. |
| User-generated content | No. Photos stay in the user’s library. Looks are private on the device. |
| Messaging and chat | No |
| Advertising | No |

## URLs

Host the site in `AppStore/website/` with GitHub Pages from the repository root, then use:

- Support URL: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/`
- Marketing URL: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/`
- Privacy Policy URL: `https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/privacy.html`

The same privacy policy and terms are included in the app, so they can be read with no network.

Until Pages is enabled, a working support contact is the repository issue list: `https://github.com/Hubery1991/Study_iOS/issues`

## App Privacy

Data Not Collected.

- No data is collected
- No data is used for tracking
- Tracking: No
- Identifiers, contact info, location, purchases, usage data, diagnostics, photos, and audio: not collected
- Privacy Nutrition Label: Data Not Collected
- The privacy manifest (`App/PrivacyInfo.xcprivacy`) declares no tracking and no collected data types

The camera is used only on device for the live makeup preview. Frames are processed in memory and discarded. They are not stored and not uploaded. Face geometry from ARKit or Vision is used to place color and is not kept as a template and not sent anywhere. A photo is written to the user’s Photos library only when they tap the shutter. Sheenlisse does not read the library and does not upload the picture. Favorites and settings stay in a local file on the device.

## Review notes

Sheenlisse is a complete offline makeup mirror. No sign-in, no purchase, and no network is required.

The camera is used only on device for the live preview. Frames, face landmarks, TrueDepth blend shapes, and the skin-tone reading stay in memory. They are not uploaded. A photo leaves the preview only when the reviewer taps the shutter, and then it is saved to Photos by the system.

How to test:

1. Launch the app and allow the camera. The mirror opens on the Natural look. The pill reads TrueDepth on a device with a TrueDepth front camera, and Vision otherwise.
2. Tap Evening, Vibrant, or Fresh. The shades and intensities change. Drag Intensity. Turn the region switch off to hide that color.
3. Tap Compare and drag across the picture. The left of the divider is the bare camera. The right shows makeup. Close an eye on a TrueDepth device and the shadow and liner ease off.
4. Tap the shutter. Allow adding to Photos. The picture is saved to the library. Sheenlisse does not upload it.
5. Tap Save, name the look, and open Favorites. Tap a saved look to apply it. Swipe to delete.
6. Tap the sparkle icon. The suggestion uses the face it sees, or the shape and tone you pick. Try this look applies it. The note says it is a starting point.
7. To see the denied-camera screen, turn the camera off for Sheenlisse in Settings. The app explains that, offers Open Settings, and offers Browse shades without the camera. Studio mode still saves looks.
8. About has the privacy policy and the terms inside the app, the haptics switch, and Delete saved looks. The support link is optional and needs a network only if the reviewer taps it.

iPhone is portrait. iPad is portrait, including upside down. There is no account and nothing to restore. A device with no front camera, including some simulators, opens the same studio path.

## Screenshots to upload

Five images in each folder under `AppStore/screenshots/`. Each one places an original generated portrait inside the mirror UI and adds a short headline. The controls match the app: look chips, region tabs, shade row, intensity, compare, and the suggestion card.

| Folder | Pixel size | App Store slot |
| --- | --- | --- |
| `iphone-6.9` | 1320 × 2868 | 6.9-inch iPhone |
| `iphone-6.7` | 1284 × 2778 | 6.7-inch iPhone |
| `iphone-6.5` | 1242 × 2688 | 6.5-inch iPhone |
| `ipad-13` | 2064 × 2752 | 13-inch iPad |

Order: 01 live Natural, 02 Evening shades, 03 before and after, 04 intensity, 05 a look for your face.

The portraits are original generated images made for this app, not photographs of real people. Copies are in `AppStore/models/`.

The 1024 × 1024 marketing icon is `AppStore/icon/AppIcon-1024.png` and is also in the Xcode asset catalog. It is RGB with no alpha channel.

## Submission checklist

- [ ] Apple Developer Program membership is active.
- [ ] Create the App Store Connect record with bundle ID `com.jackyliu.sheenlisse` and SKU `sheenlisse-ios`.
- [ ] Set the signing team, archive Release, and upload the build.
- [ ] Confirm the 1024 marketing icon uploaded with the build.
- [ ] Paste the name, subtitle, promotional text, description, and keywords from this file.
- [ ] Category: Lifestyle. Secondary: Photo & Video.
- [ ] Upload five screenshots for 6.9-inch, 6.7-inch, 6.5-inch, and 13-inch iPad from `AppStore/screenshots/`.
- [ ] Age rating: answer from the table above. Expect 4+. Do not enroll in Made for Kids.
- [ ] Privacy Policy URL: the `privacy.html` page above, once Pages is on.
- [ ] Support URL: the website index above.
- [ ] App Privacy: Data Not Collected. Tracking off. Camera and Photos are permissions, not collected data.
- [ ] Price: Free. No in-app purchases. No ads.
- [ ] Review notes: paste the testing steps above. No demo account. Explain that the camera is on-device only.
- [ ] Export compliance: already declared as exempt in Info.plist.

## Other Connect fields

- Bundle ID: `com.jackyliu.sheenlisse`
- SKU: `sheenlisse-ios`
- Copyright: 2026 Jacky Liu
- Price: Free
- Primary language: English (U.S.)
- Version: 1.0.0
- Content rights: the app does not use third-party content. Marketing portraits are original generated images made for this app.
- Encryption: `ITSAppUsesNonExemptEncryption` is false. The app does not use encryption beyond what the system provides, and it does not make network calls.
