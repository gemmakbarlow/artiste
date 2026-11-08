# Artiste: Castle Mode design

**Date:** 2026-11-08
**Status:** Draft for review
**Builds on:** `2026-11-07-artiste-design.md` (the base game). Everything there still applies unless this document says otherwise.
**Visual reference:** `assets/2026-11-08-castle-mode-mockup.html`, the mockup Nina's mom approved: chunky castles, castle colors, and the six princesses. Open it in a browser.

## 1. Intent

Nina loves princesses. Castle Mode puts the same coding puzzles inside a princess castle she chooses, and rewards her with a princess who steps out and waves when she solves it. The point is delight and motivation. The puzzles teach the same thing; the castle makes her want to do one more.

## 2. Goals, non-goals, anti-goals

**Goals**
- A **Castle Mode** switch on the level-select screen.
- With Castle Mode on, tapping a level asks Nina to **pick a castle before every level**.
- Six castles. Each has its own black-outline fairy-tale shape, its own board shape, and its own colors.
- The puzzle board **is** the castle: big squares fill its walls, towers and keep.
- When she solves a castle level, **the castle's princess steps out, smiles, blinks and waves**, instead of the "Good job!" screen.
- A castle version of level N is about as hard as level N.

**Non-goals (this version)**
- The snowy-village princess (the Anna-inspired one). Left out for now, but the castle list must make adding a seventh castle easy.
- Choosing a princess separately from her castle. Each castle has exactly one princess.
- New sounds per princess (reuse the existing success sound).
- iPhone portrait (the app stays landscape-only).

**Anti-goals: these would make it a failure even if it works**
- **Copying Disney.** No Disney names, no copies of their character designs or castle logos, nothing traced. The princesses are original characters that share only general hair and dress colors and hairstyle ideas with the ones Nina knows. The castles are generic fairy-tale shapes.
- **Tiny squares.** If the castle board makes squares too small for a 4–7 year old to see and tap, it has failed. Fewer, bigger squares beat a detailed castle.
- **Breaking the normal game.** With Castle Mode off, everything behaves exactly as it does today.
- **A scary or flat character.** Every princess must look happy and friendly: big eyes, a smile, rosy cheeks, and a wave.

## 3. Flow

1. **Level select.** A **Castle Mode** switch sits in the top-left corner (the mute button is top-right). It shows a small castle icon and a green on/off switch, and it is saved like the mute setting.
2. **Castle Mode off.** Nothing changes: tapping a level opens the normal 5×5 game.
3. **Castle Mode on → castle picker.** Tapping a level opens a full-screen **"Pick your castle!"** screen showing the six castles as big black-outline cards, in two rows of three. Each card also shows a small preview of its princess's face, so Nina can find the castle by the princess. Tapping a card starts that level in that castle. A back button returns to level select.
4. **Playing a castle level.** This uses the same game screen as normal mode:
   - The target and the canvas are both castle-shaped boards.
   - The tray's paint drops use the castle's colors.
   - Tap to add, Play, Reset, Back, bump-on-wall and the step timing all work as in the base game.
5. **Solved.** The success overlay is replaced by the **princess reveal** (§6). After the wave there's a big green **Next** button. Next goes to the **castle picker** for the next level, because she picks before every level. A small "levels" button returns to level select. On level 15 there is no Next; it shows a Home button instead, as the base game does.
6. **Failed.** This works exactly as in the base game: Play grays out until she taps Reset.

## 4. The six castles

All castles are drawn as **black outlines** (no fill) in a slim, tall fairy-tale style: pointed curved roofs with flags, battlements and a taller middle keep. The board squares fill the inside of the walls, towers and keep. Roofs, flags and spires sit above the squares and aren't playable.

Each castle has:
- a **board shape**: a set of squares on a grid, about **40–48 squares**, with a bounding box of at most **8 columns × 8 rows**;
- **four paint colors** with names (used for the tray drops and VoiceOver);
- a **tile motif** drawn faintly on every painted square;
- one **princess**.

| Castle | Shape idea | Four colors | Tile motif | Princess |
|---|---|---|---|---|
| Rose castle | Two slim side towers, tall middle keep, battlemented wall (as in the mockup) | Light pink, hot pink, rose, blush white | Little rose | Rose princess |
| Ice palace | Same family as the rose castle, with icicles under the roofs | Light blue, sky blue, deep blue, snow white | Snowflake | Ice queen |
| Desert palace | Wide base, onion-dome keep (dome rows step inward), two thin minarets | Turquoise, gold, sand, deep teal | Small diamond mosaic | Desert princess |
| Tall tower | One tall, wide tower (about 3 squares wide) on a small base, with one window bay | Lavender, purple, gold, pink | Tiny flower | Tower princess |
| Bayou palace | Low, wide two-story palace with a balcony row, water line under it | Lily green, leaf green, cream, gold | Lily pad | Bayou princess |
| Island fort | Squat fort on a hill with a thatched-roof tower, waves along the bottom | Ocean blue, turquoise, sand, coral red | Little wave | Ocean voyager |

The rose castle and ice palace shapes and colors are shown in the mockup and are approved. The other four use the descriptions above; their exact square layouts and hex values are left to the builder (§10), as long as they keep to the size rules and the anti-goals.

**Empty squares** in every castle are white with a dashed border in the castle's grout color. That way "this one needs painting" looks the same in every castle.

**The marker** starts on the bottom-left square of the castle's lowest row, the same purple diamond as in the base game.

## 5. Castle puzzles

Tapping level N and a castle gives a puzzle on that castle's board **about as hard as base-game level N**. Hand-designing 15 × 6 = 90 puzzles is too much, so castle puzzles are **generated by code from a difficulty table and a fixed seed**. The same level and castle always give the same puzzle.

**Difficulty table** (mirrors base spec §8):

| Levels | Empty squares | Solution length | Paint drops in the tray | Turns |
|---|---|---|---|---|
| 1–2 | 1 | 2–3 | 2 | none (straight line) |
| 3–4 | 2 | 3–4 | 2 | none |
| 5–6 | 2–3 | 4–6 | 3 | allowed |
| 7–9 | 3–4 | 5–7 | 3 | allowed |
| 10–12 | 3–4 | 6–8 | 4 | allowed |
| 13–15 | 4–5 | 8–10 | 4 | allowed |

**How a puzzle is made** (the builder can refine the method, but these rules are fixed):
- Each castle has a fixed **finished picture**: every square of its board painted in its colors, as a simple pattern such as stripes or a checkerboard per tower. The picture uses all four colors.
- **Paint drops in the tray** (my call): the tray shows the castle's *first N* colors, where N comes from the table (2, 3 or 4), just as the base game introduces colors gradually. The generator may only leave a square empty if its picture color is one of those N. Pre-painted squares can still show all four colors.
- The generator picks a path from the start square that stays on the castle's squares. It chooses squares on that path to leave **empty** in the starting board, and the solution is: walk the path, painting each empty square its picture color.
- The **target** is the finished picture. The **starting board** is the finished picture with those squares empty.
- Every other square starts already painted correctly.
- The solution length, empty-square count, tray colors and straight-line rule must match the table row.
- Slots = solution length + 2 (max 12), as in the base game.

Tests must prove that all 90 puzzles are solvable by their own solution, stay on the castle, follow their table row, and are identical every time they're generated.

## 6. The princess reveal

When she solves a castle level:
1. A short pause lets the last paint land (the base game already does this).
2. The target castle fades away, and the screen dims gently behind the canvas castle. **An arched door appears over the bottom-middle of the keep and swings open** (my call). The doorway squares are ordinary playable squares; the door is drawn on top of them after the puzzle is solved.
3. **The princess steps out** of the doorway, growing from small to full size with a soft bounce, about 0.6 s. Full size is **about 55% of the screen height**, standing in front of the canvas castle and centered on it, with the dimmed castle still visible behind her (my call).
4. She **waves** (her arm swings back and forth, 3 times), **blinks** every couple of seconds, and does **one little hop**. Then she keeps idling: slow blinking and an occasional small wave while Nina looks.
5. A sparkle or two and the existing success sound play. Fireworks are not used here.
6. After about 1.5 s, the **Next** button (and the small levels button) appears below her.

**The six princesses** are original characters, drawn in code from simple shapes, chibi style. They follow the mockup, which is approved ("love the characters"):
- Big eyes with a white highlight, rosy cheeks and a smile.
- A short neck.
- One arm raised to wave.

| Princess | Hair | Outfit |
|---|---|---|
| Desert princess | Black hair in a long low ponytail tied with bands, gold headband | Turquoise outfit |
| Ice queen | Platinum-blonde side braid over one shoulder, swept up and back | Icy-blue gown, sheer cape |
| Tower princess | Floor-length golden hair with tiny flowers woven in | Lavender dress, pink bodice |
| Rose princess | Long golden waves, small gold tiara | Pink gown with a white off-shoulder collar |
| Bayou princess | Dark hair in a neat high bun with a gold tiara | Lily-pad green gown with a leafy hem |
| Ocean voyager | Big curly black hair, flower behind her ear | Red top, cream skirt, blue shell necklace |

**Reduce Motion:** she appears without the bounce or hop, in a still waving pose. Blinking is fine.

**VoiceOver** announces "The <princess> waves hello! Good job!" in place of "Good job!".

## 7. Layout

- The game screen keeps the base layout: header, target on the left, canvas on the right, the Play/Reset tab, the tray and the slot row.
- **Square size:** the **canvas** castle's squares must be **at least 26 pt on iPad** and **at least 20 pt on the smallest iPhone in landscape (667 × 375 pt)**. Nobody taps board squares; they're only looked at. So the **target castle may be drawn as small as half the canvas size** (my call). It's a picture to copy, and the canvas is where Nina's eyes and the marker are, so it gets the space first.
- If the canvas still can't reach 20 pt on the SE (my calls, in this order):
  1. Let the roofs and flags rise into the header's middle, between the back and mute buttons. In castle mode on iPhone, the "Level N" title moves into the castle picker header and is hidden on the game screen, since the castle itself shows where she is.
  2. Tighten the vertical padding around the tray and slot panel, without shrinking the tokens or buttons below the base spec's minimums.
  3. Only then reduce a castle's height to 7 rows. Never shrink the canvas squares below 20 pt.
- Roofs and flags must never cover the back or mute buttons.
- The castle picker cards are at least 120 pt wide on iPhone and 180 pt on iPad.

## 8. Progress and settings

- **Castle Mode on/off** is saved in `ProgressStore`, next to mute.
- Finishing a castle level **also marks the level complete** with the existing checkmark.
- In addition, each level tile shows a **small crown** once she's finished that level in any castle. Which castles she used isn't tracked in this version.

## 9. What changes in the code (decided)

- **Boards stop being fixed 5×5.**
  - The engine gets a board shape (a set of playable squares inside a bounding box).
  - Moving onto a square that isn't part of the board is a **bump**, exactly like leaving the grid today.
  - The normal 15 levels are simply a full 5×5 shape.
- **Colors become palette slots.**
  - The engine stores "paint slot 1–4" instead of red/blue/green/yellow.
  - The current look supplies the actual colors: normal mode maps slots to red, blue, green and yellow; each castle maps them to its own four colors.
  - The existing `levels.json` letters keep working (R/B/G/Y are slots 1–4).
- Normal-mode behavior, levels and tests must be unchanged. The existing test suite must still pass.

## 10. Left to the builder

- The exact square layout of the desert palace, tall tower, bayou palace and island fort. They must stay within 40–48 squares and 8 × 8, form one connected board, and read clearly as their castle in black outline.
- Exact hex values for those four castles' colors. The four colors in each castle must be easy to tell apart, including for common color blindness. Pair them with the motif or a lightness difference.
- The generator's exact path-picking method, and each castle's finished-picture pattern, within §5's rules.
- Animation timings within §6's ranges, and the princesses' exact proportions, as long as they match the approved mockup.
- Where the crown sits on the level tile.

**Calls made by the designer (Claude), not decided by Nina's mom.** Check these:
- The castle picker shows each princess's face on her card (§3).
- Next goes to the castle picker for the next level (§3).
- Puzzles are generated by code from a seed, not hand-designed (§5).
- The tray limits colors by level; the castle picture stays fixed (§5).
- The reveal uses an arched door over the keep, the princess is about 55% of the screen height, and no fireworks (§6).
- On iPhone, the target castle shrinks before the canvas, and the order of what gives on small screens is as listed (§7).
- The crown badge, with completion counting toward the normal checkmark (§8).
- The engine changes to board shapes and paint slots (§9).

## 11. Testing

- **Engine:**
  - Bumping into a non-board square inside the bounding box.
  - A full 5×5 shape behaves exactly as before.
  - Palette slots round-trip through `levels.json` letters.
- **Castles:**
  - Each castle's board is connected and has 40–48 squares.
  - The start square is on the board.
  - Each castle has four distinct colors.
- **Generator:** all 90 (castle, level) puzzles are solvable, deterministic, on-board, ≤ 10 solution steps, and match their difficulty row.
- **View model:**
  - In Castle Mode, success shows the princess reveal instead of the success overlay.
  - Next goes to the castle picker for the next level.
  - The Castle Mode setting persists.
  - Finishing in a castle marks the level complete and earns the crown.
- **Manual:** play at least one level in each castle on the iPhone simulator and the iPad, and watch each princess's reveal.
