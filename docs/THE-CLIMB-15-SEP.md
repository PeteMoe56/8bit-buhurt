# The climb

15 Sep 2026 · `tools/probe_pace.gd`, `tools/probe_growth.gd`

> *"20 seasons is a bit much, that should be about 10 for an above average
> player."*
> *"99 overall should be the top of the goal... 1 point a season seems dismal as
> fuck."*

Both true. What follows is what was actually wrong, in the order the instruments
found it — five separate faults, four of them bugs rather than balance.

---

## First: is it the squad or the table?

Two causes were possible and they want opposite fixes. `probe_pace` asks both.

**The table is fine.** A club planted at a stated rating and simmed:

```
division            vs leader   finish  top two
Backyard Circuit          -6     0.46      30%
                           0     0.28      65%
                           6     0.13      85%
National Division         -6     0.44       5%
                           0     0.19      35%
                           6     0.10      65%
```

Match your division's leader and you go up in one year out of two. The ladder
was never the wall.

**The squad was.** Same probe, a competent manager, twenty seasons:

```
season   power  leader     mid  finish     CC signed    age
     1    36.8    45.0    39.2    0.68   23.0    0.0   27.7
    10    32.2    47.0    41.2    0.70   35.6    1.6   31.2
    20    34.2    48.4    41.8    0.72   50.4    2.2   31.8
```

Thirty signings over twenty years. The club rating **never moved**, the starting
five **aged from 27.7 to 31.8**, and the club finished each season sitting on
**fifty credits it never spent** in a division where the best man on the shelf
costs eighteen. Nothing was refusing it. Something else was wrong.

---

## 1. The club never played its best men

`starting_five()` walks `active_eight()`, which walks `roster` **in order**, and
takes the first fit man who plays each slot. Roster order is the depth chart —
and a new signing is appended to the **end** of it. Sign a 49 into a club whose
32 is listed first and the 49 does not play. Once eight men are active he is not
even on the bus.

`swap_order` gave the player the verb back on 15 Sep; nothing did the job. So
`MeleeClub.best_line()` does it in one call: the eight best fit men travel, and
the best man for each slot goes to the front.

> **Every career measurement this project has ever taken was taken on a club
> that never picked its best team.**

Line-picking alone: power 36.8 → 45.0, and the aging reversed.

*This wants a button on the Squad screen. A human hits the same trap after every
signing, and silently loses a season to it.*

## 2. Nobody off the line developed — ever

Only `starting_five()` earned XP. Eight travel, five fight; the other three and
the five in reserve earned **nothing, at any age, for their whole careers**. A
club could not develop a player it was not already starting, so the only way to
bring a twenty-year-old on was to play him instead of a better man and lose the
season for it. There was no such thing as a pipeline.

The bench now earns 60% of what a starter earns and the reserve 30% — he trains
all week either way. Both XP paths call one function, so a simmed week and a
fought week cannot drift apart on the ratio.

## 3. The valuation bought the oldest man on the board, every time

`worth` was `lerp(projected, overall, 0.40)` — a blend of what he is and what he
becomes. On any blend weighted at all toward today, a finished 49 beats a 42 who
becomes a 52. That is why the five kept aging.

**A club does not buy a rating, it buys seasons of a rating.** `Career.worth()`
now walks a man forward through the game's own curves — `decline_for` per stat
against its own peak, `retire_chance` compounded year on year — and averages
what he actually gives you over six.

```
  49 maxed, age 35   ->  worth 26      (was 49)
  42 -> 52, age 23   ->  worth 50
  38 -> 50, age 20   ->  worth 48
  49 maxed, age 28   ->  worth 48      (still good: he has the seasons)
```

## 4. Potential was a wall a career hit at twenty-five

`probe_growth` walks one fighter through twelve seasons of regular fighting.
Before:

```
 season   age  rating ceiling  levels
      5    25      46      51       4
      8    28      47      51       3
     12    32      47      51       3
```

He reached his rolled ceiling and then **sat there, unchanged, for seven years
while still earning three levels a season.** A number somebody wrote on him at
nineteen was the end of his career, and no amount of money could move it.

Three changes:

- **A level pays by how far he has left to go.** One stat point is about +0.23
  of a rating; at four or five levels a season that is a man improving barely a
  point a year. `gain_for` now pays up to five points on a wide gap and one at
  the ceiling — self-limiting, and worth nothing to the veteran a flat rate
  helped most.
- **A ceiling moves.** A scout's guess about a nineteen-year-old is a guess, and
  the sport corrects it: a man who has caught his own projection and is still
  fighting gains ceiling every winter, free, bounded by the room his **age**
  still has. Fifteen points at twenty-two, six at thirty, nothing at thirty-five.
- **Paid training raises the ceiling instead of the rating** — the item still
  owed from `FIGHTER-TIERS-15-SEP.md`. The old paid level did the same job a
  fought level does, and the fought one is free: *a purchase that duplicates
  something the game gives away has no argument for itself at any price.*
  Buying ceiling is the thing a shelf cannot sell you in any division.

After:

```
 season   age  rating ceiling
      5    25      55      63
      8    28      62      67
     12    32      67      71
```

40 → 67 over a career, decelerating with age, and it stops because he runs out
of ceiling rather than because the calendar shut a door.

## 5. The XP bar was set against a number nobody had measured

`LEVEL_XP` was 8, so the bar reads 8 / 16 / 24 / 32. A man banks about eleven XP
an event and fights seven of them — **two and a bit levels a season.** Everything
downstream was tuned as though he took four or five. At five the bar reads
5 / 10 / 15 / 20 and the rest of the development economy is fed what it was
built for.

---

## Where it lands

Twenty seasons, five seeds, two managers — the obvious moves, and one playing
for the ceiling:

```
             season 1   season 10   season 20      was
competent       36.8        44.4         ~52      34.2
for the ceiling 36.8        47.8        56.4+     34.2
top division     0.0         0.8         1.4       0.2
```

The club now climbs about **1 point a season and accelerating** (the youth
manager gains +0.8/season early and +2/season late), against **0.0 this
morning**. It reaches the State League reliably and is pushing at Regional by
season 20.

**That is a real curve where there was a flat line, and it is not yet ten
seasons to the top.** Honest accounting of the remaining gap:

- Club power is the mean of five starters, so the club can only climb as fast as
  five men climb. One man now climbs ~2.2/season at his best; the target needs
  closer to 6.
- The five still average 29-30 even for the youth manager, because `best_line()`
  picks by **current rating** — correct for winning this weekend, wrong for
  building. A young man develops on the bench now, but by the time he out-rates
  the veteran he is 28.
- The manager still banks 60-90 credits a season. There is more money in this
  economy than there are things worth buying with it.

The next lever is one of those three, and it is a design call rather than a bug:
whether the game should let a manager **field young men without being punished
for it** — a youth slot, a development XP bonus for starting under-23s, or
simply accepting that the climb is 15 seasons for a good player and 20 for an
average one.

---

## One cost worth knowing about

`test_melee.gd` went from **8m20s to 21m19s**, and the suite's 900s cap silently
timed it out on the first clean run after these changes. Nothing about the melee
changed — `LEVEL_XP` did. A shorter bar fills far more often and `gain_for` now
spends up to five stat points on each level instead of one, so every one of the
file's 40-bouts-a-measure does more work.

The cap is now 2400s and it is a stopwatch reading rather than a guess with
headroom bolted on. *A cap that is not measured is a cap that will silently drop
this test again the next time the economy moves.*

---

## Reverted along the way, and worth recording

Two changes were made, measured, and taken back out — both plausible, neither
what fixed anything:

- **Letting a peaked stat grow.** It broke `test_career`'s rule that *a veteran
  holds but never reverses*, which is the one thing the aging layer must never
  allow. The stall it was aimed at turned out to be the ceiling, not the peaks.
- **Moving `PEAK_GAS` from 24 to 27.** Narrowed the old-fighter spread from 20
  points to 19 and failed the check that a veteran looks like a veteran. Same
  story: it was not what was wrong.

Both were reverted rather than having their tests relaxed.
