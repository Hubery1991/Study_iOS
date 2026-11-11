import Foundation

public enum SeedCloset {
    public static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "C10E0000-0000-4000-8000-%012d", n))!
    }

    public static let creamCardigan = id(1)
    public static let lightJeans = id(2)
    public static let whiteSneakers = id(3)
    public static let ivoryCamisole = id(4)
    public static let blackBlazer = id(5)
    public static let ivoryBlouse = id(6)
    public static let camelTrousers = id(7)
    public static let blackLoafers = id(8)
    public static let goldHoops = id(9)
    public static let coralDress = id(10)
    public static let lavenderCardigan = id(11)
    public static let nudeHeels = id(12)
    public static let whiteTee = id(13)
    public static let linenShirt = id(14)
    public static let oliveShorts = id(15)
    public static let navyKnit = id(16)
    public static let charcoalTrousers = id(17)
    public static let camelCoat = id(18)
    public static let blushScarf = id(19)
    public static let blackPumps = id(20)

    public static let garments: [Garment] = [
        piece(creamCardigan, "Cream cardigan", .outerwear, [.cream], [.spring, .autumn], .smart, .medium, "seed-cream-cardigan"),
        piece(lightJeans, "Light jeans", .bottom, [.denim], [.allSeason], .casual, .medium, "seed-light-jeans"),
        piece(whiteSneakers, "White sneakers", .shoes, [.white], [.allSeason], .casual, .light, "seed-white-sneakers"),
        piece(ivoryCamisole, "Ivory camisole", .top, [.ivory], [.allSeason], .casual, .light, "seed-ivory-cami"),
        piece(blackBlazer, "Black blazer", .outerwear, [.black], [.allSeason], .smart, .medium, "seed-black-blazer"),
        piece(ivoryBlouse, "Ivory blouse", .top, [.ivory], [.allSeason], .smart, .light, "seed-ivory-blouse"),
        piece(camelTrousers, "Camel trousers", .bottom, [.camel], [.spring, .autumn, .winter], .smart, .medium, "seed-camel-trousers"),
        piece(blackLoafers, "Black loafers", .shoes, [.black], [.allSeason], .smart, .medium, "seed-black-loafers"),
        piece(goldHoops, "Gold hoops", .accessory, [.gold], [.allSeason], .smart, .light, "seed-gold-hoops"),
        piece(coralDress, "Coral midi dress", .dress, [.coral], [.spring, .summer], .formal, .light, "seed-coral-dress"),
        piece(lavenderCardigan, "Lavender cardigan", .outerwear, [.lavender], [.spring, .summer], .smart, .light, "seed-lavender-cardigan"),
        piece(nudeHeels, "Nude heels", .shoes, [.camel], [.allSeason], .formal, .light, "seed-nude-heels"),
        piece(whiteTee, "White tee", .top, [.white], [.allSeason], .casual, .light, "seed-white-tee"),
        piece(linenShirt, "Blue linen shirt", .outerwear, [.blue], [.spring, .summer], .casual, .light, "seed-linen-shirt"),
        piece(oliveShorts, "Olive shorts", .bottom, [.olive], [.summer], .casual, .light, "seed-olive-shorts"),
        piece(navyKnit, "Navy knit", .top, [.navy], [.autumn, .winter], .smart, .medium, "seed-navy-knit"),
        piece(charcoalTrousers, "Charcoal trousers", .bottom, [.charcoal], [.autumn, .winter], .smart, .medium, "seed-charcoal-trousers"),
        piece(camelCoat, "Camel coat", .outerwear, [.camel], [.autumn, .winter], .smart, .heavy, "seed-camel-coat"),
        piece(blushScarf, "Blush scarf", .accessory, [.blush], [.spring, .autumn, .winter], .casual, .light, "seed-blush-scarf"),
        piece(blackPumps, "Black pumps", .shoes, [.black], [.allSeason], .formal, .light, "seed-black-pumps")
    ]

    public static let workLookIDs = [ivoryBlouse, camelTrousers, blackBlazer, blackLoafers, goldHoops]
    public static let weekendLookIDs = [whiteTee, oliveShorts, linenShirt, whiteSneakers]
    public static let casualLookIDs = [ivoryCamisole, lightJeans, creamCardigan, whiteSneakers]
    public static let eveningLookIDs = [coralDress, lavenderCardigan, nudeHeels]

    public static func sampleWears(around today: DayStamp, calendar: Calendar) -> [WearEntry] {
        func entry(_ daysAgo: Int, _ ids: [UUID], _ occasion: Occasion, _ slot: Int) -> WearEntry? {
            guard let day = today.addingDays(-daysAgo, calendar: calendar) else { return nil }
            return WearEntry(
                id: id(100 + slot),
                day: day,
                pieceIDs: ids,
                occasion: occasion,
                lookID: nil,
                note: ""
            )
        }
        return [
            entry(1, casualLookIDs, .casual, 1),
            entry(3, weekendLookIDs, .weekend, 2),
            entry(6, workLookIDs, .work, 3),
            entry(9, eveningLookIDs, .date, 4)
        ].compactMap { $0 }
    }

    private static func piece(
        _ id: UUID,
        _ name: String,
        _ category: GarmentCategory,
        _ colors: [GarmentColor],
        _ seasons: [Season],
        _ formality: Formality,
        _ weight: GarmentWeight,
        _ token: String
    ) -> Garment {
        Garment(
            id: id,
            name: name,
            category: category,
            colors: colors,
            seasons: seasons,
            formality: formality,
            weight: weight,
            imageToken: token,
            isFavorite: false,
            isSample: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            note: ""
        )
    }
}
