# One crowd number, dues that bite, and promotion you can turn down
*15 Sep 2026 — the changes Part 3 of the Retro Bowl teardown argued for.*

Pete, having read the teardown, gave four directions. All four are built.

---

## 1. There is one crowd number now

> *"I don't like our 3 factors, there should be one. Notoriety should be
> something of a coach trait."*

`notoriety` and `members` are **deleted**. The chain is four links and it is
Retro Bowl's, with our arena in the middle of it:

```
fans  →  attendance (capped by the ground)  →  fill  →  band  →  the gate
```

- **`fans`** is the one population. It grows toward `fan_cap()` — capacity ×
  1.25 — on results, on crowds, and on a season in the top half; it bleeds every
  summer.
- **The band reads how full the ground is**, which is their bar exactly: *"for
  each third of this bar that is filled either in full or in part, you will
  receive one coaching credit."* Gates at 10 / 28 / 46 / 66 / 88 per cent.
- **The SIZE of the house is `Arena.gate_factor`**, where it already lived. The
  two multiply, so a packed back field pays full band at back-field rates and a
  third-full National Arena pays poorly at National rates.

The first cut banded **absolute heads** — 25 / 90 / 300 / 1,000 / 6,000, each
gate just under a filled ground — and it looked right on paper. It pinned the
whole bottom of the pyramid to band 0: forty people in a forty-seat field is a
*sold-out house* and it was being paid what an empty one was. `probe_run`
measured a career's whole gate at **6.3 credits a season**. Banding on fill
doubled it.

**Where notoriety went** is Pete's answer, and it is a better home than the
wallet: the coach's reputation now decides **what the dilemma deck offers him**.
Cards are `CLEAN`, `ANY` or `SHADY`; a well-regarded coach gets the federation's
fitting day, a coach nobody vouches for gets the pallet of plate with somebody
else's name inside the helm. The bands overlap between 9 and 11 so a reputation
crossing a line does not swap the whole deck on one tick.

`CROWD_PAY` also went from `[1..6]` to `[2..7]`. On the old fame ladder a club
climbed the bands once and stayed; on this one a club that stops filling its
ground **falls back down them**, and at `[1..6]` a struggling club earned a
sixth of the top band against costs that do not fall with it. Retro Bowl's own
bar is 1 / 2 / 3 — **their bottom band is a third of their top, not a sixth.**

---

## 2. The dues bite, and you can go into the red

> *"I'm not liking the dues portion, that should more be a league dues at the
> start of a season, one in which you CAN go negative but it's a good bite."*

`Federation.dues_for(members)` paid the club **24.4 credits a season across a
career — 58% of every credit it earned**, from a standing subscription. It now
runs the other way: `League.dues_for(tier)` is **6 / 14 / 24 / 38**, charged at
the roll-over, and `spend()` does not check — because a bill you can decline is
not a bill.

Taking the biggest income line out forced the rest of the economy to come from
people watching, which was the whole point:

| | before | after |
|---|---|---|
| **The gate** | 7.9 | **19.1** |
| The counter | — | 4.4 |
| Prize money | 7.6 | 5.6 |
| The ground | 2.2 | 2.8 |
| Members' dues | **24.4** | *gone* |
| | | |
| results-driven share | 42% | **91%** |

One knock-on worth recording: `UPKEEP_FRACTION` came down from 0.45 to 0.28,
because the recurring bite was being charged twice and the two together were 73%
of income before the club bought anything. That immediately broke a rule the
register has held since the bills went in — *no ground is profitable to simply
own* — because at 0.28 a National Arena paid 21 to own and cost 17 to hold.
`test_office.gd` caught it by name on the first run. **A rule kept by two numbers
that happen to agree is a rule waiting for one of them to move**, so
`arena_upkeep()` is derived from the retainer now rather than from the build
cost: 4 / 7 / 10 / 15 / 30, always more than the ground pays.

---

## 3. Promotion is an offer

> *"If you qualify for the next league, you can choose to advance, or stay within
> your league next season. A player may bust through the season but want to stay
> a season and continue building up their money, train players, or whatever they
> wish, and staying in a cheaper league would be beneficial."*

This is a better answer to the yo-yo than the one Part 3 proposed. I suggested
copying Retro Bowl's stadium — a thing you buy that narrows the swing — so a
promoted club could survive a bad first season up. Pete's version does not damp
the bounce, it **lets you decline it**: you go up when your squad is ready rather
than when the table says so, and the cheaper division you stayed in is the year
you spent getting ready.

It only works because the division costs money to be in. The two changes are one
change and neither works alone.

`blocked_by()` holds the season on it, like a dilemma card, because a decision
the player can walk past is a decision he walks past — and this is the biggest
one of the year.

---

## 4. The counter, and it comes with the ground

> *"Stadium damper could be food sales. Lemonade, bakery, brownies for back yard,
> progressing to real NFL beer sales and stuff at higher tiers."*

Two fields on each arena level, not a system — a second ladder beside the arena
would be a second set of prices, a second upkeep bill and a second screen, for a
decision that is always "yes, buy the food".

| ground | sells | packed, a home meet |
|---|---|---|
| Back field | Lemonade and a bake sale | 2 CC |
| Club gym | Tea urn, brownies, a biscuit tin | 2 |
| Fenced ground | A burger van and a coffee cart | 3 |
| Sports hall | Hot food, and a bar with a licence | 4 |
| Arena | Concession stands and beer on tap | 7 |
| National Arena | Concourse bars and four franchises | 11 |

**It is the damper and the damping is the point.** The gate reads the band and
swings with form; the counter reads the turnstile and does not. A club that loses
in front of a full house still sold them all a pint.

Tuned twice off the probes. Flat credits-per-head made a packed National Arena
worth **8,400 CC a meet** — the retainer's original bug in a new costume. At the
other extreme it was worth 2.0 credits a season, a line not worth the line.

---

## And the rest of the list

**Free agents span one division either side.** *"A free agent won't bother being
available if they aren't one league above or below the team's standing."* Half
your own division, a third from below, a sixth from above — so most of the list
is men you can carry, there is always a bargain, and roughly one in six is a
reach. The Backyard shelf now offers a **53/64 for 18 CC** against a squad whose
best is 41, which is a stretch signing that changes a season. It had no such
thing before: every man was drawn from your own band, so the market offered you
your own standard and there was nothing in it to want.

**Levelling leans toward theirs.** Four changes, all measured against
`probe_levels`:

- `xp_for` **reads the man's rating**. Their bar is `xp_level * 100` forever and
  it works because their XP income grows with production. Ours was 2 + 3 a down
  + 1 a round standing and nothing else.
- The bar rises **one rung longer** (cap 3 → 4): 8, 16, 24, 32.
- The price moves from half theirs to three quarters (`LEVEL_COST_PER` 2 → 3).
- And **their maxed-player valve**: a man at his ceiling turns a level into
  credits instead of being refused. Every point of XP a veteran earned was being
  thrown away.

A twenty-two-year-old still climbs 50 → 59 across eight seasons, so the rework
moved *when* and *what it costs* without moving how far a career climbs.

**Three armorer cards**, all rare (`weight: 3` against a default 10). A van in
the car park that will do the whole club before the first bout; the federation's
fitting day; and a pallet of plate going very cheap with somebody else's name
inside one of the helms. The deck already spent `armor` on one man and `kit` on
the whole book, so these are data rather than a system — and the cheap option is
always cheap for a reason.

---

## Where the career landed

`tools/probe_run.gd`, twenty seasons, spending only what it earns:

| difficulty | top division | yrs/promotion | finish | income | buildings lost |
|---|---|---|---|---|---|
| Matched | 0.4 | 33.3 | 0.77 | 31.5 | 0.00 |
| Friendly | 0.8 | 11.1 | 0.71 | 34.8 | 0.00 |
| **Sanctioned** | **0.6** | **20.0** | **0.78** | **31.5** | **0.20** |
| Full Steel | 0.6 | 33.3 | 0.82 | 28.5 | 0.00 |
| The Hard List | 0.4 | 50.0 | 0.85 | 27.4 | 0.00 |

Income is lower than the 42 it was before the dues flipped, and it should be —
that was a subscription. What matters is that **almost nothing is lost to unpaid
bills any more**, and that nine credits in ten now come from people watching a
fight.

## Still open

- **The promotion choice has no AI counterpart.** A CPU club never declines, so
  a division the player stays down in has one extra promotion slot that year and
  somebody who would not otherwise have gone up takes it. That is arguably right
  and it is certainly unexamined.
- **`pos` sits around 0.78 at the default grade** — the club finishes in the
  bottom half of its division more often than not. The gap on rating is only
  −5, so this is the sim's noise rather than the squad, but it is worth a look
  before anybody calls the default difficulty tuned.
