import Foundation

/// Optimal step strings from the breadth-first solver. U D L R are single steps.
/// Replayed by the test suite against the Swift rules engine.
enum VerifiedSolutions {
    static let moves: [Int: String] = [
        1: "R",
        2: "UU",
        3: "RR",
        4: "LLU",
        5: "LLU",
        6: "LULU",
        7: "UUDRR",
        8: "UUDRR",
        9: "LUDRRU",
        10: "LULURR",
        11: "LLURDRU",
        12: "LDURRRD",
        13: "RRRDRRUR",
        14: "ULUDRRRU",
        15: "UUDDRRRURU",
        16: "LLURDRURDRU",
        17: "UDLLURRRDRU",
        18: "UUDDRRRURUULD",
        19: "LLUDDURRRRUDD",
        20: "RRDDUULLDRURD",
        21: "LUDRRRUULLDDRU",
        22: "LLUDDURRRRRUDD",
        23: "UDLUURDRUDRDRUU",
        24: "UURDDRRRLLUULURR",
        25: "LULDRRRDRULULLDDRR",
        26: "UUDLLDLUUDRRRRRDRUU",
        27: "URDRUUDDLLLUUDLLDLUU",
        28: "ULURULRRRRRDLDLULDLU",
        29: "UDLLLUURDRDRRUULLDDRU",
        30: "UUDDLLUUDDRRRRUUDDRRUU",
        31: "LLULDLUUDRRRDRUUDRRDRUU",
        32: "DRURDDDLULDRRRRUUURRRDL",
        33: "ULDDULURRRRDRUDLDLDRLLL",
        34: "LULDLUDRDRDLRRRRURUULURDDRD",
        35: "LULDLUUDRRRDRUURULLRDDDRUURUL",
        36: "LLLURDLDRURUDDURRRRULDRDLULUDD"
    ]
}
