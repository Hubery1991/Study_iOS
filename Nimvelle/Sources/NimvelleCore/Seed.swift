import Foundation

public enum SampleID {
    public static func make(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "B7E1A0C0-4D20-4F6A-8C10-%012d", n))!
    }
}

/// A small shelf and routine so the first launch is not empty.
/// Every piece is marked `isSample` and can be removed from About.
public enum SampleStudio {
    public static func make(today: DayKey, calendar: Calendar) -> Studio {
        let cleanser = product(1, "Cloud Milk Cleanser", "Hearth & Co.", .cleanser, opened: today.adding(days: -40, calendar: calendar), pao: 12, fill: .threeQuarters)
        let toner = product(2, "Rice Water Toner", "Hearth & Co.", .toner, opened: today.adding(days: -40, calendar: calendar), pao: 12, fill: .half)
        let serum = product(3, "Dawn C Serum", "Lumen Atelier", .serum, opened: today.adding(days: -50, calendar: calendar), pao: 6, fill: .threeQuarters)
        let veilExpiry = today.adding(days: 10, calendar: calendar)
        let veil = product(4, "Veil Cream", "Hearth & Co.", .moisturizer, opened: veilExpiry.adding(months: -12, calendar: calendar), pao: 12, fill: .quarter)
        let spf = product(5, "Daily Veil SPF 50", "Lumen Atelier", .sunscreen, opened: today.adding(days: -80, calendar: calendar), pao: 12, fill: .half)
        let nightExpiry = today.adding(days: -40, calendar: calendar)
        let night = product(6, "Night Repair Cream", "Hearth & Co.", .moisturizer, opened: nightExpiry.adding(months: -12, calendar: calendar), pao: 12, fill: .low)
        let mask = product(7, "Soft Clay Mask", "North Room", .mask, opened: today.adding(days: -90, calendar: calendar), pao: 12, fill: .half)
        let polish = product(8, "Gentle Polish", "North Room", .exfoliant, opened: today.adding(days: -100, calendar: calendar), pao: 12, fill: .quarter)

        let morning: [RoutineStep] = [
            step(11, "Cleanse", .cleanser, .morning, cleanser.id, 0),
            step(12, "Tone", .toner, .morning, toner.id, 1),
            step(13, "Serum", .serum, .morning, serum.id, 2),
            step(14, "Moisturize", .moisturizer, .morning, veil.id, 3),
            step(15, "Sunscreen", .sunscreen, .morning, spf.id, 4),
        ]
        let evening: [RoutineStep] = [
            step(21, "Cleanse", .cleanser, .evening, cleanser.id, 0),
            step(22, "Tone", .toner, .evening, toner.id, 1),
            step(23, "Night cream", .moisturizer, .evening, night.id, 2),
        ]
        let steps = morning + evening
        var checks: [CheckIn] = []
        for offset in -40 ... -20 {
            let day = today.adding(days: offset, calendar: calendar)
            for item in steps {
                checks.append(CheckIn(day: day, stepID: item.id))
            }
        }
        for offset in [-10, -9, -8, -5, -4, -3, -2, -1] {
            let day = today.adding(days: offset, calendar: calendar)
            for item in steps {
                checks.append(CheckIn(day: day, stepID: item.id))
            }
        }
        let partial = today.adding(days: -6, calendar: calendar)
        for item in morning.prefix(2) {
            checks.append(CheckIn(day: partial, stepID: item.id))
        }
        for item in morning.prefix(3) {
            checks.append(CheckIn(day: today, stepID: item.id))
        }

        let notePlan: [(Int, Int, Int, Int, Int, String)] = [
            (-12, 3, 0, 4, 3, "Comfortable. Late night."),
            (-10, 2, 0, 4, 4, "Soft after the cream."),
            (-8, 4, 2, 3, 2, "A little tight, a few spots."),
            (-6, 3, 0, 4, 4, "Calmer than yesterday."),
            (-5, 2, 0, 5, 5, "Slept well."),
            (-4, 3, 1, 4, 3, "One small spot on the chin."),
            (-3, 2, 0, 4, 4, ""),
            (-2, 1, 0, 5, 4, "Felt comfortable all day."),
            (-1, 3, 0, 4, 4, "A bit dry by evening."),
        ]
        let notes: [SkinNote] = notePlan.enumerated().map { index, item in
            SkinNote(
                id: SampleID.make(40 + index),
                day: today.adding(days: item.0, calendar: calendar),
                dryness: item.1,
                breakouts: item.2,
                mood: item.3,
                sleep: item.4,
                text: item.5,
                isSample: true
            )
        }

        return Studio(
            products: [cleanser, toner, serum, veil, spf, night, mask, polish],
            steps: steps,
            checks: checks,
            notes: notes,
            photos: [],
            reminders: .off,
            hapticsEnabled: true
        )
    }

    private static func product(
        _ id: Int,
        _ name: String,
        _ brand: String,
        _ kind: StepKind,
        opened: DayKey,
        pao: Int,
        fill: FillLevel
    ) -> Product {
        Product(
            id: SampleID.make(id),
            name: name,
            brand: brand,
            kind: kind,
            openedOn: opened,
            paoMonths: pao,
            fill: fill,
            note: "",
            isSample: true
        )
    }

    private static func step(
        _ id: Int,
        _ title: String,
        _ kind: StepKind,
        _ part: DayPart,
        _ productID: UUID,
        _ position: Int
    ) -> RoutineStep {
        RoutineStep(
            id: SampleID.make(id),
            title: title,
            kind: kind,
            part: part,
            productID: productID,
            position: position,
            isActive: true,
            isSample: true
        )
    }
}
