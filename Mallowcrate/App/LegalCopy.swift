import Foundation

enum LegalCopy {
    static let supportURL = "https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/"
    static let privacyURL = "https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/privacy.html"
    static let termsURL = "https://hubery1991.github.io/Study_iOS/Mallowcrate/AppStore/website/terms.html"
    static let contactURL = "https://github.com/Hubery1991/Study_iOS"

    static let privacyTitle = "Privacy Policy"
    static let termsTitle = "Terms of Use"

    static let privacyParagraphs: [String] = [
        "This policy describes Mallowcrate, a puzzle game for iPhone and iPad. It is written in plain language. The same text is published at the privacy page linked from About.",
        "Mallowcrate does not collect, transmit, sell, or share personal data. It has no account, no sign-in, no ads, no analytics, no tracking, and no in-app purchases. The app does not ask for your name, email, contacts, photos, location, or any identifier.",
        "Progress stays on your device. Cleared levels, star ratings, best move counts, and the sound and haptics switches are stored in local app storage (UserDefaults). That information is not uploaded. Deleting the app deletes it. Reset Progress in Settings clears the saved puzzles and keeps your sound and haptics choices.",
        "Mallowcrate does not use the network to play. Links in About open this policy, the terms, or the project page in the browser only if you tap them. The full policy and terms are also readable inside the app with no connection.",
        "Sound is generated on the device. Haptics use the system vibration motor. Both can be turned off in Settings. The app does not use the microphone or camera.",
        "Children. Mallowcrate is a gentle puzzle suitable for a general audience. It is not directed at collecting information from children, and it collects no personal information from anyone.",
        "This policy may be updated when the app changes. The copy inside the app matches the version you installed. Continued use of an update means you accept the policy that ships with it.",
        "Questions. Mallowcrate is an offline game in the Study_iOS project. You can reach the project at \(contactURL). There is no separate data request to make, because no personal data is collected."
    ]

    static let termsParagraphs: [String] = [
        "These terms cover your use of the Mallowcrate app. By downloading or playing, you agree to them. If you do not agree, do not use the app. On Apple devices, Apple’s Standard Licensed Application End User License Agreement also applies.",
        "License. You receive a personal, non-exclusive, non-transferable license to play Mallowcrate on devices you own or control, as allowed by the App Store. You may not copy the app for sale, reverse engineer it except where the law allows, or present it as your own product.",
        "The game. Mallowcrate is a crate-pushing puzzle. You walk Mallow one tile at a time and nudge a single crate onto each daisy. Levels, star thresholds, and best move counts are part of the game. Stars are three for a clear within two moves of par, two for a wider band, and one for any clear.",
        "Local saves. Progress is stored only on your device. It can be lost if you delete the app, reset progress, or change devices. There is no cloud backup and no account to restore it.",
        "Acceptable use. Do not use the app to break the law, to interfere with other people’s devices, or to misrepresent who made it. The app has no player chat and no user content.",
        "No warranty. Mallowcrate is provided as is, without a promise that it will be uninterrupted or fit a particular purpose, to the extent the law allows. Puzzle difficulty is part of the design.",
        "Liability. To the extent the law allows, the developer is not liable for indirect or consequential damages arising from use of the app. Nothing in these terms limits rights that cannot be waived.",
        "Apple. These terms are between you and the developer, not Apple. Apple is not responsible for the app or its support. Apple and its subsidiaries are third-party beneficiaries of these terms and may enforce them.",
        "Changes. An update may include updated terms. The text inside the app is the text that applies to that version.",
        "Contact. Questions about these terms can go to the Study_iOS project at \(contactURL)."
    ]
}
