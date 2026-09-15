# JUICE.md — what makes it feel 8-bit rather than merely look it

**Built, 13 Sep 2026 — everything in Part 2 that does not need art.** `Juice`
holds the timing, `JuiceArt` is the one node that draws it, `test_juice.gd`
asserts every number below, and REGISTER §49 records what it cost. What is left
is item 7's remaining ambition and the idle motion beyond a blinking cursor.

This stays a brief rather than becoming a changelog, because the numbers in it
are the specification the code is checked against — if this document and the
code disagree, one of them is a bug.

The distinction worth holding: **a pixel font and a limited palette make a game
look retro. Juice is what makes it feel like a machine.** A NES had no tweening,
no easing curves and no particle systems, and it still hit harder than most
modern UI, because everything happened on a frame boundary and nothing was ever
half-way.

---

## Part 1 — The formats, and why they are what they are

### The resolution is already decided and it is right

`960 × 540`, `canvas_items` stretch, `expand` aspect. Three consequences, all
good:

- **960 × 540 is exactly 1/4 of 1080p and 1/2 of 1440p width.** On a 1080p
  monitor every game pixel is a clean 2 × 2 block. On a phone it is not integer,
  but a phone's pixels are small enough that nobody sees it.
- `canvas_items` scales the *drawing*, not the window, so text stays sharp
  instead of being a blown-up bitmap.
- `expand` means a wider phone gets **more world**, not bars. Which is why
  every screen in this game has a side gutter and nothing important within 24px
  of an edge.

**The rule that follows: draw on whole pixels.** A rect at `x = 240.5` is a
smeared edge on every display. Positions in this codebase are already integers by
habit; when the juice layer starts moving things, that habit has to become a
rule — see *the pixel-snap rule* below.

### The grid

Everything already sits on multiples of 4, mostly by accident of taste. Make it
deliberate: **4px is the atom, 8px is the unit, 24px is the gutter.**

| | |
|---|---|
| 4px | the smallest gap that reads — between a label and its value |
| 8px | padding inside a panel, gap between rows |
| 16px | gap between unrelated blocks |
| 24px | the screen gutter, never violated |
| 48px | a touch target's minimum side (see below) |

**Touch targets are 48 × 48 minimum** and the existing buttons are 44 tall —
close, and worth raising to 48 on the mobile build. A miss on a phone is worse
than any amount of polish elsewhere.

### The font sizes are now fixed by the grid

**Superseded 12 Sep 2026.** The three house faces were replaced by one — *Buhurt
Plate*, a proportionally-spaced derivative of Press Start 2P — after Pete read
three names in the old faces and found every one of them hyphenating:
*"Merrick looks like Merri-ck."* See REGISTER §48.

**Two faces, one grid.** Plate for anything the player reads as a heading or a
name, Rail — ours, 5×7, one-pixel stems — for anything small and dense. Press
Start 2P is drawn with two-pixel stems, which is its whole character and is a
wall at table size; Rail sets the same table two-thirds as wide and reads as
quieter than the heading above it.

All four faces are declared on an **8-pixel em**, Rail included — it was rebuilt
into an eight-row box for exactly this reason. So there is one ladder: **8, 16,
24, 32 and nothing else**; `UiKit.snap()` rounds down to it.

| role | face | size |
|---|---|---|
| screen title | Plate | 24 or 32 |
| panel heading | Plate | 16 |
| name on a card | Plate | 16 |
| big number, score, credits | Plate | 24 or 32 |
| body / table row | Rail | 8 |
| footnote, hint | Rail | 8, dimmed |

Nothing at 11, 12, 13, 14, 15, 17, 18, 20, 21 or 26. Those are the sizes the
codebase uses today and every one of them shows a row of pixels a fraction
taller than its neighbors.

**Converting the UI is a real job** — the sixteen scenes still draw in
`ThemeDB.fallback_font`, and the jump from 13 to either 8 or 16 is a re-layout
rather than a find-and-replace. Two collisions are already known on the roster
screen alone: `39 · age 26` running into `to 46`, and the `FLANKER 10/13` label
walking into its number.

### The palette

A real 8-bit machine had a fixed palette and that constraint is most of why the
look holds together. Adopt one: **16 colors, no more**, defined once in `UiKit`
and never mixed outside it. The game already funnels color through `UiKit.INK`,
`DIM`, `UP`, `DOWN`, `YOU`, `EDGE` — that is the skeleton of a palette already.
Finish it and forbid literals.

---

## Part 2 — The juice, in the order worth building it

Each of these is cheap. Together they are the difference between a spreadsheet
and a game.

### 1. Numbers that land — do this one first

Every meaningful change pops a number that rises and fades. `+2`, `−4 CC`,
`DOWN`, `+1 XP`. Three rules and they are all about *restraint*:

- Rises **12px over 400ms**, then holds 200ms, then gone. Not longer.
- It moves in **whole pixels on a 6-step ladder** (2px per step), not smoothly.
  Sub-pixel motion is the single most modern-looking thing a retro game can do.
- **One at a time per source.** Five simultaneous popups is confetti, and
  confetti reads as a mobile F2P game, which this is not.

Where: every credit change, every down in the melee, every XP award in the
winter, every morale shift the player caused.

### 2. Hit pause

On a down, **freeze the whole sim for 80–120ms**, then resume. It is two lines
and it is the single largest perceived-impact gain available. Every fighting game
since Street Fighter II does it and almost no management game does.

Scale it: an ordinary down 80ms, the fifth man down 200ms, a knockout 350ms.

### 3. Screen shake, used sparingly

**Trauma-based, not event-based.** Keep a `trauma` float 0–1, add to it on
impact, decay it every frame, and offset the camera by `trauma² × max`. Squaring
is what makes small hits subtle and big ones violent without two code paths.

Cap it low — **4px** — and shake in whole pixels. Reserve anything bigger for a
knockout. A management screen never shakes.

### 4. The palette flash

The cheapest, most 8-bit trick there is: on a big event, **invert or white-out
the whole screen for 2 frames**. Two frames at 60fps is 33ms — under conscious
perception, but the player feels it.

Use for: the fifth man going down, a cup won, a promotion. Nothing smaller.

### 5. Text that types

Anything narrative — a dilemma card, a job offer letter, the summer report —
reveals **one character per 2 frames**, with a tap skipping to the end. This is
the most *era-correct* item on the list and it costs nothing.

**Never** on numbers or tables. A roster that types itself in is a roster you
cannot read.

### 6. Transitions between screens

No fades. A fade is a 32-bit idea. Use one of:

- **Hard cut.** Always acceptable, and the right default for tab switches.
- **A wipe on the 8px grid** — a column of blocks sweeping across in 8 steps,
  ~130ms. Good for entering the melee.
- **Iris in/out** from the point that was tapped, in stepped rings.

Pick two and use them consistently. The rule that matters: **every transition is
under 200ms.** Anything longer is a load screen wearing a costume.

### 7. Sound is half the juice and this game already has the pipeline

The ACTM event-music pipeline exists and `audio/` is already structured. What is
missing is the **UI layer**: a tick on every button, a lower tick on a
back/cancel, a two-note rise on a confirm, a descending third on a refusal. Nine
or ten one-shots at most.

**The refusal sound is the important one.** This game refuses the player
constantly — over the cap, one job a week, the trial is closed, not entered for
the cups — and those refusals currently land as a line of red text. A 120ms
descending blip makes a refusal feel like a rule rather than a bug.

### 8. Idle motion

Nothing in a retro game is ever completely still. A 2-frame flag flutter, a
selected card that breathes by one pixel every 30 frames, a blinking cursor on
the active tab. Cheap, and it is what stops a paused screen looking crashed.

---

## Part 3 — The three rules that hold it together

**THE PIXEL-SNAP RULE.** Every drawn position is `round()`ed before it is drawn.
Every one. A screen shake, a rising number and a wipe are all things that
generate fractional positions, and one un-snapped element in a scene makes the
whole scene look soft — the eye catches the inconsistency even when it cannot
name it.

**THE FRAME-LADDER RULE.** Animations step on a ladder of frames, not on a
continuous curve. 6 steps, 8 steps, 12 steps. If a designer would have had to
draw it as cels, step it. This is the actual difference between *retro* and
*retro-themed*, and it is almost always the thing missing from games that have
the pixel art and still feel wrong.

**THE BUDGET RULE.** Every one of these is individually cheap and collectively
capable of making the game unreadable. Pick a ceiling — **two juice effects may
fire at once, never three** — and enforce it in one place, the way this codebase
already enforces one queue for the bid, the cup and the dilemma.

---

## What to build first, if it is one afternoon

1. Number popups on credits and downs (item 1)
2. Hit pause on a down (item 2)
3. The refusal sound (item 7)

Those three touch the two things the player does most — reading a number change
and being told no — and none of them needs art.
