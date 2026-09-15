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
border — the artwork's *own* outlines are black, so a color key punches holes
through the helmet — then cut into six files, each at the size it is drawn at,
because the project runs nearest-neighbor filtering and a texture the engine
scales is a texture with chewed edges.

`scripts/game/brand.gd` is the one place that knows the name and the mark. The
name is read from `application/config/name`, the same copy the APK manifest and
a store listing are built from.

Two bugs fell out of it: the front door hung every element off `const CENTER :=
480.0`, so on a 1170-wide handset the whole screen sat 105 pixels left of center;
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
| 14 | **Difficulty settings cannot be found** | `done` |
| 25 | **No weekly income, ever.** You are set to lose, and you die out if you do not win | `answered` |
| 8 | **No fan information anywhere**, and none on the fight card | `open` |
| 16 | **"room" and "name" are never explained** — the two dilemma currencies | `done` |
| 21 | Squad needs **sort-by and min/max** on skill / age / cost | `done` |

**14** — not moved, signposted. `Season.grade`'s own note says why it lives on the
career and not in Settings: *"volume is a property of the room you are sitting
in, and difficulty is a property of the run."* A grade you could change at the
title screen between fixtures would make the table meaningless. So Settings now
carries a **THIS CAREER** panel that names the grade and says where it is set —
because a setting that is deliberately somewhere else still has to be findable
from where people look for it, and an absence with no explanation is
indistinguishable from an omission.

**16** — `room` is morale and `name` is notoriety, and neither word appeared
anywhere else in the game. A key sits on the dilemma card's rule now, read out of
`Dilemma.FX_WORD` so renaming a currency renames its own caption.

**23** — two faults. The label was military and the game is not: every other
screen calls this the *bus*. And pressing it on a full eight is refused, with a
sentence that printed into the button row's drop shadow — that is the "it's
hidden". The button now says `Off the bus`, goes **dead** when the move is
impossible, and the reason prints on the line above. `set_active_would()` answers
in four words what `set_active` already knew.

**26** — three screens in the whole game played anything: the front door, the
slot picker, and settings, all asking for the same track. **Thirteen other menus
ran in silence**, including the one a player spends most of his time on. Nobody
had ever added the line. It is in `UiKit.ground()` now, which already runs on
exactly the set of screens that want it and none of the ones that do not —
`melee_scene` paints its own ground, so the fight keeps its own sound.
| 23 | **"Stand down" is unexplained**, and hides itself when pressed | `done` |
| 26 | Put the **settings-menu music into every non-fight menu**; find something else for what it replaces | `done` |

**25 — the money is there and you cannot see it.** Measured before anything was
changed (`tools/probe_purse.gd`): a club walked from its first event goes **8 →
92 CC across three seasons**, about 21 in the first and 28 by the third. So "no
income weekly ever" is not literally true.

What is true is that none of it was ever *shown*. It arrived as +1 and +2 after
an event and a lump at the season roll, against a purse in the header that simply
read a different number than it had a moment ago. **A club that cannot see itself
earning is a club that is not earning, as far as the player is concerned.**

Every credit in now passes through `ClubOffice.take()` with a reason attached,
and the clubhouse shows the last four — *The gate +3, Won the event +2, Members'
dues +6*. No amount changed. It is a screen fix, because the problem was a screen
problem.

What it costs to act, for scale: a cap raise 4 CC, a bus place 6, a facility 3, a
serviceable harness 3 (×8 = 24). So season one earns about one decision.

**15 is the ladder, from the other end.** The measured result was a club that wins
its division four times in forty seasons and finishes last in the one above every
time. One problem, two symptoms — and the ladder half is still open.

> **PARKED FOR PETE.** A club that finishes 4th-6th earns **no position money at
> all** (`CREDITS_BY_POSITION` is `[6, 4, 2]`). Everything else — the gate, dues,
> the win bonus — is small and slow. That is the shape of "you die out if you do
> not win", and whether a bottom club should have a floor under it is a design
> call, not a bug.

---

## Design — needs a decision before any code

| # | Item | Status |
|---|---|---|
| 5 | **Rebuild the Market** as the Quartermaster | `done` |

### 5 — the Armorer

Pete chose the quartermaster direction. What it turned out to be is smaller and
better grounded than a new gear system, because **most of it already existed and
had no screen.**

`FighterCard.armor` decays every event off the captain's regime, multiplies a
man's base through `effective_base()`, and gates `passes_inspection()` at 0.35 —
below that line the marshals will not pass him and he cannot go out at all.
Direction §4 has said since day one: *"The cap isn't money-per-player, it's how
many bodies you can put on a plane and how many harnesses you own that pass
inspection."* All of it was reachable one man at a time, from a row on the
fighter card, behind two taps.

Three things were measured before a line was written (`tools/probe_kit.gd`):

| Finding | |
|---|---|
| **An AI club has no kit at all** | It is a `power` integer drawn from its tier's band, not a squad of men. It cannot wear a harness out or repair one. The player is the only club on the ladder paying this tax. |
| **A simmed event cost no wear** | `_apply_regime()` ran from `post_bout`, not `skip_event` — 24 simmed events left a squad on exactly the kit it started with. A discount for not playing the game. **Fixed.** |
| **And the tax is a rounding error** | The whole legal armor range, 0.35 to 1.00, is worth **1.37 rating points**. The 0.90→1.00 a repair buys is worth 0.24. Repairing thirteen men before every event for 24 events moved club power by **zero**. |

So: **inspection has teeth and the multiplier does not.** The screen is built
around the part that bites. The new part is one integer per fighter — a harness
*grade* that sets the ceiling a repair can reach and how fast the kit wears:

| Grade | Ceiling | Wear | Cost |
|---|---|---|---|
| Borrowed | 90% | ×1.00 | — |
| Serviceable | 96% | ×0.86 | 3 CC |
| Fitted | 100% | ×0.72 | 7 CC |
| Tournament | 100% | ×0.58 | 14 CC |

Nothing on that ladder is worse than the game was before it existed — the first
cut had Borrowed capped at 82% and wearing ×1.30, which would have shipped a
ceiling cut and a 30% wear increase to every club as a side effect of adding a
shop. *A feature that nerfs the baseline to make its own upgrades look good is a
feature charging you to undo it.*

Free agents moved to the **Squad** tab, which kills the tab-in-a-tab.

> **PARKED FOR PETE — one balance decision.** Armor is worth 1.37 rating points
> across its entire range. If a harness is meant to be the cap Direction says it
> is, that range wants widening, and it is **one constant**:
> `FighterCard.effective_base()` is `base * lerpf(0.78, 1.0, armor)`. Drop the
> 0.78 to, say, 0.55 and the range becomes ~3.5 points a man, ~3.5 club power
> across a five — which is the difference between a shop and a decoration.
> `test_quartermaster.gd` asserts the current figure, so moving it fails the
> suite and points at this paragraph rather than letting the docs go stale.

| # | Item | Status |
|---|---|---|
| 20 | **The formation and play slots on the fixture card should not be there.** — `done` |
| 9 | **Pre-fight should show the field**, idle fighters behind it, positions updating as a formation is picked, and a dashed line of the plan |
| 7b | Remove **"A night out"** — *"pretty dumb"* — `done`. The verb stays and is still tested; the button is gone from the busiest row in the game. |

9 lands in `melee_scene.gd`, which belongs to the arena chat — see
`docs/ARENA-SHAPE-HANDOFF.md`.

---

## Where this list came from

Sixteen screenshots, one continuous session from the front door through a season
opener, a fight, a dilemma, a contract and the chalkboard. The shots are the
evidence and they are worth keeping: half the findings in `docs/REGISTER.md` are
"the screenshot showed something no test could see", and this run is the largest
single batch of those the project has had.


---

## What #20 and #21 turned into

**21 — the sort goes on the reserve, not on the eight.** That is the design
decision rather than an omission. `starting_five()` picks the five by walking
roster order, so **the left column IS the depth chart** — that is what made
`swap_order()` the fix for #22, and sorting it by wage would sort away the one
thing it says. A screen that let you re-sort it would also have to decide whether
tapping two men swaps their *display* places or their real ones, and there is no
answer a player would guess right.

The reserve has no such order. Nothing reads it and nothing depends on it, and it
is the list you scan when you ask "who is my best nineteen-year-old". So it sorts
— rating, age, wage, ceiling — and the eight stays the depth chart.

"Min/max" is answered as a **spread**, not a filter: `age 19-31 · rated 21-41` on
the heading line. Thirteen men is a list you read, not a set you query; a filter
on a squad this size hides men to save scrolling that is not happening.

**20 — the slots are gone and three things took their place.**

The slots were a redundancy. `Fight it` leads to the walk-out and then to BEFORE
THE CHARGE, whose entire job is choosing a shape and a play *with the men and
their condition in front of you*. Choosing them on a card that shows a league
table is the same decision taken earlier with less information, and then taken
again ten seconds later. **A decision offered twice is a decision the player
makes once and then has to remember he already made.**

- **Sim asks first.** It is the one button on that screen that spends a fixture
  and cannot be undone — the result is written, the week ticks, kit wears — and
  it sat one thumb away from Fight. It is a modal now, the same shape as the
  shop, and it says what a sim costs.
- **The schedule** fills the hole: what is left this season, home or away, the
  current matchday lit.
- **The ticker** runs along the foot of the club tab and nowhere else. Results
  first, remarks second, one in four. A ticker of pure jokes is a screensaver; a
  ticker of pure results is a second league table. It reads `season.table()` and
  the club's own log rather than recomputing either, so it cannot disagree with
  the table sitting above it — and it is built once an event, not once a frame.

**And a bug fell out of photographing it:** `Dilemma.fill()` was applied to the
card's BODY and not to its options, so a card whose answers name the club printed
`{club} is not an advert.` One card in the deck uses the tokens in its blurbs,
which is why it had survived. *A substitution applied to some of the strings is a
substitution nobody can rely on.*

---

## Still open

| # | Item | Why it is still here |
|---|---|---|
| 4 | **Squad redesign** | Sort, spread and promote-into-the-five all landed; a full visual rebuild wants a mockup Pete approves rather than my taste applied at 4am |
| 3 | **No tutorial** | The largest single item on the list and the one most shaped by what Pete wants the first ten minutes to feel like |
| 8 | **No fan information** anywhere, including the fight card | Notoriety, the crowd band and `crowd_meter()` all exist — this is a screen, like the armorer was |
| 1, 2, 6, 12, 17 | The rest of the **formatting sweep** | 7 and the clubhouse are done; the title, slots, free-agent cards, dilemma card and chalkboard are not |
| 2 | **No "Name Your Club"** step | Part of the same pass |
| 9 | The pre-fight **field with idle fighters and a dashed plan line** | `melee_scene.gd` — the arena chat's, and written up in the hand-off |
| 15 | **The ladder** | Unchanged and still the biggest question in the game |
