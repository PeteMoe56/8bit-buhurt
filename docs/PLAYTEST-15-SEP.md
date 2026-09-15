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
| 24 | **Back in any popup goes to the main club**, not the previous screen | `open` |
| 22 | **No way to put a fighter INTO the starting five.** "Pick who to trade places with" only drops men from starters to bench | `open` |
| 18 | Saved **formation** does not appear in the blank slot | `open` |
| 19 | Saved **play** does not appear in the blank slot | `open` |
| 11 | **SKIP ROUND floats over the after-action report** and does nothing useful there | `open` |
| 10 | Playbook appears on click — #9 may be this same bug | `open` |
| 13 | One man is already OUT at season start, for no stated reason | `open` |

24 and 22 are the two that make the game feel broken rather than unfinished: one
loses the player's place on every popup, the other means the squad screen can
only ever make your team worse.

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
