# Career sims — 15 Sep 2026

Pete: *"let's have you do some career Sims and lets find a good balance for all
the features and difficulties. There's a lot of career variables now."*

`tools/probe_run.gd` plays twenty-season careers at every difficulty with a
manager who does the obvious things in the obvious order, **spending only what
the club earns** — no top-ups, unlike `probe_climb.gd`, which subsidises 120 CC
a year and therefore cannot see an economy at all.

---

## Where it landed

| difficulty | top division | yrs/promotion | finish | income | bank | buildings lost |
|---|---|---|---|---|---|---|
| Matched | 0.6 | 6.7 | 0.65 | 40.8 | 43 | 0.00 |
| Friendly | 1.2 | 5.0 | 0.62 | 45.8 | 48 | 0.00 |
| **Sanctioned** | **0.8** | **10.0** | **0.70** | **35.1** | **37** | **0.00** |
| Full Steel | 0.6 | 10.0 | 0.71 | 32.0 | 32 | 0.40 |
| The Hard List | 0.2 | 33.3 | 0.85 | 22.1 | 23 | 1.00 |

*finish* is where the club came in its division, 0.00 champions and 1.00 bottom.
*buildings lost* is grounds and facilities shed because a summer bill went
unpaid — the only failure state the economy has, and it now happens on the two
hardest settings and nowhere else, which is the right shape.

The spread is monotonic and it wasn't before.

---

## Four things the sims found

### 1. The difficulty setting did nothing if you pressed Sim

Five twenty-season careers at five different grades came back **byte for byte
identical**. `opposition_scale()` — the whole of `Grade` — was read in exactly
two places, both of them `MeleeSim.new`. So difficulty applied only to fights
you chose to play, and the SIM IT button on every fixture turned it off.

This is the third time this project has found the same shape: simmed events cost
no kit wear until 15 Sep, no arena wear until 16 Sep, and were fought at no
difficulty at all until now. **A discount for not playing the game.**

Fixed: `LeagueWorld.player_scale` carries the grade into the simmed fixture.
That one change is what produced the table above.

### 2. Training cannot climb the ladder, and it looks like it can

With the price and the throttle both removed — 245 levels over twelve seasons —
the developed squad is **+4 club power** over one left alone. `power_exact()` is
the mean of the *starting five*, and a level is one point on one of four stats:

| | cost | worth |
|---|---|---|
| a level | 4–40 CC | +0.05 club power |
| an arena | 6–22 CC | every home gate, forever |
| **a signing** | **11–18 CC** | **+3 to +6 club power** |

One signing is worth about a hundred levels and often costs less. And the squad
you are given has four of its five starters within six points of their ceiling
(Brand 37/38, Norrey 41/42), so training them is a dead end by design.

The first version of the sim manager bought levels first, the way the screens
imply you should: **36.9 of a 40.2-credit season went on the squad line, and the
club never built an arena in twenty years.** Reordering it — ground and market
first, levels out of what is left — is the single change that took the manager
from finishing 60% down his division to competing in it, and doubled how often
he went up.

That is a finding about the game, not just the fixture. A player has no way to
know any of it: the level-up screen shows an XP bar and a price, which reads
like the upgrade it is not. **This is the thing I'd fix next and it is a
signposting problem before it is a balance one.**

### 3. Relegation was a trapdoor

`TIER_CAP` is `[200, 2600, 34000, …]` — thirteen times a division. A club that
goes up, signs State League men to survive and comes straight back down carries
a wage bill 75% over its new cap, cannot sign anybody ever again, and decays.
`probe_ladder.gd` traced exactly that: up in year 6, down in year 7, then four
seasons of refusals while the squad fell from twelve men to six and the rating
from 33 to 22.

The game's own escape is to cut your most expensive man, and it works — but
nothing tells you that is what has happened, and the refusal you see is
*"Lowe wants $6 a week. That puts you $150 over the cap."*

### 4. The Backyard Circuit was the hardest division to leave

It promoted its champion only — the one rung in the pyramid with a single
promotion slot, and the one every career starts in. At the default grade that
was **one promotion per twenty seasons**; four divisions at that rate is a
sixty-season career before anyone sees the National Division.

Changed to two up, with the State League sending two down to match, so the
pyramid stays balanced and every division now runs the same 2-and-2 arithmetic.
Promotion pace roughly doubled at every grade.

---

## And what the gate change did

The venue work in this same pass (home pays full, away 45%, neutral 60%, all
multiplied by the ground it is fought in) took the gate from **1.4 CC a season
to 7.9** in a Backyard career. Members' subs are still the biggest line at 24.4,
but fighting is no longer a rounding error.

Per-season books across a whole career now read:

```
IN                          OUT
  Members' dues     24.4      The squad         14.3
  The gate           7.9      Facilities        10.7
  Prize money        7.6      The ground         5.6
  The ground         2.2      The club           5.6
                              Kit and harness    0.8
                              Travel             0.7
```

---

## What I did not change, and would ask about first

- **The yo-yo.** With two up and two down, a club now goes up, struggles and
  comes back. That is very football and might be exactly right; it is also why
  *finish* got worse in the table above. Worth playing before deciding.
- **The level price.** Making levels cheaper or worth more would fix finding 2
  in the numbers, but I think the honest fix is the screen telling the truth
  about what a level does, and that is a design call.
- **Members' subs as the biggest income line.** Still 58% of a career's money.
  The gate is no longer trivial, but the club is still mostly funded by people
  paying to belong to it rather than by fighting.
