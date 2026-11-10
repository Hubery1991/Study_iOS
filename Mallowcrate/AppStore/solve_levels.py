#!/usr/bin/env python3
"""Handcrafted Mallowcrate levels and a breadth-first solver.

Rules match the Swift engine: one step at a time, push a single crate,
no pulling, no walking through walls or crates. A level is solved when
every crate stands on a daisy. Search is optimal (fewest steps).

Static dead squares and permanent freezes only drop states that can never
lead to a solution. A square is dead when a lone crate could not be pushed
from it onto any daisy.

    python3 Mallowcrate/AppStore/solve_levels.py

Rewrites the Swift catalog, the verified-solution fixture, levels.json,
and SOLUTIONS.md.
"""

from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "Sources" / "MallowcrateCore" / "LevelCatalog.swift"
SOLUTIONS = ROOT / "Tests" / "MallowcrateCoreTests" / "VerifiedSolutions.swift"
REPORT = ROOT / "AppStore" / "SOLUTIONS.md"
LEVELS_JSON = ROOT / "AppStore" / "levels.json"

WORLD_NAMES = {
    1: "Meadow",
    2: "Orchard",
    3: "Clover",
    4: "Honey",
    5: "Lantern",
    6: "Starlight",
}

# Ordered, original layouts. Six worlds of six. Not taken from a published set.
DRAFTS: list[tuple[str, list[str]]] = [
    ("First Nudge", [
        "#####",
        "#@$.#",
        "#####",
    ]),
    ("Two Steps", [
        "#####",
        "# . #",
        "#   #",
        "# $ #",
        "# @ #",
        "#####",
    ]),
    ("Keep Going", [
        "######",
        "#    #",
        "#@$ .#",
        "######",
    ]),
    ("Around the Post", [
        "######",
        "# .  #",
        "# $# #",
        "#   @#",
        "######",
    ]),
    ("Little Niche", [
        "#######",
        "#.    #",
        "#$#   #",
        "#  @  #",
        "#######",
    ]),
    ("Far Side", [
        "#######",
        "#  .  #",
        "#  $# #",
        "#    ##",
        "#    @#",
        "#######",
    ]),
    ("Quiet Corner", [
        "########",
        "# .##  #",
        "# $ #  #",
        "#   $. #",
        "# @    #",
        "########",
    ]),
    ("Short Park", [
        "########",
        "# .    #",
        "# $##  #",
        "#  $ . #",
        "# @    #",
        "########",
    ]),
    ("Daisy Pair", [
        "#######",
        "# . . #",
        "# $ $ #",
        "#  @  #",
        "#######",
    ]),
    ("Corner Daisy", [
        "######",
        "#   .#",
        "# $  #",
        "#  @ #",
        "######",
    ]),
    ("Side by Side", [
        "########",
        "# . .  #",
        "# $$   #",
        "#   @  #",
        "########",
    ]),
    ("Down the Lane", [
        "########",
        "#  @   #",
        "# $  $ #",
        "##.  .##",
        "########",
    ]),
    ("Under the Hedge", [
        "##########",
        "#@ $ . $.#",
        "#        #",
        "##########",
    ]),
    ("Pass Between", [
        "########",
        "# .  . #",
        "# $##$ #",
        "#      #",
        "#  @   #",
        "########",
    ]),
    ("Two Sheds", [
        "#########",
        "# . # . #",
        "# $ # $ #",
        "#   #   #",
        "# @     #",
        "#########",
    ]),
    ("Push In", [
        "########",
        "# #### #",
        "# #. . #",
        "# $ $  #",
        "#  @   #",
        "########",
    ]),
    ("Berry Shelf", [
        "########",
        "# . . .#",
        "# $$$  #",
        "#   @  #",
        "########",
    ]),
    ("Cozy Nook", [
        "########",
        "# .#   #",
        "# $# $ #",
        "#   #. #",
        "# @    #",
        "########",
    ]),
    ("Honey Loop", [
        "#########",
        "# .   . #",
        "# $###$ #",
        "#   @   #",
        "# $###$ #",
        "# .   . #",
        "#########",
    ]),
    ("Second Thought", [
        "#######",
        "#@    #",
        "# $$  #",
        "# #.  #",
        "# #.  #",
        "#######",
    ]),
    ("Swap Sides", [
        "#######",
        "# . . #",
        "# $$$ #",
        "#  @  #",
        "#  .  #",
        "#######",
    ]),
    ("Four Corners", [
        "##########",
        "# .    . #",
        "# $ ## $ #",
        "#   @    #",
        "# $ ## $ #",
        "# .    . #",
        "##########",
    ]),
    ("Three Up", [
        "########",
        "# . . .#",
        "#      #",
        "# $$$  #",
        "#  @   #",
        "########",
    ]),
    ("Wall Gap", [
        "#########",
        "# .   . #",
        "# $$ ## #",
        "#    #  #",
        "# @  $ .#",
        "#########",
    ]),
    ("In the Middle", [
        "#########",
        "# . $ . #",
        "# $ @ $ #",
        "# . $ . #",
        "#########",
    ]),
    ("Long Lane", [
        "##########",
        "#.  .  . #",
        "#        #",
        "# $ $ $  #",
        "#   @    #",
        "##########",
    ]),
    ("High Shelf", [
        "##########",
        "#. #. #. #",
        "#  #  #  #",
        "# $ $ $  #",
        "#    @   #",
        "##########",
    ]),
    ("Offset", [
        "##########",
        "# . . .  #",
        "#  $ $ $ #",
        "# #      #",
        "#   @    #",
        "##########",
    ]),
    ("Turnabout", [
        "#######",
        "# . . #",
        "# $$$ #",
        "# . @ #",
        "#######",
    ]),
    ("Four Crates", [
        "##########",
        "# . . . .#",
        "#        #",
        "# $ $ $ $#",
        "#   @    #",
        "##########",
    ]),
    ("Alcove Row", [
        "##########",
        "#. # . #.#",
        "#  #   # #",
        "# $ $ $  #",
        "#    @   #",
        "##########",
    ]),
    ("Shed Corner", [
        "##########",
        "#@  #    #",
        "# $ # .$ #",
        "#   #  # #",
        "# $    # #",
        "#. .   # #",
        "##########",
    ]),
    ("Corner Goals", [
        "########",
        "#.    .#",
        "# $  $ #",
        "#  @   #",
        "# $  $ #",
        "#.    .#",
        "########",
    ]),
    ("Amber Path", [
        "##########",
        "#.      .#",
        "# $ ## $ #",
        "#   @    #",
        "# $ ## $ #",
        "#.      .#",
        "##########",
    ]),
    ("Pocket Row", [
        "##########",
        "#. . .   #",
        "# ###    #",
        "# $ $ $  #",
        "#   @    #",
        "##########",
    ]),
    ("Twin Pockets", [
        "#########",
        "# #. .# #",
        "# $   $ #",
        "#   @   #",
        "# $   $ #",
        "# #. .# #",
        "#########",
    ]),
]

DIRS = ((-1, 0, "U"), (1, 0, "D"), (0, -1, "L"), (0, 1, "R"))


def parse(rows: list[str]):
    if not rows or any(len(row) != len(rows[0]) for row in rows):
        raise ValueError("rows must be rectangular")
    height, width = len(rows), len(rows[0])
    if width > 10 or height > 8:
        raise ValueError(f"board {width}x{height} is larger than 10x8")
    walls: set[tuple[int, int]] = set()
    goals: set[tuple[int, int]] = set()
    crates: set[tuple[int, int]] = set()
    player = None
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch == "#":
                walls.add((r, c))
            elif ch in ".+*":
                goals.add((r, c))
            if ch in "@+":
                if player is not None:
                    raise ValueError("two players")
                player = (r, c)
            elif ch in "$*":
                crates.add((r, c))
            elif ch not in "#. ":
                raise ValueError(f"bad tile {ch!r}")
    if player is None:
        raise ValueError("no player")
    if not crates or len(crates) != len(goals):
        raise ValueError(f"crate/goal mismatch {len(crates)} vs {len(goals)}")
    if goals <= crates:
        raise ValueError("level is already solved")
    return width, height, walls, goals, player, crates


def dead_squares(width, height, walls, goals):
    def floor(r: int, c: int) -> bool:
        return 0 <= r < height and 0 <= c < width and (r, c) not in walls

    alive = set(goals)
    queue = deque(goals)
    while queue:
        r, c = queue.popleft()
        for dr, dc, _ in DIRS:
            sr, sc = r - dr, c - dc
            pr, pc = r - 2 * dr, c - 2 * dc
            if floor(sr, sc) and floor(pr, pc) and (sr, sc) not in alive:
                alive.add((sr, sc))
                queue.append((sr, sc))
    dead = set()
    for r in range(height):
        for c in range(width):
            if floor(r, c) and (r, c) not in goals and (r, c) not in alive:
                dead.add((r, c))
    return dead


def permanent_freeze(crates, walls, goals, width, height) -> bool:
    def wallish(r: int, c: int) -> bool:
        return not (0 <= r < height and 0 <= c < width) or (r, c) in walls

    for r, c in crates:
        if (r, c + 1) in crates:
            vertical = ((r - 1, c), (r + 1, c), (r - 1, c + 1), (r + 1, c + 1))
            if all(wallish(rr, cc) for rr, cc in vertical):
                if (r, c) not in goals or (r, c + 1) not in goals:
                    return True
        if (r + 1, c) in crates:
            horizontal = ((r, c - 1), (r, c + 1), (r + 1, c - 1), (r + 1, c + 1))
            if all(wallish(rr, cc) for rr, cc in horizontal):
                if (r, c) not in goals or (r + 1, c) not in goals:
                    return True
        if (r, c + 1) in crates and (r + 1, c) in crates and (r + 1, c + 1) in crates:
            square = {(r, c), (r, c + 1), (r + 1, c), (r + 1, c + 1)}
            if not square <= goals:
                return True
    return False


def solve(rows: list[str], node_limit: int = 1_500_000):
    width, height, walls, goals, player, crates = parse(rows)
    dead = dead_squares(width, height, walls, goals)
    if crates & dead:
        return None, 0, "start crate on a dead square"
    start = (player, frozenset(crates))
    queue: deque[tuple[tuple, str]] = deque([(start, "")])
    seen = {start}
    nodes = 0
    while queue:
        (pos, boxes), path = queue.popleft()
        nodes += 1
        if nodes > node_limit:
            return None, nodes, "node limit"
        if goals <= boxes:
            return path, nodes, "ok"
        r, c = pos
        for dr, dc, name in DIRS:
            nr, nc = r + dr, c + dc
            if (nr, nc) in walls or not (0 <= nr < height and 0 <= nc < width):
                continue
            nboxes = boxes
            if (nr, nc) in boxes:
                br, bc = nr + dr, nc + dc
                if (
                    (br, bc) in walls
                    or (br, bc) in boxes
                    or not (0 <= br < height and 0 <= bc < width)
                ):
                    continue
                if (br, bc) in dead:
                    continue
                nboxes = frozenset((boxes - {(nr, nc)}) | {(br, bc)})
                if permanent_freeze(nboxes, walls, goals, width, height):
                    continue
            state = ((nr, nc), nboxes)
            if state in seen:
                continue
            seen.add(state)
            queue.append((state, path + name))
    return None, nodes, "no solution"


def swift_rows(rows: list[str]) -> str:
    return "[" + ", ".join(json.dumps(row) for row in rows) + "]"


def write_outputs(chosen: list[dict]) -> None:
    entries = []
    for level in chosen:
        entries.append(
            "        LevelDefinition(\n"
            f"            index: {level['index']},\n"
            f"            world: {level['world']},\n"
            f"            worldName: {json.dumps(level['worldName'])},\n"
            f"            title: {json.dumps(level['title'])},\n"
            f"            par: {level['par']},\n"
            f"            rows: {swift_rows(level['rows'])}\n"
            "        )"
        )
    catalog = f"""import Foundation

/// Handcrafted puzzles. `par` is the fewest steps found by the breadth-first
/// solver in `AppStore/solve_levels.py`. Every catalog entry has a verified solution.
public struct LevelDefinition: Equatable, Identifiable, Sendable {{
    public let index: Int
    public let world: Int
    public let worldName: String
    public let title: String
    public let par: Int
    public let rows: [String]

    public var id: Int {{ index }}

    public init(index: Int, world: Int, worldName: String, title: String, par: Int, rows: [String]) {{
        self.index = index
        self.world = world
        self.worldName = worldName
        self.title = title
        self.par = par
        self.rows = rows
    }}
}}

public enum LevelCatalog {{
    public static let worlds: [Int] = [1, 2, 3, 4, 5, 6]

    public static func worldName(_ world: Int) -> String {{
        levels.first {{ $0.world == world }}?.worldName ?? "Meadow"
    }}

    public static let levels: [LevelDefinition] = [
{",\n".join(entries)}
    ]

    public static func level(_ index: Int) -> LevelDefinition? {{
        guard index >= 1, index <= levels.count else {{ return nil }}
        return levels[index - 1]
    }}
}}
"""
    CATALOG.parent.mkdir(parents=True, exist_ok=True)
    CATALOG.write_text(catalog)

    pairs = ",\n".join(f'        {level["index"]}: "{level["solution"]}"' for level in chosen)
    SOLUTIONS.parent.mkdir(parents=True, exist_ok=True)
    SOLUTIONS.write_text(
        f"""import Foundation

/// Optimal step strings from the breadth-first solver. U D L R are single steps.
/// Replayed by the test suite against the Swift rules engine.
enum VerifiedSolutions {{
    static let moves: [Int: String] = [
{pairs}
    ]
}}
"""
    )

    public_levels = []
    for level in chosen:
        public_levels.append({
            "index": level["index"],
            "world": level["world"],
            "worldName": level["worldName"],
            "title": level["title"],
            "par": level["par"],
            "crates": level["crates"],
            "rows": level["rows"],
            "solution": level["solution"],
            "nodes": level["nodes"],
        })
    LEVELS_JSON.write_text(json.dumps(public_levels, indent=2) + "\n")

    lines = [
        "# Mallowcrate level solutions",
        "",
        "Every level was solved with breadth-first search over single steps",
        "(walk or push). `par` is that optimal length. The same move strings are",
        "replayed by `MallowcrateCoreTests` through the Swift rules engine, so the",
        "Python search and the shipping rules agree.",
        "",
        "Dead squares are precomputed by pulling a lone crate backward off each",
        "daisy. A push onto a dead square is pruned. Pair and 2x2 freezes that",
        "can never move again are pruned too. Neither rule drops a state that",
        "could still reach a solution.",
        "",
        "| # | World | Title | Crates | Size | Par | Nodes | Solution |",
        "|---|-------|-------|--------|------|-----|-------|----------|",
    ]
    for level in chosen:
        rows = level["rows"]
        lines.append(
            f"| {level['index']} | {level['worldName']} | {level['title']} | "
            f"{level['crates']} | {len(rows[0])}×{len(rows)} | {level['par']} | "
            f"{level['nodes']} | `{level['solution']}` |"
        )
    lines.append("")
    REPORT.write_text("\n".join(lines))


def main() -> None:
    if len(DRAFTS) != 36:
        print(f"expected 36 drafts, found {len(DRAFTS)}")
        sys.exit(1)
    chosen = []
    for number, (title, rows) in enumerate(DRAFTS, start=1):
        world = (number - 1) // 6 + 1
        try:
            path, nodes, status = solve(rows)
        except ValueError as error:
            print(f"INVALID {number} {title}: {error}")
            sys.exit(1)
        if not path:
            print(f"FAIL {number} {title}: {status} ({nodes} nodes)")
            sys.exit(1)
        _, _, _, _, _, crates = parse(rows)
        chosen.append({
            "index": number,
            "world": world,
            "worldName": WORLD_NAMES[world],
            "title": title,
            "rows": rows,
            "solution": path,
            "par": len(path),
            "nodes": nodes,
            "crates": len(crates),
        })
        print(
            f"OK {number:02} {WORLD_NAMES[world]:10} {title:16} "
            f"par={len(path):3} crates={len(crates)} nodes={nodes}"
        )
    titles = [level["title"] for level in chosen]
    if len(titles) != len(set(titles)):
        print("duplicate titles")
        sys.exit(1)
    maps = [tuple(level["rows"]) for level in chosen]
    if len(maps) != len(set(maps)):
        print("duplicate maps")
        sys.exit(1)
    write_outputs(chosen)
    pars = [level["par"] for level in chosen]
    print(f"Wrote {len(chosen)} levels. Pars: {' '.join(str(p) for p in pars)}")


if __name__ == "__main__":
    main()
