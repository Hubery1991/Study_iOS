import Foundation

/// A first-launch drawer so the wardrobe, picks, and wear history are visible immediately.
/// House names are invented. Nothing here is a store catalog.
public enum StarterWardrobe {
    public static func make(today: CalendarDay) -> WardrobeSnapshot {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let lipsticks: [Lipstick] = entries.enumerated().map { index, entry in
            Lipstick(
                id: identifier(entry.number),
                name: entry.name,
                brand: entry.brand,
                finish: entry.finish,
                undertone: entry.undertone,
                colorFamily: entry.family,
                occasions: entry.occasions,
                shade: try! ShadeColor(hex: entry.hex),
                swatchFileName: nil,
                ownership: entry.ownership,
                createdAt: base.addingTimeInterval(Double(index) * 60)
            )
        }
        let wears: [WearRecord] = wearOffsets.compactMap { offset in
            guard let day = today.adding(days: -offset.daysAgo) else { return nil }
            return WearRecord(
                id: identifier(100 + offset.number),
                lipstickID: identifier(offset.number),
                day: day
            )
        }
        return WardrobeSnapshot(
            lipsticks: lipsticks,
            wears: wears,
            starterInstalled: true
        )
    }

    public static func identifier(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", number))!
    }

    private struct Entry {
        var number: Int
        var name: String
        var brand: String
        var finish: Finish
        var undertone: Undertone
        var family: ColorFamily
        var occasions: [Occasion]
        var hex: String
        var ownership: Ownership
    }

    private struct WearOffset {
        var number: Int
        var daysAgo: Int
    }

    private static let entries: [Entry] = [
        Entry(number: 1, name: "Cellar Merlot", brand: "Orchard Lacquer", finish: .stain, undertone: .cool, family: .wine, occasions: [.evening, .date], hex: "6E2436", ownership: .owned),
        Entry(number: 2, name: "Dusty Blush", brand: "Clayroom", finish: .satin, undertone: .warm, family: .nude, occasions: [.everyday, .brunch], hex: "C48984", ownership: .owned),
        Entry(number: 3, name: "Lantern Coral", brand: "Harbor Pigment", finish: .cream, undertone: .warm, family: .coral, occasions: [.date, .photos], hex: "E15A3C", ownership: .owned),
        Entry(number: 4, name: "Quiet Rose", brand: "North Satin", finish: .satin, undertone: .neutral, family: .rose, occasions: [.office], hex: "B15C6C", ownership: .owned),
        Entry(number: 5, name: "Bare Apricot", brand: "Clayroom", finish: .sheer, undertone: .warm, family: .nude, occasions: [.everyday], hex: "D0A088", ownership: .owned),
        Entry(number: 6, name: "Ink Plum", brand: "Orchard Lacquer", finish: .matte, undertone: .cool, family: .plum, occasions: [.evening, .holiday], hex: "5A2748", ownership: .owned),
        Entry(number: 7, name: "Glass Cherry", brand: "Harbor Pigment", finish: .gloss, undertone: .neutral, family: .red, occasions: [.date, .photos], hex: "C4233A", ownership: .owned),
        Entry(number: 8, name: "Mauve Hour", brand: "North Satin", finish: .cream, undertone: .cool, family: .mauve, occasions: [.office, .wedding], hex: "A56B86", ownership: .owned),
        Entry(number: 9, name: "Winter Currant", brand: "Atelier Vesper", finish: .gloss, undertone: .cool, family: .berry, occasions: [.holiday, .evening], hex: "7A1E3A", ownership: .wishlist),
        Entry(number: 10, name: "Noon Terracotta", brand: "Clayroom", finish: .matte, undertone: .warm, family: .brown, occasions: [.brunch, .photos], hex: "C26A45", ownership: .wishlist)
    ]

    /// Relative to the day the drawer is installed. Today itself stays open for a new log.
    private static let wearOffsets: [WearOffset] = [
        WearOffset(number: 4, daysAgo: 1),
        WearOffset(number: 5, daysAgo: 3),
        WearOffset(number: 8, daysAgo: 8),
        WearOffset(number: 3, daysAgo: 16),
        WearOffset(number: 7, daysAgo: 21),
        WearOffset(number: 6, daysAgo: 40)
    ]
}
