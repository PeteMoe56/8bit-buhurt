# The shelf, fixed

15 Sep 2026 · follows `FIGHTER-TIERS-15-SEP.md`

Four changes off Pete's read of the first measurement. The headline is the one
he opened with, because it invalidated every career number the probes had ever
produced.

---

## 1. The managers were buying the wrong man

> *"The simulations need to run on potential, not immediate power. I may have a
> guy with a power of 55 maxed, but there's a guy for signing that's starting at
> 54 with a max of 60s."*

Every manager fixture in `tools/` sorted the shelf by `overall()` and compared
against the weakest starter's `overall()`. A finished 55 beat a 54 who becomes a
62, six times a summer, for twenty seasons. **A market read on today's number is
a market that systematically buys the wrong man** — and the balance findings were
being measured through that mistake.

`Career.projected()` and `Career.worth()` now answer it. Two things decide how
much of a man's gap he actually closes and both are age: `roll_potential` already
shrinks the gap with age, and he needs the runway to use it — `PEAK_SKILL` at 35
is the last peak to arrive. Double-counting age here is deliberate. A 34-year-old
with four points in front of him will not find them.

```
  55 maxed, age 30   ->  worth 55
  54 -> 64, age 24   ->  worth 60
```

The free-agent list now **sorts** on that too, because a card that shows both
numbers and orders on the wrong one teaches the player to distrust the order.

### What it did to the career

```
policy        TOP      up   power     gap     before        after
sign          0.8     1.2    34.8    -3.2   TOP 0.4    ->   TOP 0.8
both          0.6     1.0    33.8    -2.6   gap -9.4   ->   gap -2.6
```

Reading the shelf on potential **doubled the promotion rate** — 0.4 divisions a
career to 0.8, 0.8 promotions to 1.2. Final club power comes out slightly lower
because the club is measured in a harder division than the one it used to end in.

---

## 2. Backyard stays as it is; National gets a foreign man

> *"That's fine, backyard is suppose to be all beginners... A rare foreign man
> that upfront costs are large can show up, but otherwise, nothing above
> national."*

`clampi(tier + step, 0, 3)` sent the one-in-six reach draw back into your own band
at the top flight, so a club arriving at National — with the most money it will
ever have — found a **flatter** shelf than the one it left.

`Market.FOREIGN_CHANCE` is one in four of those reach draws, at the top rung only:
rated 87–94, priced in a sixth **Marquee** band at 174 CC, which is two and a half
seasons of everything a top-flight club has spare. Roughly one name every three or
four summers.

He is not a fifth division. He is one name from outside the world, and the card
says **"foreign"** rather than "step up" — derived from where he stands, so a
foreign man who fades under the ceiling stops reading as one.

The best man on a National shelf went **82.5 → 85.6**, his ceiling **84.9 → 88.2**.

---

## 3. The fee curve, un-inverted

The band was measured against `League.TIERS[t]["power"]` — the standard of the
*clubs in the division*, not of the *men on offer to them*. A third of every
shelf is drawn from the division below, so a third of every shelf sat entirely
underneath the scale pricing it, and the bands get wider the higher you climb.

`League.TIERS[t]["shelf"]` is the range the list actually spans, measured. Fee
bands across the pyramid, before and after:

```
              Journeyman       Star        Marquee
  before      30% -> 59%    19% -> 8%          —
  after       23% -> 17%    8% -> 18%     6% -> 9%
```

Flat, and the Star band now *grows* with the division instead of shrinking.

A second bug surfaced the moment Marquee claimed the top of the scale: `BANDS`
ended at `1.00`, which made Star fire only at `t == 1.0` — **a band exactly one
rating point wide**, held open for weeks by a `clampf` that swept everything above
the range into it. *A band held open by a clamp is not a band, it is a rounding
artifact.* Four edges at fifths now.

---

## 4. Money refuses again

`tools/probe_wallet.gd` is new and measures the one number a fee has to be a
fraction of: what a season actually leaves a club for its squad.

```
division                 in  upkeep    dues   slack
Backyard Circuit       27.7     5.5     6.0    16.2
State League           55.7     9.2    14.0    32.6
Regional League        77.7    16.5    24.0    37.2
National Division     132.5    27.5    38.0    67.0
```

The fee was a flat 1/3/6/11/18 at *every* rung — a whole season's spending money
in the Backyard Circuit and pocket change at National. It is now a **share of
that slack**, so the Backyard column is unchanged (that division is tuned and
plays right) and everything above it scales:

```
             BYC   STL   REG   NAT
  Journey      1     2     2     4
  Steady       3     6     7    12
  Good         6    12    14    25
  Strong      11    22    25    46
  Star        18    36    41    74
  Marquee     42    86    96   174
```

Share of each shelf a club can actually afford: **97–100% → 86 / 81 / 79 / 73%**.
About one man in four at National is now out of reach, which is what a shelf worth
reading looks like.

Note that slack does *not* climb as fast as income does, because the dues climb
with it — State 33 to Regional 37 on a 40% jump in income. That squeeze is real
and the fee ladder follows it honestly rather than smoothing it out.

---

## Still open

- **Promotion pace.** TOP 0.8 over twenty seasons means an average career gets
  from the Backyard Circuit to about the State League. That is a separate axis
  from this work and it is the next thing worth measuring.
- **Levels still do not pay.** `both` buys 13.4 of them a career now (up from
  5.8) and still reaches a lower division than `sign` does. The finding from
  `FIGHTER-TIERS-15-SEP.md` stands: a level needs a different *job*, not a
  different price.
