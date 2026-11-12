import Foundation

enum LegalCopy {
    static let supportURL = "https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/"
    static let privacyURL = "https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/privacy.html"
    static let termsURL = "https://hubery1991.github.io/Study_iOS/Quillisse/AppStore/website/terms.html"
    static let contactURL = "https://github.com/Hubery1991/Study_iOS"

    static let privacyTitle = "Privacy Policy"
    static let termsTitle = "Terms of Use"

    static let privacyParagraphs: [String] = [
        "This policy describes Quillisse, a daily outfit assistant for iPhone and iPad by Jacky Liu. The same text is on the privacy page linked from About. Quillisse does not collect personal data.",
        "Quillisse has no account, no sign-in, no ads, no analytics, no tracking, and no in-app purchases. The closet works with the device offline. Nothing you add is uploaded to a developer server.",
        "Clothes you photograph or choose from Photos are copied into the app’s private storage on this device. They are used only to build your closet and to suggest outfits. They are not sent anywhere. Deleting a piece deletes that copy. Deleting the app deletes the closet.",
        "The camera is used only when you choose Take a photo, and only to photograph a garment. If you deny the camera, Quillisse explains how to turn it on in Settings. You can still add a picture from Photos, or keep using the sample closet.",
        "The photo library is read only when you choose a picture to add. A picture is written back to Photos only when you tap Save to Photos. If you deny either permission, the rest of the app keeps working and tells you what could not be done.",
        "Weather is a choice you make in the app: a season and a band such as mild, cool, or rain. That choice stays on the device. If you turn on Apple Weather, Quillisse asks for location while you are using it, requests a forecast from Apple WeatherKit, and keeps only the resulting band, a rain flag, and a short note such as “18° and dry.” Coordinates are not stored. If you deny location, or the network is unavailable, the manual choice is used and the app says so.",
        "Favorites, the wear journal, tags, the repeat window, and the haptics switch live in a file on this device. They are not transmitted. Remove the sample closet deletes the pieces that shipped with the app and the sample journal entries that used them. Pieces you added stay.",
        "Quillisse does not use the microphone, contacts, advertising identifier, or a developer account. Links in About open this policy, the terms, or the project page only if you tap them. Both documents can be read inside the app with no connection.",
        "Outfit suggestions are a sorting of clothes you already own. They are not a stylist’s advice, not a product recommendation, and not a promise about comfort or dress codes.",
        "Children. Quillisse is a general-audience app. It is not directed at collecting information from children, and it collects no personal information from anyone.",
        "This policy may change when the app changes. The copy inside the app matches the version you installed.",
        "Questions can go to Jacky Liu via \(contactURL). There is no data export to request, because no personal data is collected."
    ]

    static let termsParagraphs: [String] = [
        "These terms cover your use of Quillisse. By downloading or using it, you agree to them. If you do not agree, do not use the app. On Apple devices, Apple’s Licensed Application End User License Agreement also applies.",
        "License. You receive a personal, non-exclusive, non-transferable license to use Quillisse on devices you own or control, as allowed by the App Store. You may not sell the app, reverse engineer it except where the law allows, or present it as your own product.",
        "The closet. Quillisse lets you photograph or import clothes, tag them, and ask for a complete look for an occasion and a weather band. You can save favorites, build a look by hand, and keep a journal of what you wore so a recent look is ranked lower. A sample closet is included so the first day is not empty. You can remove it.",
        "Your pictures and notes stay on the device. They can be lost if you delete the app or a piece. There is no account and no cloud backup from Quillisse.",
        "Permissions. You can deny the camera, Photos, and location. The app explains the denial and keeps working with whatever you already have, including a weather band you set yourself. Apple Weather is optional and is not required for any suggestion.",
        "Acceptable use. Do not use the app to break the law or to misrepresent who made it. There is no chat and no public profile.",
        "No warranty. Quillisse is provided as is. Suggestions can miss a piece, repeat a color, or ignore a rule of dress you care about. To the extent the law allows, there is no promise that a look will be suitable for a workplace, an event, or the real weather.",
        "Liability. To the extent the law allows, the developer is not liable for indirect or consequential damages from use of the app. Nothing here limits rights that cannot be waived.",
        "Apple. These terms are between you and the developer, not Apple. Apple is not responsible for the app or its support. Apple and its subsidiaries are third-party beneficiaries and may enforce these terms.",
        "Changes. An update may include updated terms. The text inside the app is the text for that version.",
        "Contact. Questions about these terms can go to the Study_iOS project at \(contactURL)."
    ]
}
