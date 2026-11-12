import Foundation

enum LegalCopy {
    static let supportURL = "https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/"
    static let privacyURL = "https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/privacy.html"
    static let termsURL = "https://hubery1991.github.io/Study_iOS/Sheenlisse/AppStore/website/terms.html"
    static let contactURL = "https://github.com/Hubery1991/Study_iOS"

    static let privacyTitle = "Privacy Policy"
    static let termsTitle = "Terms of Use"

    static let privacyParagraphs: [String] = [
        "This policy describes Sheenlisse, a makeup mirror for iPhone and iPad by Jacky Liu. The same text is published on the privacy page linked from About. The short version is that Sheenlisse does not collect personal data.",
        "Sheenlisse does not collect, transmit, sell, or share personal information. It has no account, no sign-in, no ads, no analytics, no tracking, and no in-app purchases. You can use the whole app with the device offline.",
        "The camera is used only on this device, and only to show a live makeup preview. Frames from the front camera are read in memory so the app can find facial landmarks and lay color on the lips, cheeks, eyelids, liner, and brows. Those frames are not saved unless you tap the shutter, and they are not uploaded. When you leave the mirror, or the app goes to the background, the camera stops.",
        "On devices with a TrueDepth camera, Sheenlisse uses Apple’s ARKit face tracking to follow the face and to notice a blink or an open mouth. On other devices it uses the Vision framework on the same camera image. Face geometry, blend shapes, and any skin-tone reading are calculated in memory to place and suggest color. They are not stored as a face template, not used to identify you, and not sent anywhere.",
        "A photo is written to your Photos library only when you tap the shutter. Sheenlisse does not read your existing photos. The saved picture stays in your library under Apple’s control. The app does not keep its own copy and does not upload it.",
        "Saved looks, the last recipe you tried, the haptics switch, and whether you have dismissed the short camera note are stored in a file on this device. Deleting Sheenlisse deletes them. Delete saved looks in About removes the favorites and leaves the haptics switch as it is. Nothing in that file is transmitted.",
        "Sheenlisse does not use the microphone, location, contacts, advertising identifier, or a network connection of its own. Links in About open this policy, the terms, or the project page in the browser only if you tap them. The policy and the terms are also readable inside the app with no connection.",
        "Color on the screen is a preview. It is not a cosmetic product, not a match to any brand’s shade, and not professional or medical advice. Light, the display, and your camera all change how a color looks.",
        "Children. Sheenlisse is a general-audience app. It is not directed at collecting information from children, and it collects no personal information from anyone.",
        "This policy may be updated when the app changes. The copy inside the app matches the version you installed. Continued use of an update means you accept the policy that ships with it.",
        "Questions about privacy can be sent to Jacky Liu via \(contactURL). There is no data request to make, because no personal data is collected."
    ]

    static let termsParagraphs: [String] = [
        "These terms cover your use of the Sheenlisse app. By downloading or using it, you agree to them. If you do not agree, do not use the app. On Apple devices, Apple’s Standard Licensed Application End User License Agreement also applies.",
        "License. You receive a personal, non-exclusive, non-transferable license to use Sheenlisse on devices you own or control, as allowed by the App Store. You may not copy the app for sale, reverse engineer it except where the law allows, or present it as your own product.",
        "The mirror. Sheenlisse shows a live camera preview and draws lipstick, blush, eyeshadow, eyeliner, and brows on the face it finds. Curated looks, shade choices, intensity, a before-and-after divider, saved looks, and a face-shape and skin-tone suggestion are part of the app. The suggestion is a starting point based on simple on-device measurements. It is not a diagnosis and not a promise about how a color will look in person.",
        "Your photos and looks. A picture is saved only when you ask, and only to your Photos library. Favorite looks stay on the device. They can be lost if you delete the app, delete saved looks, or change devices. There is no account and no cloud backup.",
        "The camera. You can deny camera access. The app then explains how to turn it on in Settings, and you can still browse shades and save a look without a live preview. You can deny Photos access. The mirror still works, and a shutter tap will explain that the photo could not be saved.",
        "Acceptable use. Do not use the app to break the law, to interfere with other people’s devices, or to misrepresent who made it. The app has no chat and no public profile.",
        "No warranty. Sheenlisse is provided as is, without a promise that the preview will match a product you buy or that tracking will succeed in every light, to the extent the law allows.",
        "Liability. To the extent the law allows, the developer is not liable for indirect or consequential damages arising from use of the app. Nothing in these terms limits rights that cannot be waived.",
        "Apple. These terms are between you and the developer, not Apple. Apple is not responsible for the app or its support. Apple and its subsidiaries are third-party beneficiaries of these terms and may enforce them.",
        "Changes. An update may include updated terms. The text inside the app is the text that applies to that version.",
        "Contact. Questions about these terms can go to the Study_iOS project at \(contactURL)."
    ]
}
