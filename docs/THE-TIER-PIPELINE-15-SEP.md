# The tier is the pipeline

15 Sep 2026 · `tools/probe_growth.gd` Part E

> *"No to the youth slot. Alright so we can go with a 'team training' CC sink...
> Team coach with a static training exp gain plus game exp gain doesn't work?
> Then the age should already be an under-23 or so boost anyway. What more boost
> would they need to eventually catch up the old men and become starters if
> they're a higher tier? Like, the same tier pipeline shouldn't matter much in
> the same tier, but training a new guy from a higher tier should surpass the
> older lower tier guy."*

The question deserved a measurement before anything else got built, so it got
one. **You were right, and one piece of it was missing.**

---

## The measurement

A twenty-two-year-old signing against the thirty-year-old he is behind — a
finished man at the top of the Backyard band. The signing sits in the **reserve
the whole time** and the incumbent starts every week, which is the hard version
of the question.

```
                                         starts   ends   passes him
a 22-year-old from his own division         39      40      never
   the 30-year-old he is behind             45      42

a 22-year-old raw, but reared one up        40      40      never
   the 30-year-old he is behind             45      42

a 22-year-old from the one above            49      49    season 1
   the 30-year-old he is behind             45      42
```

...and the same four rows with a four-star captain teaching his role:

```
a 22-year-old from his own division         39      52    season 7
a 22-year-old raw, but reared one up        40      53    season 6
a 22-year-old from the one above            49      63    season 1
```

Read the first column against the third and the whole design is in it:

- **Same tier barely matters.** Seven seasons with the best coaching in the game,
  and *never* without it. Exactly the weight you asked for.
- **A tier above surpasses him at once** — season one, with no captain at all —
  because he arrives better and then keeps climbing.
- **Coaching is the thing that turns a prospect into a starter.** The same man is
  worth 40 or 52 after ten seasons depending only on who was teaching him.

So: no youth slot, no extra under-23 boost. The tier gap already does the work,
and the practice week is what lets it.

---

## The piece that was missing

Look at the middle row. **A raw man reared one division up was identical to a
local boy** — never passed him without coaching, and beat him by a single season
with it.

`Career.roll_potential` read `potential_room(age)` **and nothing else**. Two
twenty-two-year-olds rated 39 had the same prospects whether one of them had
spent his career training against National fighters or against a back field. So
the rare case the market exists to create — the cheap man from up the pyramid
whose rating is low and whose ceiling is not — was not a thing that could happen.

It now reads the standard he was reared against: the top of the band he was
**drawn from**, not the one he is being sold into.

```gdscript
if standard > f.overall():
    bonus = min(STANDARD_ROOM, (standard - overall) / 2) × room / POTENTIAL_GAP_MAX
```

Two details carry it:

**It is added after the roll, not into its range.** Widening the range leaves the
draw uniform, so a raw man reared a division up would be better only *on average*
and any one of them could still roll a nothing ceiling. The first cut did exactly
that and produced season 6 against season 7 — noise wearing a rule's clothes.
*Evidence shifts an estimate; it does not merely widen it.*

**It fades with age on the same curve the room does.** A thirty-four-year-old
rated 40 off a National shelf is a journeyman who was in the building, not a
prospect, and handing him nine points of ceiling he has no years left to reach
would make "reared up the pyramid" a laundering trick for old men.

After:

```
a 22-year-old raw, but reared one up, no captain    40 -> 43    season 10
a 22-year-old raw, but reared one up, 4-star        40 -> 58     season 3
```

Season 3 and a finish of 58, against the local boy's season 7 and 52. That is the
sentence — *training a new guy from a higher tier should surpass the older lower
tier guy* — with numbers under it.

---

## Team training

A club-wide credits sink, because there was more money in this economy than
things worth buying with it: `probe_pace` had clubs ending every season with
sixty to ninety unspent credits. The captains are hired once and the ground is
built once; neither absorbs a surplus that arrives every week.

- **Price is a share of the division's slack**, like the signing fee, so it means
  the same thing at every rung: **2 / 4 / 4 / 8 CC** against a season's 16 / 33 /
  37 / 67.
- **One a matchday**, the throttle every building here already follows, so a
  windfall cannot buy a career.
- It runs `_practice()` immediately rather than banking a promise in
  `built_this_week` — that dictionary is not saved, so a player who paid on
  Tuesday and closed the game would have bought nothing. *Paying for a thing and
  having it happen is one step or it is a bug.*
- It lives on **the Staff screen**, not the Clubhouse. What it buys is a week's
  work at the grade of whoever teaches each role, so its worth is decided
  entirely by the two cards above it — and the Clubhouse was already the tab you
  called too crowded.

### What it did

```
season  power  leader  tier          before  
     1   36.6    45.0   0.0           36.6   
    10   40.2    48.0   0.2           41.2   
    19   52.8    62.2   1.4           46.8   
```

The competent manager finishes on **52.8 and pushing at the third division**,
against 46.8 without the sink. Mean starting-five age is drifting down for the
first time, and the finish column reaches 0.17 and 0.40 in the late seasons.

Still ending seasons with ~68 credits in hand, so the sink absorbs real money and
has not solved the surplus. That is the next thing to look at, not this one.
