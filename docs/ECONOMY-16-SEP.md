# Where the money comes from — 16 Sep 2026

Pete, 16 Sep 2026:

> The income is either too low or costs are too high. 84 in one year will not
> maintain enough, you'll decline.

This is what the instruments say, what was changed, and the one decision left
on the table.

---

## The two probes disagreed, and both were right

`tools/probe_economy.gd` has said since it was written that the economy is
generous: a Backyard club nets 56–69 CC a season against a 6-credit Club gym,
so the next ground is **a tenth of a season away**.

That is a true sentence about the arena ladder and a misleading one about the
economy, because the arena ladder is 138 credits across a whole career and it
is not where a club's money goes. **A probe that measures one sink and calls
the economy generous is measuring the sink, not the economy.**

Nothing in the project could total the others, because money left the club in
**twenty-three separate `credits -= x` statements** and said nothing on the way
out. `take()` had named every credit *in* since the purse ledger went in; there
was no matching door for credits going the other way. **A ledger with one side
is a ledger.**

So `ClubOffice.spend(cc, line)` now exists, all twenty-three sites call it, and
the club keeps books by heading for the year in hand and the year before it.
Two things read them: the new FINANCES tab, and `tools/probe_afford.gd`.

---

## What the books say

`tools/probe_afford.gd` — eight years, back half counted, three seeds, league
fixtures only, no tournament:

| division | club | year 1 | income | forced | earned | growth | % left |
|---|---|---|---|---|---|---|---|
| Backyard Circuit | title-winning | 29.7 | 66.7 | 14.5 | ~12 | 52.2 | 78% |
| Backyard Circuit | mid-table | 22.7 | 62.2 | 14.4 | ~12 | 47.4 | 76% |
| State League | mid-table | 26.7 | 66.5 | 26.8 | ~12 | 39.4 | 59% |
| Regional League | mid-table | 42.0 | 77.1 | 40.3 | ~12 | 36.3 | 47% |
| National Division | mid-table | 52.0 | 97.0 | 62.7 | ~10 | 34.2 | 35% |

- **FORCED** — upkeep, keeping every harness above the inspection line, keeping
  the ground out of the state that costs you gate.
- **EARNED** — the level-ups the men actually worked for. It reads near zero in
  that table and that is the fixture, not a finding: `_standard()` manufactures
  rating by pushing raw stats, so those men never bank XP. Measured on a squad
  that develops naturally it is about 12 CC a season in the Backyard Circuit.

**At the steady state the economy is fine.** A third to three quarters of
income is free for growth at every rung.

## The first seasons are not fine, and that is the complaint

`tools/probe_year1.gd` — a Backyard club's books, five seeds, line by line:

| line | S1 | S2 | S3 | S4 | S5 |
|---|---|---|---|---|---|
| Prize money | 6.4 | 5.8 | 5.4 | 7.2 | 2.2 |
| **The gate** | **1.4** | **1.6** | **1.6** | **1.6** | **1.8** |
| The ground (retainer) | 2.0 | 2.0 | 2.0 | 2.0 | 2.0 |
| **Members' dues** | **8.0** | **14.0** | **14.8** | **15.4** | **19.2** |
| IN | 17.8 | 23.4 | 23.8 | 26.2 | 25.2 |
| maintenance + levels | 15.8 | 18.2 | 18.2 | 18.2 | 15.6 |
| **LEFT FOR GROWTH** | **2.0** | **5.2** | **5.6** | **8.0** | **9.6** |

Two credits of growth in season one, five in season two, against a Club gym at
6 and a cap raise at 4. That is not a difficulty curve, it is a club standing
still — Pete's word for it was *decline*, and he was describing this table.

And the reason is one line of it:

> **The gate pays 1.4 CC a season.** Members' subs pay 8 to 19.

The whole crowd apparatus — notoriety, bands, turnout percentages, the fan
meter, five screens' worth of it — is worth under two credits a year in the
division a new player spends his first hours in. **The thing the player does is
not the thing that pays him.** His money comes from people paying to belong to
the club.

Two causes, both structural:

1. `Venue.pays_the_gate` means only HOME fixtures pay, and `tools/probe_venue.gd`
   measured the real calendar at **home 33%, away 37%, neutral 30%** — the cup
   ties are neutral ground. A five-event Backyard season has about 1.7 home
   fights.
2. `CROWD_PAY` is a flat `[1, 2, 3, 4, 5, 6]` by notoriety band and **does not
   read the ground at all**. The comment over `gate_income()` says "the events
   are where the arena earns"; the code disagrees with it.

---

## What was changed (both defensible on their own, both measured)

**1. The division purse.** `CREDITS_BY_POSITION := [6, 4, 2]` paid the top
three and nothing else — so from the State League up, most of the field earns
no prize money in any year, and winning the National Division paid the same six
credits as winning the Backyard Circuit against four times the upkeep. It is
now `Season.purse(place, field, tier)`: a pot that grows with the division,
shared down a straight line from the champions to the wooden spoon. Backyard
pays 6 down to 1; National pays 16 down to 3. Worth about +1.6 CC a season to a
Backyard club and considerably more higher up.

**2. The armorer refuses work not worth doing.** `Quartermaster.topped_out()`
used a tolerance of 0.001 — any scratch at all — while `kit_cost()` has a floor
of one credit. Across thirteen men that is a standing charge for polishing
things that did not need polishing. The tolerance is now `WORTH_DOING = 0.08`,
about one hard week, and below it the armorer says come back when there is
something to do. The arena already had this rule in as many words: *a ground
already spotless is refused rather than billed.*

Neither change touches the late game.

---

## The decision that is Pete's

The gate is the problem and fixing it is a shape change, not a number change.
Two options, and they are not exclusive:

**A. The gate reads the ground.** `crowd_pay()` becomes band × a factor from
arena capacity, so building a Sports hall visibly changes what a fight pays.
This is what the code's own comments already claim happens. It makes the arena
the engine of the economy and it makes the early game harder, because a back
field stays worth a credit.

**B. The gate is paid at every fixture, scaled by venue.** Home pays full, away
pays a share, neutral pays a share — instead of away and neutral paying
nothing. Roughly triples early gate income without touching any constant's
magnitude, and keeps "build a ground" worth doing through the retainer and the
home multiplier. This contradicts the 14 Sep rule (*"the gate is only yours at
home"*), which is why it needs Pete rather than me.

My read: **B first, then A.** B fixes the felt problem — fighting should pay —
without inflating the top, and it is one function. A is the better long-term
shape but it widens the gap between a new club and an established one, which is
the wrong direction for the complaint that started this.

Parked until Pete says which.
