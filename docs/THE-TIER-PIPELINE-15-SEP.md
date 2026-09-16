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


---

## Postscript: the summer after a promotion

> *"When the team raises up a tier, so does the tier of fighters in the free
> agency. So if they're holding onto Tier one fighters, they're wrong."*

**The mechanism is already live.** `Season.market()` reads
`world.player_tier()` every time it is called, so the shelf, the fee bands and
the standard a man was reared against all move up the day a club is promoted.
Nothing had to be built.

**The manager was not using it.** `probe_pace` caught it plainly: at the
promotion in season 18 the club's signings **fell to 0.8** while its bank climbed
to 68 credits. It went shopping *less* in the one summer it should have gone
most.

Two things make an ordinary summer wrong there, and both are self-inflicted:

- **The reserve is sized off the dues**, which just doubled — so the manager
  holds back more money at the moment money is worth least.
- **The bar for a signing is "better than my weakest starter"**, which is a bar
  set by the division he has just *left*. In this one summer the question is not
  whether a man beats the worst of last year's team; it is whether he can hold a
  place in the company the club has joined. The bar is the new division's floor.

```
season  power  leader   mid  signed   age  under      before
     7   40.8    49.8  47.0     0.2  30.6    1.0     40.8 / 0.2
    15   48.6    58.8  50.2     2.8  28.4    0.0     46.0 / 3.0
    19   55.8    63.0  55.8     1.0  30.4    0.2     52.8 / 0.8
```

`under` is men **on the line** rating below their own division's floor. It falls
to zero from season 11 on.

The club now finishes on **55.8 against 52.8**, reaches the second division by
**season 15 rather than 19**, and — the line that matters most — its rating sits
exactly on its division's median (55.8 against 55.8) instead of in the bottom
half. A median club is one good summer from a promotion place. A bottom-half one
is not.

### The thread this leaves open

`Season.release()` pays **nothing**. So a promoted club's outclassed men are dead
weight it can drop but cannot liquidate, and the churn Pete is describing has to
be funded entirely out of a bank that just met doubled dues and doubled fees.

Retro Bowl has the other half: trade value, in three coarse tiers, which the
teardown called *"a beloved arbitrage"*. A man you should have sold two years ago
being worth less than the man you should sell now is the sentence that makes
"holding tier-one fighters is wrong" cost something rather than merely being true.

Not built — it adds an income stream to an economy that is already ending seasons
with seventy unspent credits, and that surplus should be understood before
anything else pours into it.
