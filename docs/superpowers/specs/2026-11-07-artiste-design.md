# Artiste — Design Spec

**Date:** 2026-11-07
**Status:** Draft for review

## 1. Summary

Artiste is a SwiftUI game for iPad and iPhone (landscape only) that teaches young children sequencing — the core idea behind programming. Each level shows a **target picture** on a 5×5 grid and a **canvas** grid that is partly painted. The child drags arrow and paint-drop actions into a row of slots, taps **Play**, and watches a marker walk the grid running each action in turn. If the canvas matches the target, fireworks and a **Next** button appear. If not, the marker stays where it stopped, and the child must tap **Reset** before trying again.

Artiste should look and feel very similar to the game seen at the library: the same screen layout, color scheme and chunky round controls (see §6). All icons are SF Symbols, and the 15 levels are Artiste's own designs.

## 2. Goals and non-goals

**Goals**
- Big, bright, tappable/draggable elements that suit 4–7 year olds.
- 15 hand-made 5×5 levels, with colors introduced gradually.
- A simple loop: build → Play → watch → succeed or Reset.
- Works fully offline, with no accounts, ads or network calls.

**Non-goals (v1)**
- Level editor, procedurally generated levels, endless mode.
- Loops, functions or other advanced programming ideas.
- Localization (English only, but the UI should use icons almost everywhere so it reads without text).
- Cloud sync, analytics, in-app purchases.

## 3. Platform and tech

- Swift 6, SwiftUI. Deployment target is the **latest iOS/iPadOS** version that the current Xcode supports, with no back-deployment. This means modern APIs (`@Observable`, `Transferable`, `.draggable`/`.dropDestination`, the newest SF Symbols) can be used freely.
- Icons: **SF Symbols only**, with no custom image assets apart from the app icon.
- Universal app: iPad and iPhone, **landscape left/right only**.
- No third-party dependencies.
- Tests: Swift Testing (`import Testing`) for the game engine and level data.
- Xcode project: `Artiste.xcodeproj`, app target `Artiste`, test target `ArtisteTests`.

## 4. Gameplay rules

### 4.1 Grid
- Always 5×5. Coordinates are `(row, col)`, with `(0,0)` at the top-left.
- Each cell is either **empty (white)** or painted one of the colors in `PaintColor`.
- The marker starts at the level's `start` position (top-left `(0,0)` unless a level says otherwise).

### 4.2 Colors (introduced gradually)
`PaintColor` cases: `red`, `blue`, `green`, `yellow`.

| Levels | Colors in the tray |
|---|---|
| 1–4 | red, blue |
| 5–9 | red, blue, green |
| 10–15 | red, blue, green, yellow |

The tray shows **only** the paint colors available in the current level. All four arrows are always shown.

### 4.3 Actions
| Action | Effect |
|---|---|
| `move(.up/.down/.left/.right)` | Marker moves one cell in that direction. |
| `paint(color)` | The cell under the marker becomes `color` (painting over an existing color is allowed). |

### 4.4 Program slots
- The number of slots is the length of the level's **reference solution** (the shortest answer the level designer wrote) **plus 2**. The extra slots give the child some room for detours and mistakes.
- Any program that produces the target counts as a success. It doesn't have to match the reference solution.
- Empty slots are skipped. **Play is enabled as long as at least one slot is filled** (and the board is in the Ready state, see 4.6).

### 4.5 Running
- Actions run left to right, one step every ~0.6 s. The current slot is highlighted, the marker slides to its new cell, and paint "splats" in with a short scale animation.
- **Moving off the grid:** the marker does a short "bump" wobble against the edge, the run stops right there, and the board goes into the Failed state.
- When the last filled slot has run, the canvas is compared with the target:
  - **Match →** Success state, showing the fireworks overlay.
  - **No match →** Failed state.

### 4.6 Board states
```
Ready ──Play──▶ Running ──(match)──▶ Succeeded ──Next──▶ Ready (next level)
                   │
                   └─(mismatch / off-grid)──▶ Failed ──Reset──▶ Ready
```
- **Ready:** editing allowed; Play is enabled when ≥1 slot is filled; Reset does nothing.
- **Running:** editing, Play and Reset are all disabled.
- **Failed:** the marker stays where it stopped, and the canvas keeps whatever was painted. **Play is disabled** (grayed out) and **Reset pulses** gently to show it's the next step. Editing slots *is* allowed, so the child can fix the program while waiting to reset.
- **Reset** (from Failed) puts the marker back at `start` and restores the canvas to the level's starting pattern. **The program in the slots is kept.**
- **Succeeded:** a full-screen overlay with fireworks, a big "Good job!" message and a **Next** button (plus a small "back to levels" button). On the last level, Next goes back to level select with a bigger celebration.

## 5. Interaction: drag-and-drop editing

Editing is drag-and-drop only. Nothing is placed by tapping.

- **Tray → slot:** drag an action from the tray onto any slot. If the slot is empty, the action goes in. If it's full, the new action **replaces** the old one.
- **Slot → slot:** drag a placed action onto another slot to **move** it there. If the target slot is full, the two actions swap.
- **Slot → trash:** a large trash-can drop target sits at the end of the slot row. Dropping a placed action on it clears that slot. The can "gulps" when it's hovered over and when something is dropped in.
- A drop anywhere else is cancelled, and the action springs back.
- Drop targets highlight (thicker outline and a slight scale-up) while an item hovers over them.
- Tray items are never used up; the tray works like an endless supply.

Implementation note: the drag payload is a small `Transferable` (`Codable`) value `DragToken { action: Action, sourceSlot: Int? }`. `sourceSlot == nil` means the drag came from the tray.

## 6. Screens and layout

### 6.0 Launch screen and app icon (green — Nina's favorite)
- **Launch (splash) screen:** a solid, bright green background (the same green as the game's `PaintColor.green`). It uses the `UILaunchScreen` Info.plist keys: `UIColorName` points to a `LaunchGreen` color asset, and `UIImageName` points to a white paintbrush/drop glyph. The level select screen then fades in.
- **App icon:** a green background with a white SF Symbol-style glyph (`paintbrush.pointed.fill` over a `drop.fill`), exported as a single 1024×1024 image in `Assets.xcassets/AppIcon`. The icon also provides dark and tinted variants, kept on green.
- Green is also the accent color (`AccentColor` asset) used for highlights such as drop-target outlines and the level-select checkmarks.

### 6.1 Level select (first screen after launch)
- Title **"Artiste"** in a big, friendly rounded font (`.system(.largeTitle, design: .rounded)`, heavy weight).
- Directly below it, the subtitle ***A game for Nina, by Mom*** in a smaller italic font.
- 15 large numbered tiles (3 rows × 5). Finished levels show a star or checkmark. All levels are unlocked.
- A mute toggle in the corner.

### 6.2 Game screen (landscape)
The game screen should look very similar to the library game:
```
┌────────────────────────────────────────────────────────────┐
│ (◀)                    Level 4                      (🔊)   │
│        ┌─────────┐              ┌─────────┐                │
│        │ TARGET  │              │ CANVAS  │                │
│        │  5×5    │              │ 5×5 + ◆ │                │
│        └─────────┘              └─────────┘                │
│ ╭────────╮ ╭───────╮                                       │
│ │ ▶ Play │ │ ↺     │                                       │
│ ╰────────╯ ╰───────╯                                       │
│ ┌──────── cream tray bar ─────────────────────────────┐    │
│ │  (⬆)(➡)(⬅)(⬇)    (💧)(💧)(💧)(💧)                     │    │
│ └─────────────────────────────────────────────────────┘    │
│ ████████ orange slot panel ████████████████████████████    │
│   ( )( )( )( )( )( )( )( )( )                     (🗑)      │
└────────────────────────────────────────────────────────────┘
```
**Visual style**
- **Background:** soft lavender with faint, lighter vertical zig-zag stripes, drawn with a SwiftUI `Path`/`Canvas`.
- **Header:** a round, dark back button in the top-left (`arrow.left` on a dark circle) and a subtle, semi-transparent "Level N" title at the top center. A mute toggle (`speaker.wave.2.fill` / `speaker.slash.fill`) sits top-right.
- **Grids:** the target (left) and canvas (right) sit side by side. Each is a 5×5 grid of square cells with thin dark grid lines and a dark outer border. Both are sized with `GeometryReader` to fill the space above the bottom panel. Unpainted cells are very pale gray/white.
- **Current-location marker:** a purple diamond (`suit.diamond.fill`, rotated slightly) inside the current cell, with a white outline so it shows up on any color.
- **Play button:** a bright blue rounded-rectangle button that sits like a tab on the top-left edge of the tray, with an orange rim (`play.fill` + "Play"). **Reset** sits beside it in the same style, in orange (`arrow.counterclockwise`). Both are at least 64 pt tall on iPad and 52 pt on iPhone.
- **Tray bar:** a cream/pale-yellow rounded bar with an orange border. It holds the action tokens:
  - **Arrow tokens:** white SF Symbol arrows (`arrow.up`, `arrow.right`, `arrow.left`, `arrow.down`) on red circles with a white ring.
  - **Paint tokens:** a `drop.fill` in the paint color on a white circle with a light ring.
  - Tokens are at least 56 pt on iPad and 44 pt on iPhone.
- **Slot panel:** a warm orange panel along the bottom. Empty slots are slightly darker orange circles, the same size as the tokens. Filled slots show the token. The trash target (`trash.fill` in a large circle) sits at the right end of the panel.
- **Slot limit:** at most 12 slots per level (reference solution ≤ 10, plus the 2 extra), so the row fits on one line on the smallest supported iPhone in landscape.

### 6.3 Success overlay
- The game screen dims, and fireworks fill the screen. They're particle bursts drawn with `TimelineView` + `Canvas` in red, blue, green and yellow.
- A "Good job!" heading and a big **Next ▶** button.
- A cheerful sound effect (respects mute).

## 7. Architecture

The design has three layers, each with one clear job.

### 7.1 `Engine/` — pure Swift, no SwiftUI, fully unit-tested
- `PaintColor` (enum, `Codable`).
- `Direction` (enum) and `Action` (enum: `.move(Direction)`, `.paint(PaintColor)`, `Codable`, `Hashable`).
- `Position` (row, col) and `Grid` (5×5 array of `PaintColor?`, with `subscript`, `contains(_:)`, `==`).
- `Level` (`id`, `start: Position`, `initial: Grid`, `target: Grid`, `solution: [Action]`, `palette: [PaintColor]`). `slotCount` is computed as `solution.count + 2`.
- `Interpreter`: `func steps(program: [Action?], from: Position, on: Grid) -> [Step]`. It returns a list of `Step` values, one per filled slot. Each `Step` holds the slot index, the action, the resulting position and grid, and an outcome (`.ok` or `.bumped`). The list stops at the first bump. Because the whole run is worked out up front, the engine stays simple to test and the view model only has to play back the steps.

### 7.2 `Game/` — state and orchestration
- `GameViewModel` (`@Observable`, `@MainActor`): holds the current level, `slots: [Action?]`, `canvas: Grid`, `marker: Position`, `state: BoardState` (`ready/running/failed/succeeded`), and `activeSlot: Int?`.
  - `place(_:at:)`, `move(from:to:)`, `clear(slot:)` handle editing and are blocked while Running.
  - `play()` gets the steps from the `Interpreter`, then plays them back with `Task.sleep` between them, updating `marker`/`canvas`/`activeSlot` inside `withAnimation`. It also handles a bump step and sets the final state.
  - `reset()` (only from Failed) and `next()`.
  - The playback `Task` is cancelled if the view goes away.
- `LevelStore`: loads `levels.json` from the bundle into `[Level]`.
- `ProgressStore`: keeps the set of finished level IDs and the mute setting in `UserDefaults`.
- `SoundPlayer`: plays a few short bundled sounds (place, paint, bump, success) with `AVAudioPlayer` and respects mute.

### 7.3 `Views/` — SwiftUI only, no game logic
- `LevelSelectView`, `GameView`, `GridView` (shared by target and canvas, with an optional marker), `ActionTokenView`, `TrayView`, `SlotRowView`, `TrashTargetView`, `ControlButtonsView`, `SuccessOverlayView`, `FireworksView`.

### 7.4 Level data
`Artiste/Resources/levels.json`. Each level looks like this:
```json
{
  "id": 1,
  "start": [0, 0],
  "initial": ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"],
  "target":  ["RBRBR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"],
  "solution": ["right", "right", "paint:red"],
  "palette": ["red", "blue"]
}
```
Rows are 5-character strings: `R`/`B`/`G`/`Y` for colors and `.` for empty (white).

## 8. Level design (15 levels)

Rules every level must follow:
- `initial` and `target` differ only in cells that `target` paints. The target has **no** empty cells, so every finished picture is full of color.
- Running `solution` from `start` on `initial` produces exactly `target`, and never goes off the grid.
- `solution.count` ≤ 10 (so the slot count, `solution.count + 2`, is ≤ 12).
- `palette` contains every color that `solution` uses and matches the color schedule in §4.2.

Difficulty ramp (rough guide):
| Levels | Empty cells | Solution length (slots = +2) | Idea introduced |
|---|---|---|---|
| 1–2 | 1 | 2–3 | Move then paint |
| 3–4 | 2 | 3–4 | Two colors, two moves |
| 5–6 | 2–3 | 4–6 | Green appears; turning corners |
| 7–9 | 3–4 | 5–7 | Downward paths, mixed colors |
| 10–12 | 3–4 | 6–8 | Yellow appears |
| 13–15 | 4–5 | 8–10 | Longer paths, all four colors |

Patterns are original: checkerboards, stripes, diagonals, simple shapes (a heart, a smiley, a flag).

## 9. Error handling

- Missing or invalid `levels.json` is a programmer error. Crash in Debug with a clear message, and the test suite checks the file (§10) so it can't ship broken.
- Missing sound files are logged and ignored, so gameplay never breaks.
- Starting Play with zero filled slots can't happen because the button is disabled.
- Backgrounding during a run: the run carries on when the app comes back. If the view goes away, the run is cancelled and the board goes back to Ready with a reset canvas.

## 10. Testing

**Engine unit tests (Swift Testing)**
- Each action changes the position or grid correctly.
- An off-grid move in each direction gives `.bumped`, and the run stops there.
- Empty slots are skipped.
- Painting over an existing color.
- A different program that still reaches the target counts as success.

**Level data tests** (parameterized over all 15 levels)
- JSON decodes, and each grid is exactly 5×5.
- Running `solution` on `initial` gives `target` with no bump.
- `solution.count` ≤ 10 and `slotCount == solution.count + 2`; the target has no empty cells; `palette` covers the colors used and follows the §4.2 schedule.

**View model tests**
- State changes: Ready → Running → Succeeded/Failed. Play is blocked in Failed until `reset()`. `reset()` restores the marker and canvas but keeps the slots.
- Editing is blocked while Running. Place, replace, move/swap and clear-via-trash all behave as described.
- Steps are timed with an injectable delay of 0 in tests.

**Manual checks**
- iPhone SE (3rd gen) landscape and an iPad, checking layout, the 12-slot fit, drag targets and fireworks performance.

## 11. Accessibility

- Every token, slot, cell and button has a VoiceOver label (for example "Paint red", "Slot 3, move right", "Row 2, column 4, blue").
- Because editing is drag-only, slots also get accessibility actions ("Set to…", "Clear") so VoiceOver and Switch Control users can still play.
- Colors always come with shape cues: paint drops have a distinct drop shape on a white circle, arrows have arrow shapes on red circles, and the start marker stands out by shape, not just color.

## 12. Suggested project structure
```
Artiste/
  ArtisteApp.swift
  Engine/   PaintColor.swift, Action.swift, Grid.swift, Level.swift, Interpreter.swift
  Game/     GameViewModel.swift, LevelStore.swift, ProgressStore.swift, SoundPlayer.swift
  Views/    LevelSelectView.swift, GameView.swift, GridView.swift, ActionTokenView.swift,
            TrayView.swift, SlotRowView.swift, TrashTargetView.swift,
            ControlButtonsView.swift, SuccessOverlayView.swift, FireworksView.swift
  Resources/ levels.json, Sounds/, Assets.xcassets (green AppIcon, LaunchGreen, AccentColor, paint colors)
ArtisteTests/
  InterpreterTests.swift, LevelDataTests.swift, GameViewModelTests.swift
```
