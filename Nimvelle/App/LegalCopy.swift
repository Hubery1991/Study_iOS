import Foundation

enum AppLinks {
    static let website = URL(string: "https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/")!
    static let privacy = URL(string: "https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/privacy.html")!
    static let terms = URL(string: "https://hubery1991.github.io/Study_iOS/Nimvelle/AppStore/website/terms.html")!
    static let support = URL(string: "https://github.com/Hubery1991/Study_iOS/issues")!
}

enum LegalCopy {
    static let privacy = """
    Privacy Policy
    Nimvelle
    Last updated November 11, 2026

    Nimvelle is a skincare routine check-in you keep on your own phone or tablet. This policy explains what the app does with information. The same text is on the Nimvelle website.

    Nimvelle is not a medical device. It does not diagnose, treat, or monitor a condition. Notes you write are memories, not a chart for a clinic.

    Data not collected

    Nimvelle has no account, no ads, and no analytics. The developer does not receive your routine, your products, your notes, your photos, or your reminder times. The app does not use the network for its features. A link in About opens this policy, the terms, or the project page only if you tap it.

    What stays on the device

    These stay in the app’s private storage on the device:

    • Products on your shelf, including an open date, a period-after-opening, and how full the jar feels
    • Morning and evening steps, and the days you check them off
    • Skin notes you choose to write
    • Progress photos you add
    • Whether reminders and haptics are on, and the times you pick

    Deleting the app deletes that copy. Nimvelle has no server copy to restore.

    Camera

    The camera is optional. It is used only when you choose Take a photo for a progress picture. If you deny the camera, the rest of Nimvelle still works, and you can still choose a picture you already have. The photo is stored in the app and is not uploaded.

    Photo library

    Choosing a picture asks for photo library access. That picture is copied into the app and is not uploaded. Saving a copy back to Photos happens only when you tap Save a copy to Photos, and that asks for permission to add a picture. If you deny either permission, Nimvelle explains how to turn it on in Settings and keeps the copy it already has.

    Notifications

    Reminders are optional. If you turn one on, iOS asks whether Nimvelle may send notifications. The reminder is scheduled on the device. There is no remote push. If you deny notifications, the routine still works. You can change the permission later in Settings.

    Sample shelf

    The first launch includes a sample routine, products, check-ins, and notes so the calendar is not empty. You can remove the sample in About. Your own additions are kept.

    Children

    Nimvelle is a general-audience app. It is not directed at children under 13, and it is not enrolled in Made for Kids. It does not knowingly collect personal information from anyone, because it does not collect personal information.

    Changes

    If this policy changes, the date above will change and the copy inside the app will be updated with the app.

    Contact

    Questions can go to the project issues page linked from About. There is no Nimvelle account to write to.
    """

    static let terms = """
    Terms of Use
    Nimvelle
    Last updated November 11, 2026

    These terms are the agreement for using Nimvelle. The same text is on the Nimvelle website. If you do not agree, do not use the app.

    What Nimvelle is

    Nimvelle is a personal journal for a skincare routine: steps you check off, a calendar, a shelf with open-jar dates, optional notes, optional photos, and optional local reminders.

    Nimvelle is not a medical device and does not provide medical advice, a diagnosis, or a treatment. A period after opening is a maker’s storage guide for an opened jar. A streak is a count of days you finished the steps you listed. A note about dryness or spots is your own memory. None of these are an assessment of your health. Decisions about your skin belong to you and, when you want one, to a qualified professional. Do not delay seeking care because of anything you logged here.

    Your content

    Routines, notes, and photos you add are yours. They stay on the device. You are responsible for the photos you take and for having the right to use them. Nimvelle does not review them and does not upload them.

    License

    Nimvelle is licensed to you for personal use on Apple devices you own or control, under Apple’s standard app terms. You may not copy the app, reverse engineer it except where the law allows, or present it as a medical product.

    The sample shelf is part of the app so the first launch is not empty. You may remove it.

    No account and no warranty

    There is nothing to sign in to and nothing to buy. The app is provided as is, without a warranty of fitness for a particular purpose. To the extent the law allows, the developer is not liable for lost data, a missed reminder, a jar you kept too long, or any decision you make from your own notes. Local data can be lost if the device is lost or the app is deleted.

    Apple is not a party to these terms, except as required by the App Store terms that apply to the download.

    Age

    Nimvelle is for a general audience. It is not Made for Kids.

    Contact

    The support link in About opens the project issues page. That page is optional and needs a network only if you choose to open it.
    """
}
