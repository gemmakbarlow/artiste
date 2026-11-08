# Castle Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Castle Mode to Artiste. With the switch on, Nina picks one of six castles before every level, plays a generated castle-shaped puzzle in that castle's colors, and when she solves it the castle's princess steps out and waves.

**Architecture:**
- **Engine:** boards become arbitrary shapes. `BoardShape` plus a `Grid` that can be shaped, and stepping onto a non-board square bumps.
- **Castle data and puzzles:** a pure castle catalog with shapes, finished pictures, start square and roof layout, plus a seeded generator that turns (castle, level) into a `Level`.
- **Views:** a `BoardStyle` maps the four paint slots to colors and names (classic red/blue/green/yellow, or a castle's palette). A generalized `BoardView` draws any shape with castle outline art. Code-drawn `PrincessView`s and a reveal overlay replace "Good job!" in castles.
- **Navigation:** an `AppRouter` adds the castle picker between level select and the game.

**Tech Stack:** Swift 6.3, SwiftUI, iOS 26.0 (Xcode 26.5), Swift Testing, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-11-08-castle-mode-design.md`. It builds on `docs/superpowers/specs/2026-11-07-artiste-design.md`. Approved visual reference: `docs/superpowers/specs/assets/2026-11-08-castle-mode-mockup.html`. Its SVGs are the source for the princess and castle art.

## Global Constraints

- **Normal mode:** with Castle Mode off, behavior, the 15 `levels.json` levels and every existing test stay unchanged.
- **Copyright:** no Disney names, character designs or castle logos anywhere in code, assets or copy. Use only these names:
  - Castles: "Desert palace", "Ice palace", "Tall tower", "Rose castle", "Bayou palace", "Island fort".
  - Princesses: "Desert princess", "Ice queen", "Tower princess", "Rose princess", "Bayou princess", "Ocean voyager".
- **Castle boards:** 40–48 squares each, a bounding box of at most 8 columns × 8 rows, connected, with the start square on the bottom-left square of the lowest row.
- **Square sizes:** canvas castle squares at least **26 pt on iPad** and **20 pt on the 667 × 375 pt iPhone in landscape**. The target castle may be as small as half the canvas size.
- **Difficulty table** (spec §5), with slots = solution length + 2:

  | Levels | Empty squares | Solution length | Tray colors | Turns |
  |---|---|---|---|---|
  | 1–2 | 1 | 2–3 | 2 | none |
  | 3–4 | 2 | 3–4 | 2 | none |
  | 5–6 | 2–3 | 4–6 | 3 | allowed |
  | 7–9 | 3–4 | 5–7 | 3 | allowed |
  | 10–12 | 3–4 | 6–8 | 4 | allowed |
  | 13–15 | 4–5 | 8–10 | 4 | allowed |

- **Tray colors** = the castle's first N paint slots. Empty squares may only be squares whose picture slot is among those N.
- **Empty squares** in every castle are white with a dashed border in the castle's grout color.
- **Reveal:** the princess grows to about 55% of the screen height, standing in front of the dimmed canvas castle, with the target faded out. She waves 3 times, blinks every couple of seconds and hops once. The Next button appears after about 1.5 s. There are no fireworks.
- **Reduce Motion:** a still waving pose, no bounce or hop.
- **VoiceOver** announces exactly: `"The <princess name> waves hello! Good job!"`
- **Persistence:** Castle Mode is saved in `UserDefaults` under the key `"isCastleModeOn"`, and crowns under `"crownedLevelIDs"` (`[Int]`). Finishing a castle level marks it complete *and* crowned.
- **Copy and code style:** American spelling. SF Symbols only for icons; the castles and princesses are drawn in code. Swift 6, no new warnings.
- **Commands.** Use this test destination everywhere:

  ```
  xcodebuild test -project Artiste.xcodeproj -scheme Artiste -destination 'platform=iOS Simulator,OS=26.5,name=iPhone 17e' -only-testing:ArtisteTests/<Suite>
  ```

  Run the full suite by dropping `-only-testing`. Run `xcodegen generate` after adding files. End each commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

**Decision recorded here (the spec §9 "paint slots"):** keep the existing `PaintColor` enum and its cases as the four slot identifiers, with `red` = slot 1, `blue` = 2, `green` = 3 and `yellow` = 4. Add a doc comment saying so. All on-screen color and every spoken name goes through `BoardStyle` (Task 5). This keeps `levels.json`, `Action` tokens and all existing tests unchanged.

## Review Focus

1. **Next on level 15 in a castle** shows Home and never routes to a picker for a 16th level. Test: `AppRouterTests.nextAfterLastCastleLevelIsHome` (Task 9).
2. **Back from a castle game** returns to level select, not to the picker Nina already used. Test: `AppRouterTests.backFromCastleGameReturnsToLevelSelect` (Task 9).
3. **Walking into the gap between a tower and the keep**, a hole inside the bounding box, bumps exactly like leaving the grid. Test: `BoardShapeTests.movingIntoHoleBumps` (Task 1).
4. **VoiceOver says the castle's color names**, never "red" or "blue", inside a castle. Test: `BoardStyleTests.castleNamesReplaceClassicNames` (Task 5).
5. **Turning Castle Mode off after playing castles** returns every tap to the normal 5×5 level, with normal colors. Test: `AppRouterTests.castleModeOffOpensNormalLevel` (Task 9).

---

### Task 1: Shaped boards in the engine

**Files:**
- Create: `Artiste/Engine/BoardShape.swift`
- Modify: `Artiste/Engine/Grid.swift`
- Test: `ArtisteTests/BoardShapeTests.swift`

**Interfaces:**
- Produces:
  - `struct BoardShape: Hashable, Sendable`
    - `let width: Int`, `let height: Int`
    - `init(rows: [String])`: `#` = board square, `.` = not. It traps on ragged rows.
    - `static func full(width: Int, height: Int) -> BoardShape`
    - `func contains(_ p: Position) -> Bool`
    - `var positions: [Position]` (row-major)
    - `var count: Int`
    - `var isConnected: Bool` (4-neighbor)
    - `var bottomLeft: Position`: the lowest row's leftmost square
  - `Grid` gains:
    - `let shape: BoardShape`
    - `init(shape: BoardShape)`, all board squares empty
    - `init(shape: BoardShape, rows: [String]) throws(GridError)`: letters only on board squares, `.` elsewhere. A letter off the board throws `.badCharacter`.
    - `var width: Int`, `var height: Int`
  - `contains(_:)` now means `shape.contains`. `emptyCount` counts only board squares. `rows` renders `.` for off-board squares.
  - `Grid(rows:)` and `Grid()` keep producing a full 5 × 5 grid. `static let size = 5` stays for the classic levels.

- [ ] **Step 1: Write the failing tests** in `BoardShapeTests`:
  - **`parsesShapeRows`:** `BoardShape(rows: ["...##...","#..##..#","########"])` has width 8, height 3, count 14, `bottomLeft == Position(row: 2, col: 0)`, and `contains(Position(row: 0, col: 0)) == false`.
  - **`fullShapeMatchesClassicGrid`:** `Grid().shape == .full(width: 5, height: 5)`, and `Grid().emptyCount == 25`.
  - **`connectivity`:** the rose shape from Task 2 is connected; `BoardShape(rows: ["#.#"])` is not.
  - **`movingIntoHoleBumps`:**
    - Shape `["#.#","###"]`. From `(1,0)`, program `[.move(.up), .move(.right)]` gives the first step `.ok` at `(0,0)` and the second `.bumped` with position `(0,0)`.
    - From `(1,1)`, `[.move(.up)]` is `.bumped`.
  - **`shapedGridRejectsLetterOffBoard`:** `Grid(shape: BoardShape(rows: ["#."]), rows: ["RR"])` throws `.badCharacter("R")`.
- [ ] **Step 2: Run** `-only-testing:ArtisteTests/BoardShapeTests`. Expected: compile failure.
- [ ] **Step 3: Implement `BoardShape` and the `Grid` changes.**
  - Store cells as a flat `[PaintColor?]` of `width * height`.
  - Writes to off-board squares trap. Reads from them return nil.
  - `Interpreter` needs no change, because it already asks `grid.contains`.
- [ ] **Step 4: Run** `BoardShapeTests`, then the **full suite**. Expected: everything passes. That shows normal mode is unchanged.
- [ ] **Step 5: Commit** with `feat: support shaped boards in the engine`.

---

### Task 2: Castle catalog

**Files:**
- Create: `Artiste/Engine/Castle.swift`
- Modify: `Artiste/Engine/PaintColor.swift` (doc comment only: the cases are paint slots 1–4)
- Test: `ArtisteTests/CastleTests.swift`

**Interfaces:**
- Consumes: `BoardShape`, `Grid` (Task 1).
- Produces:
  - `enum CastleKind: String, CaseIterable, Codable, Hashable, Sendable, Identifiable { case desert, ice, tower, rose, bayou, island }`. This order is also the picker order. `id` is `rawValue`.
  - `struct Roof: Sendable, Hashable { enum Style { case spire, onionDome, thatch }; let columns: ClosedRange<Int>; let row: Int; let height: Double /* in squares */; let style: Style; let flag: Bool }`
  - `struct Castle: Sendable, Hashable, Identifiable`, with these fields:
    - `let kind: CastleKind`
    - `let name: String`, `let princessName: String`
    - `let shape: BoardShape`
    - `let picture: Grid`: the finished picture, every board square painted
    - `var start: Position { shape.bottomLeft }`
    - `let colorNames: [String]`: four names, one per slot, in `PaintColor.allCases` order
    - `let roofs: [Roof]`
    - `let battlementColumns: [Int]`, `let battlementRow: Int`
    - `static let all: [Castle]`, in `CastleKind.allCases` order
    - `static func castle(_ kind: CastleKind) -> Castle`
- Exact data, from the approved mockup:

  **Rose castle and Ice palace** share this shape, picture, roofs and battlements:
  - **Shape:** `["...##...","...##...","#..##..#","#..##..#","########","########","########","########"]` (44 squares).
  - **Picture:** `["...GY...","...YG...","R..GY..R","B..YG..B","RBRBRBRR","BRBRBRBB","RBRBRBRR","BRBRBRBB"]`.
  - **Roofs:**
    - `spire` over columns 0...0 at row 2, height 2.1, with a flag
    - `spire` over columns 7...7 at row 2, height 2.1, with a flag
    - `spire` over columns 3...4 at row 0, height 2.8, with a flag
  - **Battlements:** `battlementColumns: [1, 2, 5, 6]`, `battlementRow: 4`.

  **Names and colors:**

  | Castle | Princess | Slot names |
  |---|---|---|
  | Rose castle | Rose princess | "light pink", "hot pink", "rose", "blush white" |
  | Ice palace | Ice queen | "light blue", "sky blue", "deep blue", "snow white" |
  | Desert palace | Desert princess | "turquoise", "gold", "sand", "deep teal" |
  | Tall tower | Tower princess | "lavender", "purple", "gold", "pink" |
  | Bayou palace | Bayou princess | "lily green", "leaf green", "cream", "gold" |
  | Island fort | Ocean voyager | "ocean blue", "turquoise", "sand", "coral red" |

  **The other four castles:** the implementer designs their shape, picture and roofs from spec §4's "Shape idea" column, within the Global Constraints:
  - **Desert palace:** an onion dome using `onionDome` roofs, with the dome rows stepping inward.
  - **Island fort:** a `thatch` roof.
  - **Tall tower:** about 3 squares wide.
  - **Every picture** uses all four slots, in simple stripes or checker patterns.

- [ ] **Step 1: Write the failing tests** in `CastleTests`. Parameterize over `CastleKind.allCases`:
  - **`boardSizeWithinLimits`:** count is between 40 and 48, width and height are each ≤ 8, and the shape is connected.
  - **`pictureFillsBoard`:** `picture.shape == shape`, `picture.emptyCount == 0`, and the picture uses all four slots.
  - **`startIsBottomLeft`:** `shape.contains(start)`, and no board square is lower, or further left in the same row.
  - **`fourNamedColors`:** `colorNames.count == 4` and all are distinct.
  - **`roofsSitOnBoard`:** every roof's `columns` and `row` refer to board squares.
  - Not parameterized:
    - **`roseAndIceShareShape`:** `.castle(.rose).shape == .castle(.ice).shape`.
    - **`namesAreExact`:** the six castle names and six princess names equal the strings in Global Constraints.
- [ ] **Step 2: Run** `CastleTests`. Expected: compile failure.
- [ ] **Step 3: Implement `Castle.swift`** with the data above.
- [ ] **Step 4: Run** `CastleTests`. Expected: PASS.
- [ ] **Step 5: Commit** with `feat: add castle catalog`.

---

### Task 3: Castle puzzle generator

**Files:**
- Create: `Artiste/Engine/CastlePuzzles.swift`
- Modify: `Artiste/Engine/Level.swift` (add a memberwise init)
- Test: `ArtisteTests/CastlePuzzleTests.swift`

**Interfaces:**
- Consumes: `Castle`, `Grid`, `BoardShape`, `Interpreter`, `Action`, `Level`.
- Produces:
  - `Level.init(id: Int, start: Position, initial: Grid, target: Grid, solution: [Action], palette: [PaintColor])`
  - `struct CastleDifficulty: Sendable { let empties: ClosedRange<Int>; let length: ClosedRange<Int>; let trayColors: Int; let turnsAllowed: Bool; static func forLevel(_ id: Int) -> CastleDifficulty }`. It uses the exact table from Global Constraints.
  - `enum CastlePuzzles { static func level(_ id: Int, in castle: Castle) -> Level }`. It returns `target == castle.picture`, `start == castle.start` and `palette == Array(PaintColor.allCases.prefix(trayColors))`.
- **Algorithm** (the plan fixes these rules; the details are the implementer's):
  - Seed a SplitMix64 generator with `castleIndex * 1000 + id`, where `castleIndex` is the position in `CastleKind.allCases`.
  - Walk from `start` along board squares. When `turnsAllowed` is false, every move uses one direction, tried in the order right, up.
  - Pick empty squares among the visited squares, including possibly the start, whose picture slot is within the tray colors.
  - Solution = the walk's moves, with a `.paint(picture[p])` added on each chosen square as it's reached. Trim it after the last paint.
  - Accept the result only if the empty count and the length fall in the table row. Otherwise advance the seed and retry, up to 500 tries. Trap with a clear message if none fits, because the tests guarantee one does.
- [ ] **Step 1: Write the failing tests** in `CastlePuzzleTests`. Parameterize over all 90 `(CastleKind, 1...15)` pairs:
  - **`solutionPaintsTarget`:** running `Interpreter.steps(program: solution, from: start, on: initial)` never bumps, and the final grid equals `target`.
  - **`followsDifficultyRow`:** the empty count and `solution.count` are within the row, `slotCount <= 12`, and the palette has `trayColors` entries.
  - **`onlyTrayColorsArePainted`:** every `.paint` in the solution uses a palette color.
  - **`initialDiffersOnlyInEmpties`:** for every board square, `initial[p] == nil || initial[p] == target[p]`.
  - **`straightLineWhenNoTurns`:** for levels 1–4, all `.move` actions share one direction.
  - **`deterministic`:** two calls return equal `initial`, `solution` and `palette`.
  - Not parameterized: **`difficultyTable`:** spot-check `forLevel(1)`, `forLevel(5)`, `forLevel(10)` and `forLevel(15)` against the table.
- [ ] **Step 2: Run** `CastlePuzzleTests`. Expected: compile failure.
- [ ] **Step 3: Implement** `CastleDifficulty`, `CastlePuzzles` and the `Level` memberwise init.
- [ ] **Step 4: Run** `CastlePuzzleTests` and the full suite. Expected: PASS. If a castle can't meet a row, adjust that castle's picture or shape from Task 2, never the table.
- [ ] **Step 5: Commit** with `feat: generate castle puzzles`.

---

### Task 4: Castle Mode in progress and the view model

**Files:**
- Modify: `Artiste/Game/ProgressStore.swift`, `Artiste/Game/GameViewModel.swift`
- Test: `ArtisteTests/ProgressStoreTests.swift`, `ArtisteTests/GameViewModelTests.swift`

**Interfaces:**
- Consumes: `Castle`, `CastlePuzzles.level(_:in:)` (Task 3).
- Produces:
  - `ProgressStore`:
    - `var isCastleModeOn: Bool`, persisted on set under `"isCastleModeOn"`
    - `private(set) var crownedLevelIDs: Set<Int>`, under `"crownedLevelIDs"`
    - `func markCrowned(_ id: Int)`
  - `GameViewModel`:
    - `init(levels:levelIndex:progress:sound:stepDelay:castle: Castle? = nil)`
    - `let castle: Castle?`
    - When `castle` is set, `level` is `CastlePuzzles.level(levels[levelIndex].id, in: castle)`. Cache it for the current index.
    - On success with a castle, call both `markCompleted(level.id)` and `markCrowned(level.id)`.
    - `next()` is unchanged. Castle navigation happens in Task 9's router, not in the view model.
- [ ] **Step 1: Write the failing tests.**
  - `ProgressStoreTests`:
    - **`persistsCastleMode`**
    - **`persistsCrowns`**
    These follow the same pattern as `persistsMute`.
  - `GameViewModelTests`:
    - **`castleLevelUsesCastleBoard`:** a VM with `castle: .castle(.rose)` on level index 0 has `canvas.shape == Castle.castle(.rose).shape`, `marker == castle.start`, and `slots.count == level.solution.count + 2`.
    - **`solvingCastleLevelCrowns`:** fill the castle level's `solution` and play. Expect `.succeeded`, with `progress.completedLevelIDs` and `crownedLevelIDs` both containing 1.
    - **`normalLevelDoesNotCrown`:** solving level 1 without a castle leaves `crownedLevelIDs` empty.
- [ ] **Step 2: Run** `ProgressStoreTests` and `GameViewModelTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the changes.
- [ ] **Step 4: Run** both suites and the full suite. Expected: PASS.
- [ ] **Step 5: Commit** with `feat: castle mode progress and castle levels in the view model`.

---

### Task 5: Board styles (castle colors and names)

**Files:**
- Create: `Artiste/Views/BoardStyle.swift`
- Modify: `Artiste/Views/ActionTokenView.swift`, `Artiste/Views/TrayView.swift`, `Artiste/Views/SlotRowView.swift`
- Test: `ArtisteTests/BoardStyleTests.swift`

**Interfaces:**
- Consumes: `CastleKind`, `Castle.colorNames`.
- Produces:
  - `struct BoardStyle: Sendable, Equatable`, with these members:
    - `func color(_ slot: PaintColor) -> Color`
    - `func name(_ slot: PaintColor) -> String`
    - `let grout: Color`
    - `let motif: Motif?`
    - `enum Motif { case rose, snowflake, diamond, flower, lilyPad, wave }`
    - `static let classic`: today's `Theme` colors, names "red", "blue", "green" and "yellow", grout `Theme.gridLine`, no motif
    - `static func castle(_ kind: CastleKind) -> BoardStyle`
  - **Rose palette:** `#F8BBD0`, `#EC407A`, `#AD1457`, `#FFF0F5`, grout `#E9A8C4`, motif `.rose`.
  - **Ice palette:** `#BFE6FA`, `#64B5F6`, `#1E5FA8`, `#FFFFFF`, grout `#9CCBE8`, motif `.snowflake`.
  - **The other four:** the implementer picks the hex values, matching the color names. The four must be easy to tell apart, with an obvious lightness step between them. Motifs: desert `.diamond`, tower `.flower`, bayou `.lilyPad`, island `.wave`.
  - `ActionTokenView(action:size:style: BoardStyle = .classic)`. A paint token uses `style.color`.
  - `static func label(_ action: Action, style: BoardStyle = .classic) -> String` returns `"Paint <style.name(slot)>"`.
  - `TrayView` and `SlotRowView` take `style: BoardStyle` and pass it down.
- [ ] **Step 1: Write the failing tests** in `BoardStyleTests`:
  - **`classicMatchesTheme`:** `BoardStyle.classic.name(.red) == "red"`, and the label for `.paint(.blue)` is `"Paint blue"`.
  - **`castleNamesReplaceClassicNames`:** `ActionTokenView.label(.paint(.blue), style: .castle(.rose)) == "Paint hot pink"`, and `.castle(.ice).name(.yellow) == "snow white"`.
  - **`everyCastleHasFourDistinctColors`:** parameterized over `CastleKind`.
- [ ] **Step 2: Run** `BoardStyleTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the changes. Normal mode passes `.classic` everywhere, so it looks identical to today.
- [ ] **Step 4: Run** the full suite, then build. Expected: PASS, no warnings.
- [ ] **Step 5: Commit** with `feat: board styles with castle colors and names`.

---

### Task 6: Shaped board view, castle art and castle layout

**Files:**
- Create: `Artiste/Views/BoardView.swift` (replaces `GridView.swift`, which is deleted), `Artiste/Views/CastleArtView.swift`, `Artiste/Views/CastleLayout.swift`
- Modify: `Artiste/Views/GameView.swift` (use `BoardView` for normal mode only; castle wiring is Task 9)
- Test: `ArtisteTests/CastleLayoutTests.swift`

**Interfaces:**
- Consumes: `Grid.shape`, `BoardStyle`, `Castle` (`roofs`, `battlementColumns`, `battlementRow`).
- Produces:
  - `struct BoardView: View { init(grid: Grid, style: BoardStyle = .classic, castle: Castle? = nil, marker: Position? = nil, bump: (direction: Direction, count: Int)? = nil) }`
    - **Normal mode:** a 5 × 5 grid that draws exactly as `GridView` does today, including the marker, bump wobble, splat animation and accessibility labels.
    - **Shaped boards:**
      - Only board squares are drawn, each in `style.grout` with a rounded tile inside.
      - Painted squares get `style.color` plus a faint `style.motif` drawn in white.
      - Empty squares are white with a dashed `grout` border.
    - **Accessibility:** the label reads `"Row r, column c, <style.name or empty>[, marker]"`.
  - `struct CastleArtView: View { init(castle: Castle, cell: CGFloat) }`
    - Draws the black outline (stroke width `max(3, cell * 0.15)`) of the board's outer boundary, edge by edge, wherever a board square has a non-board neighbor.
    - Adds the battlements and the roofs from `castle.roofs`:
      - `spire`: a curved pointed roof with a band
      - `onionDome`
      - `thatch`
      - plus a flag when `flag` is set
    - The ice palace adds icicles under its roofs.
    - Its frame is the board size plus `headroom(castle) * cell` above. Roofs and flags never take board space.
  - `enum CastleLayout`:
    - `static func headroom(_ castle: Castle) -> Double`: the tallest roof plus its flag, in squares
    - `static func cellSizes(available: CGSize, castle: Castle, gap: CGFloat) -> (canvas: CGFloat, target: CGFloat)`
      - The canvas gets its cell from the height `(board height + headroom)` and about two-thirds of the width.
      - The target uses the leftover width, but is never smaller than half the canvas cell and never larger than the canvas cell.
- [ ] **Step 1: Write the failing tests** in `CastleLayoutTests`. Parameterize over `Castle.all`:
  - **`seCanvasCellIsAtLeast20`:** `cellSizes(available: CGSize(width: 470, height: 245), castle:, gap: 24).canvas >= 20`.
    - The 245 pt height is the SE game area once roofs rise into the header (spec §7, step 1). Task 9 must give the board at least this area.
  - **`iPadCanvasCellIsAtLeast26`:** `cellSizes(available: CGSize(width: 900, height: 520), …).canvas >= 26`.
  - **`targetBetweenHalfAndFullCanvas`:** `canvas / 2 <= target && target <= canvas`.
  - **`headroomCoversTallestRoof`:** headroom ≥ the largest `roof.height` plus 0.6 (the flag).
- [ ] **Step 2: Run** `CastleLayoutTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the three files, then swap `GameView` to `BoardView` for normal mode.
  - The board renders cells with `ForEach` over `grid.shape.positions`, positioned in a `ZStack` by `(col * cell, row * cell)`.
  - Port the roof and flag shapes from the mockup's SVG (`castle_mock` spire path: two quadratic curves to an apex, a band line, a flag triangle).
- [ ] **Step 4: Run** the full suite. Build, then add `#Preview`s:
  - each castle as a board, at a 26 pt cell, with its art
  - the normal 5 × 5 grid

  Look at the previews and confirm the normal grid looks unchanged and each castle reads as its castle.
- [ ] **Step 5: Commit** with `feat: shaped board view and castle art`.

---

### Task 7: The six princesses

**Files:**
- Create: `Artiste/Views/Princess/PrincessView.swift`, `Artiste/Views/Princess/PrincessParts.swift`
- Test: none (art). The check is visual via previews.

**Interfaces:**
- Consumes: `CastleKind`.
- Produces: `struct PrincessView: View { init(kind: CastleKind, pose: Pose = .idle, faceOnly: Bool = false) }`.
  - `enum Pose { case idle, waving }`. The view animates itself:
    - `waving`: the raised arm swings ±20° around the shoulder, 3 swings over about 1.5 s, then an occasional single wave every ~4 s.
    - Blinks every 2–3 s, for about 0.12 s.
    - `faceOnly` draws the head and hair only, for picker cards.
  - Drawn in a 100 × 150 coordinate space and scaled with `.aspectRatio(100/150, contentMode: .fit)`.
  - Shapes and colors are ported from the mockup's six SVGs (`docs/superpowers/specs/assets/2026-11-08-castle-mode-mockup.html`):
    - big eyes with a white highlight, rosy cheeks, a smile
    - the **short neck** (`rect x=44 y=72 w=12 h=15`)
    - hair and outfit as listed in spec §6
  - Shared parts (face, eyes, neck, arms) live in `PrincessParts.swift`. Each princess file section adds only her hair and outfit.
  - With Reduce Motion on, the arm holds the raised pose with no swing. Blinking still runs.
  - Accessibility: hidden. The reveal announces her (Task 8).
- [ ] **Step 1: Implement** `PrincessParts` and `PrincessView`.
- [ ] **Step 2: Build** and add a `#Preview` showing all six in a row, in `.waving` and `faceOnly`. Compare against the mockup:
  - each must have eyes, a smile, a short neck and her own hairstyle
  - none may resemble a copied Disney design beyond the hair and dress colors and the hairstyle idea
- [ ] **Step 3: Commit** with `feat: draw and animate the six princesses`.

---

### Task 8: Princess reveal

**Files:**
- Create: `Artiste/Views/PrincessRevealView.swift`
- Test: `ArtisteTests/PrincessRevealTests.swift`

**Interfaces:**
- Consumes: `PrincessView`, `Castle`.
- Produces:
  - `struct PrincessRevealView: View { init(castle: Castle, isLastLevel: Bool, onNext: @escaping () -> Void, onHome: @escaping () -> Void) }`
  - `static func announcement(for castle: Castle) -> String` returns exactly `"The \(castle.princessName) waves hello! Good job!"`.
  - **Sequence:**
    1. A 0.3 s black dim at 25%.
    2. An arched door outline swings open, using `rotation3DEffect` about its left edge, 0.4 s. The reveal is placed over the canvas castle by the caller (Task 9), so the door sits at the bottom-middle of the keep.
    3. The princess scales from 0.2 to 1 with `.spring(bounce: 0.35)`, about 0.6 s, to a height of 55% of the container, centered on the castle.
    4. One hop: a y-offset of −12 pt and back.
    5. A couple of sparkles (`sparkles` SF Symbol fading).
    6. After 1.5 s, the Next button (or Home on the last level) and the small "Levels" button fade in. They are styled like `SuccessOverlayView`'s.
  - The success sound plays via the existing view model, so this view adds none.
  - **Reduce Motion:** skip the scale, hop and door swing; just fade her in, in the waving pose.
  - Accessibility: `.isModal`.
- [ ] **Step 1: Write the failing test** **`announcementText`:** `PrincessRevealView.announcement(for: .castle(.ice)) == "The Ice queen waves hello! Good job!"`.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Implement** the view and add a `#Preview` for each castle.
- [ ] **Step 4: Run** the test. Expected: PASS. Build, and check the preview sequence by eye.
- [ ] **Step 5: Commit** with `feat: princess reveal`.

---

### Task 9: Navigation, Castle Mode switch, castle picker and castle game screen

**Files:**
- Create: `Artiste/Views/AppRouter.swift`, `Artiste/Views/CastlePickerView.swift`
- Modify: `Artiste/Views/RootView.swift`, `Artiste/Views/LevelSelectView.swift`, `Artiste/Views/GameView.swift`, `Artiste/ArtisteApp.swift` (inject the router)
- Test: `ArtisteTests/AppRouterTests.swift`

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `enum Route: Hashable { case level(index: Int); case castlePicker(index: Int); case castleLevel(index: Int, castle: CastleKind) }`
  - `@MainActor @Observable final class AppRouter`:
    - `init(levelCount: Int)`
    - `var path: [Route]`
    - `func openLevel(_ index: Int, castleModeOn: Bool)`: appends `.castlePicker(index)` when Castle Mode is on, `.level(index)` when it's off
    - `func pickCastle(_ kind: CastleKind)`: replaces the top `.castlePicker(i)` with `.castleLevel(i, kind)`
    - `func nextAfterCastleLevel()`: replaces the top `.castleLevel(i, _)` with `.castlePicker(i + 1)`, or pops to root if `i` is the last level
    - `func backToLevelSelect()`: sets `path = []`
  - `GameView(levelIndex:castle: CastleKind? = nil)`
  - `CastlePickerView(levelIndex:)`
- **Behavior:**
  - **Level select:**
    - A **Castle Mode** switch at the top-left: a `crown.fill` symbol, a "Castle Mode" label and a green `Toggle`, bound to `progress.isCastleModeOn`.
    - Tiles call `router.openLevel`.
    - A crowned level shows a small `crown.fill` badge in gold (`#E8B23A`) on white, at the tile's top-left. The checkmark stays at the top-right.
  - **Castle picker:**
    - Header "Pick your castle!", with "Level N" under it and a back button that calls `backToLevelSelect()`.
    - Six cards in 2 rows of 3, in `CastleKind.allCases` order. Each card shows `CastleArtView` with an empty board outline, the `PrincessView(faceOnly: true)` and the castle name.
    - Cards are at least 120 pt wide on iPhone and 180 pt on iPad.
    - Tapping a card calls `pickCastle`.
  - **Castle game screen:**
    - The `GameView` builds its VM with `castle: .castle(kind)`, and the tray and slots use `BoardStyle.castle(kind)`.
    - Both boards are `BoardView` + `CastleArtView`, sized by `CastleLayout.cellSizes`.
    - On iPhone, the header in castle mode is two corner buttons overlaid on the board area (no "Level N" title). The board area reaches the top safe-area edge, so the roofs rise between the buttons.
    - The back button calls `backToLevelSelect()`.
    - On success, show `PrincessRevealView`, placed over the canvas castle, instead of `SuccessOverlayView`. Its Next button calls `nextAfterCastleLevel()`, and Home or Levels call `backToLevelSelect()`.
    - Post the announcement from Task 8 instead of "Good job!".
- [ ] **Step 1: Write the failing tests** in `AppRouterTests` (`levelCount: 15`):
  - **`castleModeOnOpensPicker`:** `openLevel(2, castleModeOn: true)` gives `path == [.castlePicker(index: 2)]`.
  - **`castleModeOffOpensNormalLevel`:** `openLevel(2, castleModeOn: false)` gives `[.level(index: 2)]`.
  - **`pickingReplacesPicker`:** then `pickCastle(.ice)` gives `[.castleLevel(index: 2, castle: .ice)]`.
  - **`nextGoesToPickerForNextLevel`:** `nextAfterCastleLevel()` gives `[.castlePicker(index: 3)]`.
  - **`nextAfterLastCastleLevelIsHome`:** from `[.castleLevel(index: 14, castle: .rose)]`, `nextAfterCastleLevel()` gives `path == []`.
  - **`backFromCastleGameReturnsToLevelSelect`:** from `[.castleLevel(index: 4, castle: .tower)]`, `backToLevelSelect()` gives `[]`.
- [ ] **Step 2: Run** `AppRouterTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the router and wire the views. `RootView` holds `NavigationStack(path: $router.path)`, with `navigationDestination(for: Route.self)` and `.id(route)` on each destination.
- [ ] **Step 4: Run** the full suite. Expected: PASS. Then try it on the iPhone 17e simulator:
  - Turn on Castle Mode → tap level 1 → pick the Rose castle.
  - Solve it by tapping. The princess reveal should show, then Next goes to the picker for level 2.
  - Back returns to level select, where level 1 shows a checkmark and a crown.
  - Turn Castle Mode off, tap level 1, and check it's the normal 5 × 5 level.
- [ ] **Step 5: Commit** with `feat: castle mode navigation, picker and castle game screen`.

---

### Task 10: Device pass and play-through

**Files:**
- Modify: only what the checks below turn up.

- [ ] **Step 1: Check the smallest phone.**
  - Add a `#Preview` at `.fixedLayout(width: 667, height: 375)` for a level-15 castle level in each castle.
  - Confirm that 12 slots fit, the roofs don't cover the back or mute buttons, and the canvas cells are at least 20 pt. Use `CastleLayout` values, logged in a DEBUG preview overlay if needed, and remove it before committing.
- [ ] **Step 2: Check iPhone and iPad.**
  - On the iPhone 17e and iPad Pro 11-inch (M5) simulators, play level 1 and level 13 in **every** castle using the generated solutions.
  - Watch each princess's reveal, and check Reduce Motion (Settings → Accessibility → Motion) on one castle.
- [ ] **Step 3: Check VoiceOver** using an accessibility dump:
  - the castle picker cards
  - castle paint tokens ("Add paint hot pink")
  - the reveal announcement
- [ ] **Step 4: Run the full suite.** Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5: Commit** with `chore: castle mode device pass`.
