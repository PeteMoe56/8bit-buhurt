# 8-Bit Buhurt: Combat Club

**BonkWorks. Godot 4.6. Solo.**
An 8-bit buhurt club manager in the Retro Bowl mould: you run an armored combat club, and
during bouts you drop into a fighter's hands for a few seconds at a time.

This README is the cold-start doc. A fresh chat should be able to read it and continue.

> **Rewritten 15 Sep 2026, because it had become a liability rather than a stale file.**
> It described a portrait game with no meta layer — no season, no economy, no menus
> outside the bout — at a point when all sixteen of those screens existed. And it said
> *"Portrait, 540×960"* in three places while `project.godot` shipped a 960×540 landscape
> game whose handheld orientation setting was, in fact, set to portrait. That setting was a
> real bug that would have shipped. **A stale doc is not harmless; it is a wrong answer
> that nobody is checking.** See `docs/REGISTER.md` section 25.

---

## Where things stand

*Updated 27 Sep 2026 (Central), after a full code audit — see `docs/REGISTER.md` §28.*

Sixteen screens, a full career loop, 49 test files, **fast gate green, balance tier green**.
Open `C:\Dev\RetroBuhurt` in Godot 4.6.2 and press play. **Landscape, 960×540** — and the
canvas floats: see *The shape of the screen* below.

You run a club through a season: a fixture list, a league table, a squad with contracts and
wages, a market, a ground you build, a federation you owe, cups, a chalkboard you draw
plays on, and a trophy cabinet. Bouts can be simulated or fought. When you fight one you
pick a formation, pick a strategy in the corner, and then **put your finger on a fighter
and draw him a path** — to open ground, or onto an opponent. He lights up and goes. When
the route is done the AI takes him back. Drawing nothing at all is a real way to play.
Every fighter carries **sword-and-shield or a polearm** (tap it on his card to change).

Pacing, measured with `bash tools/bb.sh bases`: a National title at season **12.0** on
average (10.8–13.0 across the five check bases), with a manager that keeps the club
eligible for cups.

What is **not** built:

- **The art.** 32 slots declared in `ArtBank.SLOTS`, none filled yet (in progress). Every
  one falls back to a primitive, so nothing is broken.
- **The store and export chain** — no gradle build/AAB, no Google Play Billing plugin, no
  Steamworks. `Store` is written and its seam is ready; the plugin wiring is the job.
- **Translations.** Every UI string goes through `UiKit.t()` and `locale/strings.csv`
  (`bash tools/bb.sh strings`) has 420 of them with an empty column per Play locale. A
  column is registered in `project.godot` only once it is filled — and the BuhurtRail font
  has no accented glyphs yet.

## The shape of the screen

`project.godot` is 960×540 with `stretch/aspect = "expand"`, which does **not** letterbox:
it hands the game a bigger canvas. Measured with `tools/probe_viewport.gd`:

| device | canvas |
|---|---|
| 16:9 | 960 × 540 |
| 19.5:9 (iPhone) | 1170 × 540 |
| 20:9 (most Android) | 1200 × 540 |
| 21:9 | 1260 × 540 |
| 4:3 (tablet) | 960 × 720 |

So the design always gets **at least** 960×540 and gains the rest in one axis. Nothing is
ever squeezed, and nothing gets bars. This matches what Retro Bowl's shipped app does.

**Never write a right edge as a number.** `UiKit.screen()` is the live canvas;
`UiKit.right_edge(m)`, `UiKit.span(m)` and `UiKit.bottom(m)` are the three measurements
every screen actually takes. `UiKit.DESIGN` is the 960×540 baseline, for the rare case
that wants it. `scripts/melee/melee_scene.gd` still keeps its own `SCREEN` const on
purpose — see `docs/ARENA-SHAPE-HANDOFF.md`.

---

## Layout

```
project.godot            Godot 4.6, Compatibility renderer, landscape, nearest-neighbour
scenes/                  16 scenes — Title, Season, Roster, Fighter, Market, Staff,
                         Coach, Records, Federation, Arena, Chalkboard, Create,
                         Bracket, Melee, Settings, Start
scripts/game/            the shell: every screen, plus UiKit, Juice, ArtBank, SaveGame,
                         Career, Audio, Settings, Session, AppLife
  ui.gd                  EVERY drawing primitive, the palette, UiKit.t() and confirm()
  app_life.gd            pause/close autosave, Android back + Esc, taps during a wipe
  season_scene.gd        the clubhouse shell; each tab is season_tab_<name>.gd
  save_game.gd           v12 in an RBH2 container (length + MD5), .tmp -> rename, .bak
scripts/league/          the meta game: season, world, tables, cups, office, arena,
                         contracts, market, federation, dilemmas, splits
  season.gd              the spine — every door the screens use; the work is in
                         season_bouts / season_cups / season_desk / season_winter.gd
  club_office.gd         the club's desk; office_books / office_crowd / office_staff.gd
scripts/melee/           the fight: sim, scene, tuning, traits, grades, report
  tuning.gd              EVERY tunable fight number, in one place (weapons included)
  melee_sim.gd           pure RefCounted, seeded RNG, no node deps
tests/                   49 files; fixtures/ holds golden saves
tools/                   bb.sh is the door; shot_* render, probe_* measure
locale/strings.csv       every UI string, one column per Play locale
docs/
  GAMEPLAY.md            the current design
  DIRECTION.md           the founding direction doc (10 Sep 2026)
  CONSTRAINTS.md         the six hard rules and how each is enforced
  REGISTER.md            the running log — every finding, with the measurement
  ARENA-SHAPE-HANDOFF.md what the arena chat owns
  JUICE.md, ART.md, LEAGUES.md, WORLD.md
shots/                   rendered screens
```

## The suite, and the toolbox

```
bash tools/bb.sh test              # the fast gate — parse, every test file, the shape sweep
bash tools/bb.sh test --balance    # the statistical tier: run before any balance change ships
bash tools/bb.sh bases             # career score on the five check bases, and the mean
bash tools/bb.sh list              # every probe and shot tool, one line each
```

`bash tools/bb.sh` with no argument lists the rest (probe, shot, titles, soak, fixture,
strings, sweep, tune, noise). CI runs the fast gate on push and the balance tier nightly
(`.github/workflows/tests.yml`) once the repo has a GitHub remote.

**A file passes only if** it exits 0, prints its banner with more than zero checks, prints
no `SCRIPT ERROR`/`Parse Error`, and prints no engine `ERROR:` that is not listed (with a
reason) in `tests/allowed_errors.txt`. Full output of every file is in `logs/tests/`.
Until 27 Sep the runner read exit codes only, and `test_save` had been crashing inside its
own fingerprint — asserting nothing — while the suite printed green.

Tiers: `RB_TIER=fast|balance` is exported to every test. A slow statistical measure runs
only in the balance tier; a file that is nothing but those says `RB_TIER: balance-only` and
is **listed**, not run, in the fast tier. Nothing is ever printed as a quiet SKIP.

A few worth knowing by name:

- `test_ink.gd` — measures drawn *text*: off the frame, on a control, off a panel.
- `test_shapes.gd` — renders the screens and samples pixels. Needs a display (xvfb).
- `test_save.gd` — round trip, a five-season career, torn-file backup, and every golden
  file in `tests/fixtures/` (write a new one with `bb fixture` **before** bumping
  `SaveGame.VERSION`).
- `test_audit_*.gd` — one check per fix from the 27 Sep audit.

And the pictures no headless check can replace:

```
bash tools/bb.sh shot melee 1170x540 300 /tmp/melee.png
bash tools/bb.sh shot season
```

**Readability has never once been settled by reasoning about it on this project.**

---

## The rules that are not negotiable

Six of them, in `docs/CONSTRAINTS.md`. The short version: an order expires, so you never
hold a fighter; a good player on a bad club still loses; drawing nothing is never punished;
the report blames the roster and never the thumb; the camera never goes over the shoulder;
and formation and strategy must outrank the thumb.

## Before you close a session

1. **Audit the previous session.** Standing instruction; it has found something every time.
2. **Run `bash tools/bb.sh test`. It must be green** — and `bb test --balance` too if
   anything that moves a number changed.
3. **Re-render anything visual you touched.** An image, not an opinion.
4. **Update `docs/REGISTER.md` in the same session** — record the *rationale* and the
   measurement, not just the decision.
5. **Search the dossier glossary before naming anything.** Any role, state, action, penalty
   or piece of kit. The sport has already named it, its name is more authentic, and it is
   free. `C:\Dev\HedgeKnight\research\buhurt-source-dossier.md`, section 8.
6. **Commit**, recording the decisions and the audit findings.

### Committing from a Cowork session

The desktop sandbox blocks file deletion until you allow it, and git has to delete its own
lock files. Ask for delete permission on this folder once per session (the prompt says why)
and git works normally. Without it, `mv` the locks aside before every git command:

```
mkdir -p _git_locks_to_delete && for f in .git/*.lock .git/refs/heads/*.lock; do [ -e "$f" ] && mv "$f" _git_locks_to_delete/; done
```

Work done in the cloud container lands as `git format-patch` files applied here with
`git am --3way`; compare `git rev-parse HEAD^{tree}` on both sides afterwards.

---

That the action layer exists to make the management layer *felt*, and not to be the game,
is the whole project in one line.
