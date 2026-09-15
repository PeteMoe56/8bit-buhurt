# The six constraints

**Rebuilt 10 Sep 2026 for the new core loop (`docs/GAMEPLAY.md`).**

**The live suite is `tests/test_melee.gd` — twelve checks, all passing.**

```
godot --headless --path . --script res://tests/test_melee.gd
```

> `tests/test_sim.gd` is the **dead** design's suite and carries a stale banner. It still
> passes, which is worse than failing. It is history, not a gate.

The direction doc calls "two half-games" the primary failure mode: an ambitious melee sim
eats the schedule and ships a mediocre action game bolted to a mediocre manager. These six
rules are the mechanism that prevents it. Four survive the rebuild unchanged, one is
strengthened by it, and one has to be replaced outright.

---

## C-1 — ~~Hands-on ≤ 2 min per bout~~ → **the order expires**

The old ceiling was a switch budget. It is gone, and the replacement is not a budget at
all: **an order is consumed, not held.** You draw a man a path; he walks it; the AI takes
him back. No input path writes a fighter's position, ever — you supply a destination and a
decision and the sim owns every frame in between.

That is what stops this being an RTS, and it is structural rather than a cap, which makes
it better than the thing it replaced. Pete's model, and he was right that the three-unit
version I proposed was over-constraining to protect a ceiling this design does not need.

## C-2 — ~~Cap hero swing at ~30%~~ → **half of it survives**

There is no hero now, so "hero swing" measures nothing. The half worth keeping is the half
that always mattered:

**A good player on a bad club still loses.** A roster 12 points light everywhere, played
hard, wins **0%** of bouts. That is the pressure that sends a losing player to the front
office instead of to a practice mode.

**This test now carries the whole load.** Pete, 10 Sep 2026: *"Thumb is supposed to be
better, it engages the player."* Orchestrating moves an even match 48.6% → 87.2% and that
is intended, not a defect — so the thumb is deliberately uncapped and C-2 is the only thing
between this design and "the club does not matter". It is the most load-bearing number in
the suite.

## C-3 — Auto-sim always available, never punished → **strengthened**

There are no difficulty modes: *the AI will choose unless you choose*, and every prompt
opens with the AI's answer already in it. He holds at range while it is up and commits on
the timer, so ignoring one costs nothing — no time, no position, no penalty.

**Measured:** drawing nothing at all wins **46%** of an even mirror.

## C-4 — The report attributes losses to management, not reflexes → **unchanged**

Every line in `MeleeReport` comes from state a management decision could have changed —
gas, harness condition, which position a man was fielded in, the formation, the strategy —
and never from input accuracy. **Measured:** across 40 bouts it names a gas problem 32
times and the player's hands zero times. The test greps for reflex-blaming phrasing and
fails if any ever appears.

The gas line is causally true rather than flavour: a man under 30% of his tank wears down
1.9x faster in a clinch, so gassing really is what puts him on the ground.

## C-5 — Broadcast camera, never a player camera → **unchanged, and now free**

The old design had to resist going over-the-shoulder because it put your hands on one man.
This one never does. You are looking at the whole list because you are directing the whole
list, so the constraint and the design now agree instead of pulling against each other.

Still checked with a render rather than an opinion — `tools/shot_melee.gd`, which can wait
for the exact frame a prompt is open rather than guessing a frame number.

It has now earned itself four times: ten indistinguishable specks on the list; a four-man
pile fused into one shape; the whole melee slid into one corner with two thirds of the
screen empty; and a **deadlock between rounds** — picking a strategy re-opened the corner
on the next frame, and since the sim only ticked while the fight screen was showing, the
corner clock never ran. That last one was unreachable by any headless test, because
headless never draws the corner.

## C-6 — ~~Orders outrank hands~~ → **REWRITTEN, Pete 10 Sep 2026**

The direction doc's sixth constraint said orders *"should move outcomes more than the drags
do."* Pete overruled it — **"Thumb is supposed to be better, it engages the player"** — and
for a while it sat retired, with a leftover line in the README saying formation and strategy
must outrank the thumb. That line was never true and never tested, which is exactly how a
wrong rule survives: **the one constraint with no script was the one that was wrong.**

Pete's replacement, 10 Sep 2026:

> *"Player manipulation, when done well, should give an advantage. A great player should be
> able to thumb-manoeuvre a win out of being out-positioned and out-strategized. Out-powered
> by a heavy degree along with those things however should result in losses."*

So it is not a flat ranking, it is **a ladder: the roster beats the thumb, and the thumb
beats the tactics.** Which makes C-6 two claims and a boundary, and every one of them is a
number rather than an opinion. `tests/test_c6.gd`:

| | |
|---|---|
| **C-6a** the thumb beats the tactics | in the worst setup on the board against the best, on an identical roster, a good thumb must still win |
| **C-6b** the roster beats the thumb | there must be a roster deficit inside the sweep where the thumb stops paying |
| **C-6c** a heavy degree is a loss | at the far end of the sweep, played hard, under 40% |

C-2 already tested the easy half of C-6b at 12 points light. What was missing was the
**boundary** — and "a heavy degree" is a feeling until it is a number, which a designer
cannot balance.

**Two things the first version of this suite got wrong, both worth keeping:**

- **It chose its own baseline from an under-powered sample.** It swept all twenty
  formation/strategy pairings, picked whichever lost hardest, and hung every assertion on
  that pick — off ten bouts each. Re-measured on a different seed base, the same sweep moved
  its "best" pairing from 100% to 83% and would have picked differently. **A test that
  derives its own pivot from noise is measuring the seed, not the game.** The pairing is now
  a written-down constant with the date it was measured.
- **Its numbers are softer than they look.** Individual cells moved five to ten points
  between runs at 10-24 bouts. That is why every assertion sits at a round threshold (50%,
  40%) and none of them sits at a measured value.

What replaces C-6 as a *design* idea is still **02.26**: a strategy is an opening plan that
expires, and what a side does after it expires is the difficulty curve rather than a stat
bonus.

---

## What the last build's tests caught

Kept because the defect classes outlive the design that produced them, and because the
protocol's standing rule is that a defect a script could have caught should become a script.

- **A team-order asymmetry.** Clinches were opened inside the per-fighter step, so team 0
  got first refusal on every engagement every tick; the fighters it shut out went and
  assisted instead, and the assist bonus handed team 1 an 18% edge in a mirror match. It
  would have surfaced to players as "the AI cheats." **A mirror match must be a coin flip,
  and the new sim needs this test on day one** — it is even more exposed now that lane
  shifts and gangs decide the fight.
- **A random walk scaled by `dt` instead of `sqrt(dt)`.** Two identical fighters could
  contest for eight seconds and neither would ever win. Any contested roll in the new
  design has the same trap.
- **A verb that was a trap.** The AI got the upside of a commitment without paying its
  cost, so playing well was measurably worse than not playing. **Whatever the AI does in
  the three menus, it must pay the same prices the player pays.**
- **Readability could not be reasoned about**, and still cannot. Every readability defect
  on both builds was found by looking at a picture.
- **A stat that sounds important in prose is not one that is balanced.** Base was written
  up as "the quiet stat that wins rounds" and given to every fighter ~10 points above his
  strength. The takedown formula reads `strength - base`, so the term was negative for
  nearly every pairing in the game and two even clubs put 0.0 men on the ground in four and
  a half minutes of fighting.
- **A wear-down loop needs a source of wear.** Stability only fell to a **Hit**, and Hit is
  not in the clinch menu, so a clinch could not go anywhere on its own. Found by a true
  mirror fixture, which is worth keeping precisely because it is degenerate.
- **A test that cannot fail is worse than one that does.** GDScript lambdas capture locals
  by value, so `int` counters assigned inside a signal handler never reach the outer scope.
  Two new tests reported "0 illegal round endings" and "0 bouts settled in two rounds" —
  and **both passed green** — because their counters were dead. The tell was that "0 of 80
  bouts settled in two" is arithmetically impossible in a best-of-three. Every accumulator
  a handler touches is now an Array or a Dictionary, which are reference types.
- **A boolean where a threshold belongs.** Difficulty tiers were sets of on/off flags, and
  the beginner tier's `reads_wear: false` meant a Green side **never attempted a takedown
  in a clinch at all** — so it had almost no route to putting anyone down and lost 95% of
  bouts. The flag read like "he is worse at spotting a worn man"; it actually meant "he
  cannot see one, ever." **A capability that has a degree should be stored as a degree.**
  As a number (`wear_read`: 0.40 / 0.55 / 0.70) the same three tiers land at 63%.
- **A fingerprint that cannot tell two things apart proves nothing.** The determinism check
  compared two worlds on `tier/season/power` — and the player's power never moves in that
  run, so two different seeds that happened to leave him in the same division produced an
  identical string and the test reported a determinism failure that was really a
  three-character hash. It now compares every club, every division and every point.
- **Invented entities must be deleted by whoever invented them.** Worlds mints fourteen
  foreign clubs a year with `tier: -1`. Left on the books they grow the club list forever
  and eventually walk into the first loop that iterates the pyramid — the same silent,
  cumulative failure as a division that leaks a team a year, and it now has its own check.
