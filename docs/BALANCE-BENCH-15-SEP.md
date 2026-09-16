# The balance bench

15 Sep 2026 · `tools/sweep.sh`, `tools/tune.py`, `tools/career_score.gd`

> *"We should be gathering all the possible variables of this including every
> price and I want to find some balancing. If we want to use a LOT of tests,
> that's fine. Each variable deserves its own test... Target is a 10 season
> Championship for the average player."*

Charts: **Balance Bench** (published artifact).

---

## The toolbox

Five pieces, because Pete asked for *"a reusable toolbox to pull from rather than
ad-hoc effort each round"* and because a balance pass that has to be rebuilt each
time is a balance pass nobody runs twice.

| | |
|---|---|
| `tools/manager.gd` | **One manager, shared.** The policy was living in three probes as three drifting copies — and that matters more than usual here, because sweeps compare runs against each other. *Two probes with slightly different managers do not produce comparable numbers, they produce an argument.* |
| `tools/career_score.gd` | A whole career to one line in **about two seconds**. That number is what makes brute force affordable at all. |
| `tools/sweep_plan.py` | Reads the same `const` declarations the game compiles, so a tunable cannot be in the code and missing from the sweep. |
| `tools/sweep.sh` | Moves one constant, scores, puts it back — on a **copy** under `/tmp`, so the real tree is never touched and a crash cannot leave a constant somewhere nobody intended. |
| `tools/noise.sh` | The same game on eight different worlds. |

---

## The control, which came first

Every number a sweep prints is one sample of a stochastic career. Before reading
any of them:

**Eight worlds, the game unchanged.** First promotion lands anywhere from season
**5.8 to 25.6**; the division a club sits in at season 14 ranges 0.40 to 1.60.
That is the spread between worlds, and it is enormous.

**Five values of an inert constant, same world.** Byte-identical, all five.

Those two together are the licence to read the rest. A run is a **pure function
of its settings and its seeds**, so the sweep is paired — every movement is a real
consequence of the variable, not a lucky world. Unpaired, almost nothing here
would have meant anything, and it would have looked exactly the same.

---

## What 548 sweeps found

**115 tunables, five points each, half to double.**

- **43 of them move a career by nothing at all.** Not necessarily wrong — several
  govern the fight rather than the climb — but not one of them is a balance lever,
  and a few are prices a player will agonise over.
- **41 move it measurably.**
- **One dominates everything.** `LEVEL_XP` — the length of the XP bar — is the
  only value in all 548 that got any career to the National Division. At 2 it
  reaches division 2.20 against a baseline of 0.40.

The baseline is worth stating plainly: **the average player gets one promotion in
fourteen seasons** and never sees the third division.

---

## Two objectives that were wrong, and why

**"Minimise seasons to a title"** put every development lever at the top of its
range. Of course it did — that objective is optimised by a game you win
immediately, and nothing in it knows a career can be too fast. The target is a
ten-season championship, not the fewest possible seasons, so the objective became
**distance from ten**.

**"Never" encoded as 99** made the mean over five careers read 81.0 when one wins
in season nine and 81.2 when it wins in ten — so one career moving a single season
outranked two others ceasing to reach the top division at all, and the search took
that trade on its first pass. *A "never" encoded as a big number does not mean
never; it means a number so large it drowns everything measured beside it.* It is
now one season past the window, which says what was actually observed.

A third correction was structural rather than numeric: the first target-seeking
run **did not move at all**, because |title − 10| is flat across every setting
that never wins one. A coordinate search standing on a plateau finds no single
move that helps and stops. The score now carries a small tail term — a hundredth
of the season the club first reached the top division — so there is a slope
everywhere the search might stand.

---

## Where it lands, and why it is not shipped

A coordinate search over the ten strongest levers, aimed at season 10, converged at
**season 12.0**:

```
lever                ships   search wanted   at the edge?
LEVEL_XP                 5               1   yes
POTENTIAL_GAP_MAX       18              32   yes
CEILING_DRIFT            4              10   yes
GAIN_PER_GAP             3               2   yes
GAIN_MAX                 5               9   yes
XP_SIMMED                8              24   yes
DECLINE_RATE          0.30            0.15   yes
```

**Every single moved lever is pegged at the boundary of its range, and it is still
two seasons short.** An optimum sitting on every edge is not a balance point, it
is a corner — and the honest reading is that the search has run out of the thing
it was allowed to move.

The diagnosis is in the two numbers underneath. At that corner the club reaches
the National Division at **season 9.2** and then needs **2.8 more seasons to win
it**. Development gets you there almost on time; it does nothing at all about the
last step.

So the remaining two seasons are not in development. They are in the ladder — the
division power bands, how many clubs go up, the sixteen-club top flight a club
must finish first in — and those were deliberately excluded from this sweep as
structural. That exclusion is now the finding rather than an assumption.

**Nothing in this pass changes a game constant.** Shipping a corner because a
search walked to it would be balancing by optimiser, and the optimiser has just
told us, by sitting on every boundary at once, that it was asked the wrong
question.


---

# Part 2 — the target, sharpened

> *"The balance we're looking for is promotion out of backyard by season 2, and
> championship win by season 10-12."*

Two requirements and a **band**, and the band is the important part. Aiming at a
single number is what made the first search peg every lever; anything inside 10
to 12 now scores a hit, so a setting that wins in season eight is worse than one
that wins in eleven. `tools/tune.py` scores them summed rather than ranked — a
setting that nails the title and leaves the first promotion at season six has not
done the job.

## The first promotion is one number

`START_POWER` — the rating of the club you inherit — was a bare `38` in the middle
of a constructor call, which is a tunable no instrument can see. Named, and swept:

```
START_POWER   38     41     44     47     50
first promo   6.0    ~4     ~3    2.4    2.2
```

**Promotion out of the Backyard Circuit by season 2 is a statement about the
distance between the club you inherit and the club leading the division you
inherit it in**, and nothing else moves it nearly as much. At 44 the club starts
near the top of a 30–46 band — a good Backyard side ready to move up, which is
what "you are passing through here" should feel like.

## The wall is the middle of the ladder, not the top

With a strong start and moderate development settings, seasons to each rung:

```
Backyard Circuit    2.6
State League        7.2      <- seven seasons
Regional League    10.0      <- ten seasons
```

The National Division was never the problem. **State and Regional are**, and the
shape the target implies — roughly two seasons a division, six to arrive and four
to win — needs those two rungs cut by a factor of four.

## The obvious lever is barred, and the game says why

Promoting three from State and Regional instead of two:

```
                  before    after
National at        19.8      never
club power         67.0      46.4
final division     3.00      1.20
```

Catastrophically worse — and the cause is a rule this codebase already wrote
down. `League.TIERS` carries `up` and `down` per rung with a comment that says
*"a ladder where one rung has different arithmetic from the others is a rung that
will silently leak or gain a club."* Moving `up` without moving the division
above's `down` does exactly that: divisions change size, the schedule and tables
malform, and the collapse in club power is the symptom.

**The measurement caught it, and the measurement is the only reason it was
caught** — the run does not error, it just quietly produces a worse game. Any
future pass at the promotion slots has to move `up` and the neighbouring `down`
together, as a pair.

## Still not shipped

The same reasoning as Part 1. The search has a good diagnosis and has not
converged: coordinate descent keeps plateauing because these levers need to move
**together**, and warm-starting it from a known-good region did not rescue that.
What is now known and worth carrying forward:

- the first promotion is `START_POWER`, and 44 looks right
- the title is gated by State and Regional, not National
- promotion slots must move in `up`/`down` pairs or the pyramid leaks
- `NAT_CLUBS` 16 → 12 and the National ceiling 86 → 78 both help and are safe

The next pass wants a search that moves several levers at once over those four,
rather than one at a time.
