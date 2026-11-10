import Foundation

/// Handcrafted puzzles. `par` is the fewest steps found by the breadth-first
/// solver in `AppStore/solve_levels.py`. Every catalog entry has a verified solution.
public struct LevelDefinition: Equatable, Identifiable, Sendable {
    public let index: Int
    public let world: Int
    public let worldName: String
    public let title: String
    public let par: Int
    public let rows: [String]

    public var id: Int { index }

    public init(index: Int, world: Int, worldName: String, title: String, par: Int, rows: [String]) {
        self.index = index
        self.world = world
        self.worldName = worldName
        self.title = title
        self.par = par
        self.rows = rows
    }
}

public enum LevelCatalog {
    public static let worlds: [Int] = [1, 2, 3, 4, 5, 6]

    public static func worldName(_ world: Int) -> String {
        levels.first { $0.world == world }?.worldName ?? "Meadow"
    }

    public static let levels: [LevelDefinition] = [
        LevelDefinition(
            index: 1,
            world: 1,
            worldName: "Meadow",
            title: "First Nudge",
            par: 1,
            rows: ["#####", "#@$.#", "#####"]
        ),
        LevelDefinition(
            index: 2,
            world: 1,
            worldName: "Meadow",
            title: "Two Steps",
            par: 2,
            rows: ["#####", "# . #", "#   #", "# $ #", "# @ #", "#####"]
        ),
        LevelDefinition(
            index: 3,
            world: 1,
            worldName: "Meadow",
            title: "Keep Going",
            par: 2,
            rows: ["######", "#    #", "#@$ .#", "######"]
        ),
        LevelDefinition(
            index: 4,
            world: 1,
            worldName: "Meadow",
            title: "Around the Post",
            par: 3,
            rows: ["######", "# .  #", "# $# #", "#   @#", "######"]
        ),
        LevelDefinition(
            index: 5,
            world: 1,
            worldName: "Meadow",
            title: "Little Niche",
            par: 3,
            rows: ["#######", "#.    #", "#$#   #", "#  @  #", "#######"]
        ),
        LevelDefinition(
            index: 6,
            world: 1,
            worldName: "Meadow",
            title: "Far Side",
            par: 4,
            rows: ["#######", "#  .  #", "#  $# #", "#    ##", "#    @#", "#######"]
        ),
        LevelDefinition(
            index: 7,
            world: 2,
            worldName: "Orchard",
            title: "Quiet Corner",
            par: 5,
            rows: ["########", "# .##  #", "# $ #  #", "#   $. #", "# @    #", "########"]
        ),
        LevelDefinition(
            index: 8,
            world: 2,
            worldName: "Orchard",
            title: "Short Park",
            par: 5,
            rows: ["########", "# .    #", "# $##  #", "#  $ . #", "# @    #", "########"]
        ),
        LevelDefinition(
            index: 9,
            world: 2,
            worldName: "Orchard",
            title: "Daisy Pair",
            par: 6,
            rows: ["#######", "# . . #", "# $ $ #", "#  @  #", "#######"]
        ),
        LevelDefinition(
            index: 10,
            world: 2,
            worldName: "Orchard",
            title: "Corner Daisy",
            par: 6,
            rows: ["######", "#   .#", "# $  #", "#  @ #", "######"]
        ),
        LevelDefinition(
            index: 11,
            world: 2,
            worldName: "Orchard",
            title: "Side by Side",
            par: 7,
            rows: ["########", "# . .  #", "# $$   #", "#   @  #", "########"]
        ),
        LevelDefinition(
            index: 12,
            world: 2,
            worldName: "Orchard",
            title: "Down the Lane",
            par: 7,
            rows: ["########", "#  @   #", "# $  $ #", "##.  .##", "########"]
        ),
        LevelDefinition(
            index: 13,
            world: 3,
            worldName: "Clover",
            title: "Under the Hedge",
            par: 8,
            rows: ["##########", "#@ $ . $.#", "#        #", "##########"]
        ),
        LevelDefinition(
            index: 14,
            world: 3,
            worldName: "Clover",
            title: "Pass Between",
            par: 8,
            rows: ["########", "# .  . #", "# $##$ #", "#      #", "#  @   #", "########"]
        ),
        LevelDefinition(
            index: 15,
            world: 3,
            worldName: "Clover",
            title: "Two Sheds",
            par: 10,
            rows: ["#########", "# . # . #", "# $ # $ #", "#   #   #", "# @     #", "#########"]
        ),
        LevelDefinition(
            index: 16,
            world: 3,
            worldName: "Clover",
            title: "Push In",
            par: 11,
            rows: ["########", "# #### #", "# #. . #", "# $ $  #", "#  @   #", "########"]
        ),
        LevelDefinition(
            index: 17,
            world: 3,
            worldName: "Clover",
            title: "Berry Shelf",
            par: 11,
            rows: ["########", "# . . .#", "# $$$  #", "#   @  #", "########"]
        ),
        LevelDefinition(
            index: 18,
            world: 3,
            worldName: "Clover",
            title: "Cozy Nook",
            par: 13,
            rows: ["########", "# .#   #", "# $# $ #", "#   #. #", "# @    #", "########"]
        ),
        LevelDefinition(
            index: 19,
            world: 4,
            worldName: "Honey",
            title: "Honey Loop",
            par: 13,
            rows: ["#########", "# .   . #", "# $###$ #", "#   @   #", "# $###$ #", "# .   . #", "#########"]
        ),
        LevelDefinition(
            index: 20,
            world: 4,
            worldName: "Honey",
            title: "Second Thought",
            par: 13,
            rows: ["#######", "#@    #", "# $$  #", "# #.  #", "# #.  #", "#######"]
        ),
        LevelDefinition(
            index: 21,
            world: 4,
            worldName: "Honey",
            title: "Swap Sides",
            par: 14,
            rows: ["#######", "# . . #", "# $$$ #", "#  @  #", "#  .  #", "#######"]
        ),
        LevelDefinition(
            index: 22,
            world: 4,
            worldName: "Honey",
            title: "Four Corners",
            par: 14,
            rows: ["##########", "# .    . #", "# $ ## $ #", "#   @    #", "# $ ## $ #", "# .    . #", "##########"]
        ),
        LevelDefinition(
            index: 23,
            world: 4,
            worldName: "Honey",
            title: "Three Up",
            par: 15,
            rows: ["########", "# . . .#", "#      #", "# $$$  #", "#  @   #", "########"]
        ),
        LevelDefinition(
            index: 24,
            world: 4,
            worldName: "Honey",
            title: "Wall Gap",
            par: 16,
            rows: ["#########", "# .   . #", "# $$ ## #", "#    #  #", "# @  $ .#", "#########"]
        ),
        LevelDefinition(
            index: 25,
            world: 5,
            worldName: "Lantern",
            title: "In the Middle",
            par: 18,
            rows: ["#########", "# . $ . #", "# $ @ $ #", "# . $ . #", "#########"]
        ),
        LevelDefinition(
            index: 26,
            world: 5,
            worldName: "Lantern",
            title: "Long Lane",
            par: 19,
            rows: ["##########", "#.  .  . #", "#        #", "# $ $ $  #", "#   @    #", "##########"]
        ),
        LevelDefinition(
            index: 27,
            world: 5,
            worldName: "Lantern",
            title: "High Shelf",
            par: 20,
            rows: ["##########", "#. #. #. #", "#  #  #  #", "# $ $ $  #", "#    @   #", "##########"]
        ),
        LevelDefinition(
            index: 28,
            world: 5,
            worldName: "Lantern",
            title: "Offset",
            par: 20,
            rows: ["##########", "# . . .  #", "#  $ $ $ #", "# #      #", "#   @    #", "##########"]
        ),
        LevelDefinition(
            index: 29,
            world: 5,
            worldName: "Lantern",
            title: "Turnabout",
            par: 21,
            rows: ["#######", "# . . #", "# $$$ #", "# . @ #", "#######"]
        ),
        LevelDefinition(
            index: 30,
            world: 5,
            worldName: "Lantern",
            title: "Four Crates",
            par: 22,
            rows: ["##########", "# . . . .#", "#        #", "# $ $ $ $#", "#   @    #", "##########"]
        ),
        LevelDefinition(
            index: 31,
            world: 6,
            worldName: "Starlight",
            title: "Alcove Row",
            par: 23,
            rows: ["##########", "#. # . #.#", "#  #   # #", "# $ $ $  #", "#    @   #", "##########"]
        ),
        LevelDefinition(
            index: 32,
            world: 6,
            worldName: "Starlight",
            title: "Shed Corner",
            par: 23,
            rows: ["##########", "#@  #    #", "# $ # .$ #", "#   #  # #", "# $    # #", "#. .   # #", "##########"]
        ),
        LevelDefinition(
            index: 33,
            world: 6,
            worldName: "Starlight",
            title: "Corner Goals",
            par: 23,
            rows: ["########", "#.    .#", "# $  $ #", "#  @   #", "# $  $ #", "#.    .#", "########"]
        ),
        LevelDefinition(
            index: 34,
            world: 6,
            worldName: "Starlight",
            title: "Amber Path",
            par: 27,
            rows: ["##########", "#.      .#", "# $ ## $ #", "#   @    #", "# $ ## $ #", "#.      .#", "##########"]
        ),
        LevelDefinition(
            index: 35,
            world: 6,
            worldName: "Starlight",
            title: "Pocket Row",
            par: 29,
            rows: ["##########", "#. . .   #", "# ###    #", "# $ $ $  #", "#   @    #", "##########"]
        ),
        LevelDefinition(
            index: 36,
            world: 6,
            worldName: "Starlight",
            title: "Twin Pockets",
            par: 30,
            rows: ["#########", "# #. .# #", "# $   $ #", "#   @   #", "# $   $ #", "# #. .# #", "#########"]
        )
    ]

    public static func level(_ index: Int) -> LevelDefinition? {
        guard index >= 1, index <= levels.count else { return nil }
        return levels[index - 1]
    }
}
