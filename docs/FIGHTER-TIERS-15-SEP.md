# The fighter tiers, measured

15 Sep 2026 · `tools/probe_shelf.gd`

Pete asked whether the fighter tiers are written in and, if so, to simulate
them. They are — in **three** senses, which is worth stating plainly because
"fighter tiers" could mean any of them and they do different jobs.

| tiering | what it is | where it lives |
|---|---|---|
| **The division he came from** | `Market.pool` draws each man from the division below, your own, or the one above — stat ranges 30–46 / 40–58 / 52–70 / 64–86 up the pyramid | `Market._band_step`, new 15 Sep |
| **The fee band** | Journeyman / Steady / Good / Strong / Star at 1 / 3 / 6 / 11 / 18 CC, measured against the division he is being signed **into** | `Market.BANDS`, older |
| **His harness** | Borrowed / Serviceable / Fitted / Tournament — a tier on the **kit**, not on the man | Quartermaster, older still |

Only the first two are what this probe is about.

---

## Part A — what is actually on the shelf

24 summers a division, seed 4242.

```
division              best  worst ceiling   below     own   above carriable
Backyard Circuit      49.1   28.3   53.4     17%     69%     14%      99%
      fee bands: Journeyman 30%  ·  Steady 12%  ·  Good 22%  ·  Strong 17%  ·  Star 19%
State League          61.6   35.4   64.5     20%     65%     15%      99%
      fee bands: Journeyman 38%  ·  Steady 13%  ·  Good 15%  ·  Strong 15%  ·  Star 19%
Regional League       73.7   41.7   76.8     35%     50%     15%      97%
      fee bands: Journeyman 49%  ·  Steady 13%  ·  Good 10%  ·  Strong  9%  ·  Star 18%
National Division     82.5   54.8   84.9     35%     60%      6%     100%
      fee bands: Journeyman 59%  ·  Steady 11%  ·  Good 10%  ·  Strong 12%  ·  Star  8%
```

The shelf climbs with the pyramid the way it should: the best man on offer goes
49 → 62 → 74 → 83, the worst 28 → 35 → 42 → 55. That part works.

Three things do not.

### 1. The ends of the ladder lose a third of the variety, silently

`clampi(tier + step, 0, 3)` is doing more work than it looks like. At the
**Backyard Circuit** there is no division below, so the 33% of draws meant to be
bargains clamp back into your own band — which is why "below" reads 17% instead
of 33%. At **National** there is nothing above, so the 17% meant to be reaches
clamp down, and "above" collapses to 6%.

The bottom of the pyramid loses the bargain. The top loses the reach. **The reach
is the one that matters** — National is where a club has the most money and, by
this measurement, the least to want with it. A player who fights twenty seasons
to reach the top division arrives at a flatter shelf than the one he left.

### 2. The fee curve runs backwards

Journeyman share goes **30% → 38% → 49% → 59%** up the pyramid. More than half a
National shelf is a 1-CC man.

The cause is arithmetic rather than intent. `band_of` measures a rating against
the division doing the signing, the pool's lower tail is fixed at one whole
division down, and the bands get *wider* as you climb (Backyard is 16 points
across, National is 22). So the below-tier draw sits entirely underneath the
band it is being priced against, and sits further underneath the higher you go.

The richest division has the cheapest shelf. That is exactly inverted.

### 3. Money almost never refuses a signing

`carriable` — his fee inside a season's slack **and** his wage under the cap
beside twelve ordinary men — is 97–100% at every rung. The economy work of the
last two days built a club that has to choose between a ground, a cap raise and
a man, and **none of that tension reaches the market.** What actually refuses a
signing is the 13-man book and the "is he better than my weakest starter" test.
The credits are decoration.

---

## Part B — three managers, twenty seasons, spending only what they earn

Identical in every respect except where the money goes. Five seeds.

```
policy        TOP      up   power     gap  signed  bought  placed
train         0.2     0.2    22.4   -11.6     0.0    24.0   101.4
sign          0.4     0.8    35.8    -2.2    33.6     0.0   134.0
both          0.6     0.8    33.4    -9.4    34.6     5.8   124.6
```

*TOP* highest division reached (0 Backyard, 3 National) · *gap* final club
rating minus the division leader's · *bought* levels **paid for** · *placed*
levels the squad **earned** by fighting, which is free, so all three place them.

### The market is the ladder. Training is not.

A manager who only trains finishes on **22.4** club power and **11.6 behind**
his division leader. A manager who only signs finishes on **35.8** and **2.2
behind**. Same money, same twenty years.

And the sharpest number here came out of a bug. The first cut of this probe had
`train` buy no levels at all — it finished at **22.0**. Fixed, buying 24 paid
levels a career, it finishes at **22.4**.

> **Twenty-four bought levels are worth +0.4 club power.**

That is roughly 290 CC across a career. One Strong signing is 11 CC for +3 to
+6. A level is worth about a hundredth of a signing and can cost more — which is
what `probe_dev.gd` measured (245 levels, +4 power) now confirmed under a live
economy with real prices.

`both` is the proof that this is not a fixture artifact: given the choice, it
bought **5.8 levels in twenty years**. The market ate the money first, correctly,
every time. **The level economy is not a choice a rational manager ever makes.**

### One caveat on the gap column

`both` shows a worse gap (−9.4) than `sign` (−2.2) while reaching a *higher*
division (0.6 vs 0.4). The gap is measured against whoever leads the division
you end up in, so climbing makes it worse by definition. Read TOP first and gap
second.

---

## What was fixed today off the back of this

**The seam was invisible.** Both of the first two tierings are deliberate seams —
Pete's item 8, *"coarse tiers somewhere, so there is a seam to game"* — and the
market screen showed the *output* of each (a rating, a price) and neither of the
rules that produced them. A player could finish a career and never learn either
existed.

- `Market.step_of` / `step_word` — read off the rating against the division's
  band, not remembered from the draw, because a man generated above who came out
  at the bottom of it really is an own-division signing, and a label that
  disagrees with the stars teaches a player to ignore labels.
- The card now prints the **fee band** at the foot, beside the fee it explains,
  and **"step up"** / **"depth"** in the header corner — blank at your own
  standard, because half the shelf is there and stamping "your level" on three
  cards in six costs a corner to say nothing.
- `shots/market.png` then showed two things nothing else could: `DIM` is a color
  chosen to recede against a *panel* and was nearly invisible on a green position
  band, and the wage-bill panel had been drawing its label and its figure through
  each other in 124 pixels. **A panel is one control to `test_layout.gd` and
  three strings to the eye.**

---

## Open, for Pete to decide

1. **The top of the pyramid has nothing above it.** Either give National a draw
   that isn't a domestic division — an invitational, a foreign club's man looking
   for a season — or accept a flat top shelf deliberately and say so.
2. **The fee band should probably be measured against the man's own division,**
   not the one signing him, or the pool's lower tail should scale with the band
   width. Otherwise the shelf gets cheaper the richer you get.
3. **Levels need a different job, not a different price.** Priced honestly
   against what they deliver they would cost almost nothing, which makes them
   noise. The alternative is to stop having them compete with the market at all —
   e.g. a level raises a man's *ceiling* rather than his current rating, so
   training becomes how you keep a young signing rather than a worse way of
   buying an old one.
