# Selling him on

15 Sep 2026 · Retro Bowl's answer, ported

> *"Alright, let's go with Retro Bowl's answer."*

The thread `THE-TIER-PIPELINE-15-SEP.md` left open: `Season.release()` paid
nothing, so a promoted club's outclassed men were dead weight it could drop but
not liquidate — and the churn had to be funded out of a bank that had just met
doubled dues and doubled fees.

---

## Theirs, checked rather than remembered

| | |
|---|---|
| What you get | a **future draft pick** |
| How it's valued | *"according to their star ranking and attributes"* |
| The tiers | **three**, and only three |
| under 2★ | a 3rd-round pick |
| 2★ to 4★ | a 2nd-round pick |
| 4★ and above | a 1st-round pick |

The buckets are wide enough that a **3.9★ and a 2.0★ fetch the same thing.**
That is the whole arbitrage: you learn where the edges sit, you sell the man at
the *bottom* of a bucket and you keep the one at the top.

**Two things change in translation and neither is a choice.** We have no draft —
`Market.pool` argues that at length; buhurt clubs don't have one — so the return
is credits, the only currency a club here has. And our star system is
`BAND_NAME`, six buckets rather than their five-and-a-half stars, so the three
tiers are made by **collapsing it in pairs** rather than by inventing a second
scale. A player already reads those bands when he buys; a separate scale for
selling would be a second thing to learn that says nearly the same thing.

```
                          fee   sells
Backyard   Journeyman       1       0
           Steady           3       0
           Good             6       3
           Strong          11       3
           Star            18       8
           Marquee         42       8

National   Journeyman       4       2
           Steady          12       2
           Good            25      11
           Strong          46      11
           Star            74      33
           Marquee        174      33
```

A Strong man costs 11 to sign and fetches the same 3 as a Good man who cost 6.
Read the edges, sell the bottom of a bucket.

**Age is in there already and that is why it is not a term.** A fighter's band is
read off his *current* rating, and a rating falls as he ages — so the man you
should have sold two seasons ago is in a lower bucket now and fetches less,
without a line of code about age. Retro Bowl gets the same behaviour the same
way: their value is by stars, and stars fall.

**Nothing for a man out of contract.** His deal has run out and he can walk to
whoever he likes in the summer, so nobody is paying you for the privilege. That
is the sharp end of the re-sign/extend fork the contracts layer already had: let
a good man run down and you lose his fee as well as him.

**One door, not two.** Retro Bowl separates cutting from trading; that split only
exists because a trade needs a partner who wants him, and ours is a league of
clubs who always do. A man nobody wants is worth the bottom bucket, which at the
Backyard Circuit is nothing — so "worthless" is a price rather than a second
button doing nearly the same job.

---

## Two printers, caught by walking every rating

**The first cut read the top band of each pair** and paid **19 credits for a man
whose fee was 18** — buy a Star, sell him the same afternoon, bank a credit. The
top of that pair is Marquee, and a Marquee costs 42.

**The second cut fixed the top bucket and left the bottom one tied**, because
`fee` floors at one credit and so did the sale. Buy for 1, sell for 1, forever.

Neither was visible from any single example. Both were obvious the moment every
rating in the game was walked. The sale is now capped at `fee - 1` **by
construction** rather than by tuning, and `test_market` walks all four divisions
at every rating 1–99 and asserts the margin:

```
across every rating in every division the closest a sale comes to its own
fee is 1 CC (a 1 in the Backyard Circuit)
12 sale buckets across the four divisions, all flat, and a dearer man
fetching the same as a cheaper one: yes
```

*A rule that holds because two numbers happen to land the right way round is a
rule waiting for one of them to move* — and both of those are tuning figures that
will move.

---

## A layout bug the screenshot found

`shots/sell.png` is the first thing that has ever rendered the squad tab **with a
fighter picked**. Picking one adds three buttons to a row that already had three,
and two of them landed on top of two that were already there:

- `Sell` exactly over `Reserve by` at x=24
- the contract fork over `Free agents` at x=544

So **the reserve could not be re-sorted while a man was selected**, and the only
visible symptom was a single letter `s` sticking out from under the Extend
button. `Sell` is added later so it won the tap and drew on top, which is what
hid it.

`test_layout.gd` measures controls against controls and would have caught this on
sight. It drives every **tab** and had never driven this **state** — a control
that is never built cannot be measured. It now builds it, and the check was
verified by putting the bug back: red with it, green without.

**Driving a tab is not driving a screen.**

---

## What it did to a career

Almost nothing, and that is the right answer:

```
season  power  leader  tier    CC        without the sale
    19   55.6    59.8   1.2  71.0        55.8 / 1.4 / 71.2
```

The manager was never cash-constrained — it banks seventy credits a season — so
being able to liquidate a man it had already decided to drop changes little for
it. **The sale is a player-facing seam rather than a balance lever**, and the
number that matters is the one that did *not* move: credits in hand are flat at
71, so this added a way to convert an asset without adding an income stream to an
economy that already has a surplus.

That surplus is still the open question.
