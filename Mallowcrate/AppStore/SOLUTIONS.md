# Mallowcrate level solutions

Every level was solved with breadth-first search over single steps
(walk or push). `par` is that optimal length. The same move strings are
replayed by `MallowcrateCoreTests` through the Swift rules engine, so the
Python search and the shipping rules agree.

Dead squares are precomputed by pulling a lone crate backward off each
daisy. A push onto a dead square is pruned. Pair and 2x2 freezes that
can never move again are pruned too. Neither rule drops a state that
could still reach a solution.

| # | World | Title | Crates | Size | Par | Nodes | Solution |
|---|-------|-------|--------|------|-----|-------|----------|
| 1 | Meadow | First Nudge | 1 | 5×3 | 1 | 2 | `R` |
| 2 | Meadow | Two Steps | 1 | 5×6 | 2 | 5 | `UU` |
| 3 | Meadow | Keep Going | 1 | 6×4 | 2 | 7 | `RR` |
| 4 | Meadow | Around the Post | 1 | 6×5 | 3 | 7 | `LLU` |
| 5 | Meadow | Little Niche | 1 | 7×5 | 3 | 12 | `LLU` |
| 6 | Meadow | Far Side | 1 | 7×6 | 4 | 7 | `LULU` |
| 7 | Orchard | Quiet Corner | 2 | 8×6 | 5 | 27 | `UUDRR` |
| 8 | Orchard | Short Park | 2 | 8×6 | 5 | 35 | `UUDRR` |
| 9 | Orchard | Daisy Pair | 2 | 7×5 | 6 | 44 | `LUDRRU` |
| 10 | Orchard | Corner Daisy | 1 | 6×5 | 6 | 31 | `LULURR` |
| 11 | Orchard | Side by Side | 2 | 8×5 | 7 | 73 | `LLURDRU` |
| 12 | Orchard | Down the Lane | 2 | 8×5 | 7 | 53 | `LDURRRD` |
| 13 | Clover | Under the Hedge | 2 | 10×4 | 8 | 56 | `RRRDRRUR` |
| 14 | Clover | Pass Between | 2 | 8×6 | 8 | 49 | `ULUDRRRU` |
| 15 | Clover | Two Sheds | 2 | 9×6 | 10 | 68 | `UUDDRRRURU` |
| 16 | Clover | Push In | 2 | 8×6 | 11 | 169 | `LLURDRURDRU` |
| 17 | Clover | Berry Shelf | 3 | 8×5 | 11 | 358 | `UDLLURRRDRU` |
| 18 | Clover | Cozy Nook | 2 | 8×6 | 13 | 55 | `UUDDRRRURUULD` |
| 19 | Honey | Honey Loop | 4 | 9×7 | 13 | 640 | `LLUDDURRRRUDD` |
| 20 | Honey | Second Thought | 2 | 7×6 | 13 | 95 | `RRDDUULLDRURD` |
| 21 | Honey | Swap Sides | 3 | 7×6 | 14 | 1150 | `LUDRRRUULLDDRU` |
| 22 | Honey | Four Corners | 4 | 10×7 | 14 | 2120 | `LLUDDURRRRRUDD` |
| 23 | Honey | Three Up | 3 | 8×6 | 15 | 4460 | `UDLUURDRUDRDRUU` |
| 24 | Honey | Wall Gap | 3 | 9×6 | 16 | 2369 | `UURDDRRRLLUULURR` |
| 25 | Lantern | In the Middle | 4 | 9×5 | 18 | 6222 | `LULDRRRDRULULLDDRR` |
| 26 | Lantern | Long Lane | 3 | 10×6 | 19 | 21477 | `UUDLLDLUUDRRRRRDRUU` |
| 27 | Lantern | High Shelf | 3 | 10×6 | 20 | 5098 | `URDRUUDDLLLUUDLLDLUU` |
| 28 | Lantern | Offset | 3 | 10×6 | 20 | 13287 | `ULURULRRRRRDLDLULDLU` |
| 29 | Lantern | Turnabout | 3 | 7×5 | 21 | 921 | `UDLLLUURDRDRRUULLDDRU` |
| 30 | Lantern | Four Crates | 4 | 10×6 | 22 | 39012 | `UUDDLLUUDDRRRRUUDDRRUU` |
| 31 | Starlight | Alcove Row | 3 | 10×6 | 23 | 9993 | `LLULDLUUDRRRDRUUDRRDRUU` |
| 32 | Starlight | Shed Corner | 3 | 10×7 | 23 | 7201 | `DRURDDDLULDRRRRUUURRRDL` |
| 33 | Starlight | Corner Goals | 4 | 8×7 | 23 | 431151 | `ULDDULURRRRDRUDLDLDRLLL` |
| 34 | Starlight | Amber Path | 4 | 10×7 | 27 | 509879 | `LULDLUDRDRDLRRRRURUULURDDRD` |
| 35 | Starlight | Pocket Row | 3 | 10×6 | 29 | 14722 | `LULDLUUDRRRDRUURULLRDDDRUURUL` |
| 36 | Starlight | Twin Pockets | 4 | 9×7 | 30 | 71682 | `LLLURDLDRURUDDURRRRULDRDLULUDD` |
