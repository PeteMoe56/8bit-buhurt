# The practice week

15 Sep 2026 · `tools/probe_growth.gd`

> *"The Coaches hold practices, the better the coaches, the more you get out of
> practice. Benched guys get more out of practices, but the fighters get a little
> practice and the fight XP... Let's not give them a lot, but if you stick with
> the same guys, everyone gets a raise and they all hit their individual peaks.
> Also, make sure these guys have varying peaks on them."*

---

## What Retro Bowl actually does, since it was worth checking first

Their whole development system is one chain, and there is no practice in it:

| | |
|---|---|
| **Training Facility** | *"Improving training facilities means players gain XP faster."* 10 levels, decays. A **rate**, not a switch. |
| **Training regime** | Light ×0.6 / Normal ×1.0 / Hard ×1.5 on XP — and Hard is **five times** the injury odds, not fifty per cent more |
| **`Likeable`** | a coordinator trait: flat **+5% XP a game** |
| **`Experience`** | one-shot: an immediate level-up to everyone in his unit |
| **`Talent Spotter`** | one-shot: raises **potential** |
| XP itself | comes from **production** — a better player gains more yards, so he levels faster |
| Their tiers | four attributes 1–10, overall 0.5–5.0 **stars**; potential is a second star rating |

Two things to take and one to leave.

**Take: development is a rate the staff sets.** Every multiplier they have is a
club decision — the facility you built, the regime you picked, the coordinator
you hired. None of it is a reward for the men who played.

**Take: the variation is in the spread, not the total.** Two 3-star players have
different attribute splits, and the position weighting decides which split is
worth having. Their tiers are coarse on purpose.

**Leave: they have no bench to develop.** Ten star players against 23 slots, and
every unfilled slot is a "noname" with the worst possible stats. A pipeline is
not a thing their design has to solve. Ours carries thirteen men and eight
travel, so it is the whole question.

---

## 1. The practice

`_practice()` runs on every matchday, for every man on the books, and it is the
only place a club's development spending lands:

```
practice = (2.0 + 2.6 × captain's stars for his role) × starter share
         × the training ground × the regime × the doubled specialty × his traits
```

- **The bench gets four times what a starter gets.** A starter spends his week
  recovering and his Saturday fighting; a reserve spends the week in the hall
  with the captain. `PRACTICE_STARTER` is 0.25.
- **The floor is nearly nothing.** A club with nobody teaching gets 2.0 a week,
  which is a rounding error. *A club with no coaching develops nobody* — and
  that sentence is what makes the grade on a hire card worth paying for.
- **`ClubOffice.coaching()` is new and it is the point.** `taught()` has answered
  this question as a **bool** since captains were written, so a one-star and a
  five-star taught a role identically and the stars a player paid for reached
  nothing except how many roles the man covered.
- The **training ground** now does two jobs — its winter lump, and +10% a level
  on every practice, which is Retro Bowl's facility in our nouns.

This replaces an earlier patch that paid the bench a **share of the starters'
fight XP**. That fixed the arithmetic and said something untrue: that a man who
did not play is paid a fraction of an afternoon he did not have.

### Is the pipeline real?

A 21-year-old, twelve seasons, no other multipliers — so the captain is the only
thing moving between rows:

```
                                    rating   ceiling   levels
on the line, no captain                 73        81       66
in the reserve, no captain              42        55        7
on the line, a 3-star captain           73        81       68
in the reserve, a 3-star captain        56        62       31
on the line, a 5-star captain           73        82       71
in the reserve, a 5-star captain        62        67       46
```

A reserve under the best captain in the game reaches **62 against a starter's
73** — close enough that a young man kept four or five seasons arrives able to
play, never close enough that sitting him beats playing him. Under no captain he
reaches 42 and is worthless. That spread is the mechanic.

*(First cut had `PRACTICE_PER_GRADE` at 1.4 and the best captain got a reserve to
53 against 73. A pipeline that produces fighters twenty points short is not a
pipeline, it is a waiting room.)*

---

## 2. Everyone gets a raise

The same thirteen men, six seasons, two four-star captains, nobody signed and
nobody dropped — each man at **his best**, not on the final whistle:

```
fighter      age     was    best   ceiling    year got there
Calder        31      39      51        56       6       no
Wren          37      39      40        42       2      yes
Nolan         32      38      51        54       6      yes
Merrick       38      38      38        38       0      yes
Dain          31      30      38        43       6       no
Tarrow        32      20      27        32       5       no
Dunn          28      22      36        41       6       no
Norrey        31      24      33        38       6       no
```

**Every man got a raise** except the two who were already at their ceiling on day
one, and both of those are veterans. Five of thirteen reached their own peak
inside six seasons; the rest are still climbing — their best year is season 5 or
6, meaning they were still rising when the probe stopped.

*The first cut of this ran twelve seasons and read the squad on the final
whistle. It came back with Merrick on 20 and Orr on 7 and reported the claim
false. Nobody retires or is replaced in this fixture, so twelve seasons turns
thirteen men into a squad aged 34 to 47 — and asking whether a forty-seven year
old is at his ceiling is the wrong question about a man who passed it six years
ago.*

---

## 3. Every fighter has his own curve now

Peaks were sport-wide constants — gas 24, strength 28, base 32, skill 35, for
everyone, forever — moved only by two traits, and those moved the whole set. A
twenty-four-year-old was a twenty-four-year-old and a scouting report could only
say what his birthday said.

`FighterCard.peak_seed` is one integer per man; `Career.peak_offset` draws each
stat's offset from it, ±4 years. The starting squad:

```
fighter         gas strength     base    skill
Calder           23       28       27       30
Dain             24       31       36       39
Mear             27       26       36       39
Keld             20       32       36       35
```

Calder is finished early everywhere; Dain and Mear are late bloomers; Keld's gas
goes at twenty but his base holds to thirty-six. Thirteen distinct arcs.

The order mostly survives and sometimes does not, which is worth saying plainly
rather than claiming otherwise: the sport's peaks sit three or four years apart,
so an unusual man's base arrives after his skill. That reads as a fighter whose
hands came good before his footing, which is a real thing. A spread wide enough
to put gas after skill would be noise, not variation.

**Zero means the sport's own schedule**, which is what a fighter out of an older
save actually has — so the save default decodes into something true rather than a
placeholder.

---

## Three bugs this turned up

**`decline_for_man` had no caller.** Its own comment says *"the same figure for a
particular man, **which is the one the winter uses**"* — and the winter called
`decline_for`, the sport-wide one, since the day both were written. So a Late
Peak fighter was refused training on a stat he was past by his own schedule and
declined on it by everybody else's: the worst of both, exactly backwards. *A
comment that says where a function is called is not a check that it is.*

**A man under his ceiling with nothing left to grow banked XP forever.**
`_raise_one` only grows a stat a man is not past, so past all four peaks it
returned "nothing to grow" **without spending the bar**, while `can_level` went
on saying yes — an infinite loop that hung the probe. The fix took two attempts
and where it goes is the whole point: inside `_raise_one` it broke the rule that
*a veteran holds but never reverses*, because the winter would then hand a
forty-year-old points that lifted him above where the season started. But
`_raise_one` serves two callers with different rules, and Pete settled the other
one on 13 Sep: *"leave the ability to gain all stats still. He's just slower at
leveling."* So `level_up` now falls back to his lowest stat with room, and the
**winter** keeps refusing. Two rules, two places, neither pretending to be the
other.

**A hash is not a random number until it has been mixed.** The first peak draw
was `hash("peak:%d:%d") % 9`, and the starting squad came back with four
fighters carrying an identical 22/32/28/32 and three more sharing 26/27/32/36.
Low bits of a string hash on near-identical inputs are not independent, and a
modulo reads only the low bits. `LeagueWorld._hash2` exists for exactly this and
says so in its own header.

---

## A correction, recorded rather than quietly dropped

`docs/THE-CLIMB-15-SEP.md` reports, and Pete was told, that `test_melee` went
from 8m20s to **21m19s** because the shorter XP bar fires more level-ups, and the
suite's 900s cap was raised to 2400s to match.

**That was wrong and the cap has been put back.** The stopwatch reading was real.
The machine was not idle: four runaway `probe_growth` processes, left spinning by
the infinite loop described above, were still burning CPU hours later, and the
load average was **thirteen**. Killed, the same file runs in **500 seconds** —
8m20s, to the second what it always took.

*A stopwatch reading is not a measurement until you know what else was running.*
`uptime` before timing anything, from here on.

---

## And a balance fact that fell out of fixing a test

`test_office`'s *"facilities reach something"* asserted, in absolutes, that a
maxed training ground and a five-star captain lift the coached men over a winter.
It went red reporting **386 against 386** — because the practice now spends a
squad's headroom during the season, and because peaks vary, so the Rail the check
happened to name turned out to be an early decliner whose strength peaks at
twenty-five.

*An absolute check on one fixture's luck is a check waiting for the fixture to
change.* It now plays two identical clubs on the same seed, one with the ground
and the captain and one with neither, so decline takes the same points off both.
The difference is the facility — and the difference is **2 points across seven
coached men.**

A maxed training ground costs 54 credits and buys two points a season. That is
worth knowing before anybody spends on one, and it is a decision rather than a
bug, so it is written down here rather than quietly tuned.

---

## What it did to a career, and what it did not

```
season  power  leader  tier      (competent manager, five seeds)
     1   36.6    45.0   0.0
    10   40.8    48.6   0.4
    19   46.8    53.2   0.6
```

**Almost nothing** — and the reason is worth more than the number. The probe's
manager keeps a starting five averaging **thirty years old**, because
`best_line()` picks by current rating and `Career.worth` buys for the next six
years. Practice is worth a great deal to a twenty-one-year-old and nearly nothing
to a thirty-year-old who is already at his peak, so the club is paying for two
captains and coaching men who cannot use it. The run with hiring is marginally
*worse* than the run without.

That is not the practice failing. `probe_growth` shows it doing exactly what it
was asked to do. It is the same wall as yesterday, one layer further in: **the
game has no way for a manager to field young men without being punished for it**,
so the system that rewards keeping them has nobody to reward.

That is the next decision, and it is a design call rather than a bug — a youth
slot in the eight, a development bonus for starting an under-23, or accepting
that the pipeline is a thing a human player uses and an AI policy does not.
