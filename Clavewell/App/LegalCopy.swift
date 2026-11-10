import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        }
    }

    var updated: String { "November 10, 2026" }

    var sections: [(String, String)] {
        switch self {
        case .privacy: return LegalCopy.privacy
        case .terms: return LegalCopy.terms
        }
    }
}

enum LegalCopy {
    static let contact = "Jacky Liu — https://github.com/Hubery1991/Study_iOS/issues"

    static let privacy: [(String, String)] = [
        ("Who we are", "This policy describes Clavewell, a puzzle game for iPhone and iPad by Jacky Liu (\"we\"). It explains what the game does with information. The short version is that Clavewell does not collect personal data."),
        ("The short version", "Clavewell does not collect, transmit, sell, or share personal information. It does not require an account or a network connection. You can play the entire game with the device offline."),
        ("What stays on your device", "The game stores a few things locally, using iOS preferences on the device: your high scores and lifetime play totals; the settings you choose, including sound, haptics, color patterns, and the landing guide; and whether you have already opened the how-to-play guide. Deleting Clavewell deletes this information. We have no server that receives it."),
        ("What we do not do", "We do not collect your name, email address, contacts, photos, precise location, advertising identifier, or payment information. There are no accounts, no ads, no in-app purchases, no analytics, and no third-party software kits. The game does not ask you to sign in, and it does not contact a network service of ours."),
        ("Apple", "If you download Clavewell from the App Store, Apple handles that purchase and download under Apple's own privacy policy. That relationship is between you and Apple. Clavewell does not receive your App Store account details."),
        ("Children", "Clavewell is a general-audience puzzle. We do not knowingly collect personal information from anyone, including children under 13 or anyone else."),
        ("Changes", "If this policy changes, the new version will show a new effective date on this screen and on the public policy page. The in-app copy updates when you install an update of the app."),
        ("Contact", "Questions about privacy can be sent to \(contact).")
    ]

    static let terms: [(String, String)] = [
        ("Agreement", "These terms are a license between you and Jacky Liu for the Clavewell app. By downloading or playing Clavewell, you agree to them. If you do not agree, do not use the app."),
        ("License", "We grant you a personal, non-exclusive, non-transferable, revocable license to install and play Clavewell on Apple devices you own or control, as the App Store usage rules allow. The app is licensed, not sold."),
        ("The game", "Clavewell is an offline puzzle. Scores and settings are stored on the device. Deleting the app, moving to a new device, or a device failure can erase them. There are no accounts and no cloud saves."),
        ("Acceptable use", "Play the app for personal entertainment. Do not copy it in order to distribute it, rent it, or sell it. Do not reverse engineer it except where a law says that limit is not allowed. Do not use the app to break the law."),
        ("Intellectual property", "Clavewell, including its name, rules, text, original artwork, and synthesized sounds, belongs to Jacky Liu. These terms do not give you ownership of any of that. Apple and the App Store are trademarks of Apple Inc., used here only to describe where the app may be obtained."),
        ("No warranty", "The app is provided \"as is\", without a warranty of any kind, to the extent the law allows. We do not warrant that a session will be uninterrupted or that a score will be kept. Nothing in these terms limits a right that consumer law says cannot be limited."),
        ("Liability", "To the extent the law allows, Jacky Liu is not liable for indirect, incidental, special, or consequential damages, or for lost scores or other data on your device, arising from your use of the app. If a law requires a cap and does not allow the exclusion, our total liability is limited to the amount you paid for the app. Clavewell is free, so that amount is zero. This section does not limit liability that the law says cannot be limited."),
        ("Apple", "If you got the app from the App Store, you and Jacky Liu agree: these terms are between you and Jacky Liu only, not Apple, and Jacky Liu is solely responsible for the app and its content. Apple has no obligation to furnish maintenance or support. If the app fails to conform to an applicable warranty, you may notify Apple and Apple may refund the purchase price, if any; to the maximum extent permitted by law, Apple has no other warranty obligation. Jacky Liu, not Apple, is responsible for product claims, legal claims, and intellectual-property claims relating to the app. You represent that you are not located in a country subject to a U.S. Government embargo and are not on a U.S. Government list of prohibited or restricted parties. You will comply with third-party agreements that apply to your use, such as a wireless data service agreement. Apple and Apple's subsidiaries are third-party beneficiaries of these terms and may enforce them against you."),
        ("Changes", "We may update these terms by posting a new version here and in an app update. The effective date will change. If you keep using the app after the new terms apply, you accept them."),
        ("Contact", "Questions about these terms can be sent to \(contact).")
    ]
}

struct LegalDocumentView: View {
    var document: LegalDocument

    var body: some View {
        ZStack {
            WellBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Effective \(document.updated)")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.brass)
                    ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.0)
                                .font(Theme.serif(22))
                                .foregroundStyle(Theme.parchment)
                            Text(section.1)
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
