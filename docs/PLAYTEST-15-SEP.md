# Playtest, 15 Sep 2026 — 26 items

Pete's first full run of the game in the Godot editor, screen by screen, with
shots. **This is the list. Nothing comes off it without being done, or without
Pete saying it comes off.**

Status: `open`, `done`, or `ask` — needs a decision before code.

Bands are by *kind of work*, not by Pete's numbering; his numbers are kept so a
row can be matched back to what he wrote.

---

## Brand — done 15 Sep

| # | Item | Status |
|---|---|---|
| — | Everything says "Retro Buhurt"; move to **8-Bit Buhurt: Combat Club** | `done` |
| — | Logo on the icon, the start menu, and heavily faded behind the main menus | `done` |

`Assets/Logo.png` (1254², opaque black ground) was keyed by flood fill from the
border — the artwork's *own* outlines are black, so a colour key punches holes
through the helmet — then cut into six files, each at the size it is drawn at,
because the project runs nearest-neighbour filtering and a texture the engine
scales is a texture with chewed edges.

`scripts/game/brand.gd` is the one place that knows the name and the mark. The
name is read from `application/config/name`, the same copy the APK manifest and
a store listing are built from.

Two bugs fell out of it: the front door hung every element off `const CENTRE :=
480.0`, so on a 1170-wide handset the whole screen sat 105 pixels left of centre;
and fifteen screens opened `_draw()` with the same ground-painting line, which is
fifteen places to add a watermark and one to forget. Both are one call now.

---

## Bugs — real defects, ordered by how badly they break a session

| # | Item | Status |
|---|---|---|
| 24 | **Back in any popup goes to the main club**, not the previous screen | `done` |
| 22 | **No way to put a fighter INTO the starting five.** "Pick who to trade places with" only drops men from starters to bench | `done` |
| 18 | Saved **formation** does not appear in the blank slot | `done` |
| 19 | Saved **play** does not appear in the blank slot | `done` |
| 11 | **SKIP ROUND floats over the after-action report** and does nothing useful there | `done` |
| 10 | Playbook appears on click — #9 may be this same bug | `done` |
| 13 | One man is already OUT at season start, for no stated reason | `answered` |

**24** — every screen carried a literal Back destination. Right for most of them
most of the time, wrong the moment a screen has two ways in: the fighter card
returned to the roster whether you opened it from the roster, the market or the
staff room. A screen cannot know where it was opened from, so it must not be the
thing that decides. `UiKit` keeps a six-deep trail now; the old argument became
the *fallback*, so all fifteen call sites are still correct. `test_nav.gd`, 10
checks.

**22** — the deeper of the two. `starting_five()` *chooses* the five by walking
roster order and taking the first fit man who covers each slot, so **roster order
is the depth chart** — and nothing in the game could reorder the roster.
`swap_squad` only ever moved men between the bus and the clubhouse. A man who
ended up on the bench stayed there whatever you thought of him. `swap_order()` is
the missing verb.

**18 / 19** — they saved. They drew. And a full-size, empty-labelled, **not-flat**
Button on the layer above painted a slab over the name. The same fault was in the
club-creator's mark bank. The check that should have caught it had an explicit
exemption for "a wordless button that wholly contains a string" — written for the
mark bank, and it is the exact signature of this bug. *An exemption written for
one screen is a hole for every other one.*

**11** — `_process` returns early on the report, pre-fight and splash screens,
**before** the one function that decides whether CALL and SKIP ROUND exist. That
function's own docstring says *"two call sites deciding a control's visibility is
how a button ends up live on the report screen."* It was right, and it was
unreachable from the report screen.

**10** — and Pete's hunch was right, it was #9 as well. `_show_strategy_panel()`
built the pre-fight's controls and **never changed `screen`**, so the splash went
on drawing underneath: a playbook floating over a walk-out. It came right on the
next thing he touched because `_choose()` sets the screen — hence *"I clicked and
the rest of the playbook appeared."* One line.

**13** — not a bug. Four seeds, thirteen men each, every one fit at season start.
The man Pete saw was hurt in the bout he had just fought. Measured, since nothing
ever had (`tools/probe_knocks.gd`, 60 bouts):

| | |
|---|---|
| Bouts leaving at least one man hurt | **12%** |
| Knocks per bout | 0.12 |
| Events missed | mean 1.7, median 1, worst 3 |

That is a sane rate — one bout in eight. What it exposed is that `OUT 1` never
says it is an *injury*; that goes in the formatting band.

**Still open from #9:** the pre-fight should show the field, the idle fighters,
and a dashed line of the plan that updates as a formation is picked. That is a
feature in `melee_scene.gd` and belongs to the arena chat — see the hand-off.

---

## Formatting — the broad pass

Pete flagged 1, 2, 4, 6, 7, 12, 17 individually. They are one job: the screens
were laid out against a 960×540 canvas, re-anchored for handsets, and never
re-read as pages.

| # | Screen | Note |
|---|---|---|
| 1 | Title / slots | |
| 2 | Title / slots | and **no "Name Your Club"** step |
| 4 | **Squad** | "needs redesign, badly" — the worst one |
| 6 | Free agents (card view) | |
| 7 | Clubhouse | "looks crushed" |
| 12 | Dilemma card | "major formatting issues" |
| 17 | Chalkboard | |

Squad is the biggest single piece of work on this whole list and has two feature
rows attached to it (21, 22), so it is a screen rebuild rather than a tidy.

---

## Missing — things a player looks for and does not find

| # | Item | Status |
|---|---|---|
| 3 | **No tutorial** — nothing teaches the loop | `open` |
| 14 | **Difficulty settings cannot be found** | `open` |
| 25 | **No weekly income, ever.** You are set to lose, and you die out if you do not win | `open` |
| 8 | **No fan information anywhere**, and none on the fight card | `open` |
| 16 | **"room" and "name" are never explained** — the two dilemma currencies | `open` |
| 21 | Squad needs **sort-by and min/max** on skill / age / cost | `open` |
| 23 | **"Stand down" is unexplained**, and hides itself when pressed | `open` |
| 26 | Put the **settings-menu music into every non-fight menu**; find something else for what it replaces | `open` |

**25 is the same finding as the ladder**, from the other end. The measured result
was a club that wins its division four times in forty seasons and finishes last
in the one above every time; Pete's version is *"immediately feel outgunned by
everyone in Backyard Circuit"* (15). One problem, two symptoms.

---

## Design — needs a decision before any code

| # | Item |
|---|---|
| 5 | **Rebuild the Market.** There is a tab inside a tab. Pete: *"Market should be some type of enhancements like armor polish or something. We can brainstorm it"* |
| 20 | **The formation and play slots on the fixture card should not be there.** Fight should go to the pre-fight screen anyway and Sim should be a popup. Candidates for the space: the schedule, and *"definitely a ticker across the bottom full of humor and results"* |
| 9 | **Pre-fight should show the field**, idle fighters behind it, positions updating as a formation is picked, and a dashed line of the plan |
| 7b | Remove **"A night out"** — *"pretty dumb"* |

9 lands in `melee_scene.gd`, which belongs to the arena chat — see
`docs/ARENA-SHAPE-HANDOFF.md`.

---

## Where this list came from

Sixteen screenshots, one continuous session from the front door through a season
opener, a fight, a dilemma, a contract and the chalkboard. The shots are the
evidence and they are worth keeping: half the findings in `docs/REGISTER.md` are
"the screenshot showed something no test could see", and this run is the largest
single batch of those the project has had.
