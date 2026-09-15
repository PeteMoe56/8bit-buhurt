# Retro Bowl teardown — Part 3: the three open questions (15 Sep 2026)

Parts 1 and 2 are in `docs/RETRO-BOWL-TEARDOWN.html`. This part exists because
the career sims left three calls on the table and Pete's answer was: *"Those are
things to consult Retro Bowl on how it works within their system."*

Sources, in order of trust: the decompile figures already recorded in
`REGISTER.md` (source, not analysis), the Retro Bowl wiki and Rob's front-office
guide for figures the decompile session did not capture, and our own probes for
every number on our side. Where something is an inference it says so.

---

## The one sentence that covers all three

**In Retro Bowl every system terminates in something the player does with his
hands. In ours every system terminates in a number the sim reads.**

- Their level is felt because *you* throw the pass to the receiver you levelled.
- Their fan meter is felt because it changes the credits on the results screen
  after **every single game**.
- Their career is felt because the job-offer list visibly gets longer or shorter.

Ours: a level moves a mean of five men by 0.05. The crowd moved a season-end lump
until yesterday. The pyramid moves once a decade. Every one of the three
questions below is that same gap in a different costume.

---

# Q1 — the yo-yo, and how fast a career should move

## What they do: there is no pyramid at all

One team, one league, forever. **You cannot be fired. There is no relegation and
no loss condition.** Their entire "am I getting anywhere" signal is three things:

| | |
|---|---|
| The championship | winnable in season one, pays **+10 credits** on top of the normal fan credits |
| `coach_rating` | 1–20. **+4** for winning the division, **+8** for winning a cup, and **×0.5** for finishing below fourth |
| Job offers | `s_team_interested`: not your own club, **your rating ≥ the club's rating**, not your boyhood club before season 3, and 1 in 4 never call |

So the club does not climb. **You** do. And the rate is set by a number that is
fast to gain and brutal to lose, read every summer.

Pete already ruled on the structural question — *"I do like our gates due to
Retro Bowl staying in one league, we're promoting/demoting"* — so the pyramid
stays. But two things follow from their design anyway.

## What it means for us

**1. They never ask you to wait years for the next thing.** The trophy cabinet
starts filling in season one. Our pyramid gates the National Division behind
roughly thirty seasons at the default grade, measured. That is not a difficulty
curve, it is a queue — and the fix I shipped (two up from the Backyard Circuit)
halved it without touching the underlying problem, which is that the pyramid is
our *only* long arc.

**We already built their answer and it is switched off in practice.** `Coach`
went in on 12 Sep with the reputation curve and the offer list ported whole
(§44). A player who cannot get promoted for ten seasons can still be climbing the
job ladder in that time — but nothing on the season screen mentions it, so the
one progression that moves every year is invisible while the one that moves every
decade is the whole UI.

**2. Their stadium is a yo-yo damper, and ours is not.** This is the most
directly transferable thing in their build:

> The stadium *"determines the amount of fan support you receive after each win,
> and lose after each loss. With a better stadium, you will gain greater fan
> support with each win, and lose less fan support with each loss."*

The stadium does **not** raise the ceiling. It narrows the swing in both
directions. You spend the currency the meter produces to make the meter less
volatile — and it saturates at the top band, so early upgrades feel enormous and
late ones feel like nothing.

Ours multiplies the gate and nothing else. A promoted club that struggles takes
the full downside of a bad year with no way to have bought insurance against it.

**What I would do:** make `Arena` damp the notoriety swing as well as multiply
the gate — `note_after` scales its losses by the ground. A club that built for
the division it went up into is a club that survives a bad first season in it.
That is a yo-yo damper the player can buy, in their exact shape, and it costs one
function.

**3. And the one rule of theirs I would take verbatim:** their Dynamic difficulty
will not grade you up to its hardest band until `ACH_WIN_MAJOR_SUB` — you have to
have won something first. The relegation equivalent: **a club cannot be relegated
out of a division in its first season in it.** A newly promoted side gets one year
to stand up. Real football has no such rule and every football game that lacks it
produces exactly the bounce we measured.

---

# Q2 — what a level is worth, and why ours is a trap

## Their numbers

| | |
|---|---|
| Attributes | four, 1–10 |
| Overall | 0.5–5.0 stars |
| One level | **+1 to one attribute** = 10% of one of four = ~2.5% of a player |
| The bar | `xp_level * 100`, checked whenever the card is looked at |
| XP income | **from production** — a better player gains more yards, so he levels faster |
| Remainder | **not carried**; one monstrous game cannot buy two levels |
| Level-up | **lifts his mood** (+10 on a 1–100 attitude) |
| Buying one | `xp_level * 4` credits — so level 5 is 20 CC against a season of 16–70 |
| At the ceiling | **a maxed player converts further level-ups into credits** |

## Ours, measured

`tools/probe_dev.gd`, with the price and the throttle both removed — 245 levels
placed over twelve seasons:

| | cost | worth |
|---|---|---|
| a level | 4–40 CC | **+0.05 club power** |
| an arena | 6–22 CC | every home gate, forever |
| a signing | 11–18 CC | **+3 to +6 club power** |

**One signing is worth about a hundred levels and usually costs less.** And the
starting squad has four of its five starters within six points of their ceiling
(Brand 37/38, Norrey 41/42), so training them is a dead end before you begin.

## Why the port produced that

Three reasons, and the register has already named two of them:

1. **`power_exact()` is the mean of the starting five.** A level is +1 to one of
   four stats on one of five men — 0.05 of the number that decides every result.
   Retro Bowl has no such number: their sim is your thumb.
2. **Our XP income is flat.** `xp_for` pays the same 2 + 3 a down + 1 a round
   standing in season ten as in season one. Theirs grows with production. That is
   why our bar had to be capped at `min(level, 3) * 8` — and a capped bar is a
   capped yield.
3. **We took their price curve and left the capped yield.** Price reads the level
   and rises forever; yield reads the bar and stopped at level three. §"THE PRICES
   ARE VARIABLE" fixed the price and never revisited the other half. The result is
   the only purchase in the game that gets more expensive while what it buys stays
   the same size.

## What I would do

**Their valve first, because it is free and it is obviously right.** A maxed
player in Retro Bowl converts further level-ups **into credits**. Ours refuses:
*"%s has nothing left to learn."* That is a dead end on a man you spent a career
building. Convert instead — a fighter at his ceiling turns a waiting level into
credits at `level_cost` — and the training ground stops being wasted on veterans.

**Then one of two, and this one is Pete's:**

- **(a) Make the level bigger.** `_raise_one` grants +1; grant more while the man
  is far below his ceiling. Turns a level from 0.05 to ~0.15 club power and makes
  the screen honest. Risk: it makes development compete with signing, which is a
  real change to what the game is about.
- **(b) Leave the number and fix the screen.** Tell the player what a level is
  worth. The level-up card shows an XP bar and a price, which reads like the
  upgrade it is not; a line saying *"+1 skill · your five average 41"* would stop
  a player spending a career on it. Cheapest honest fix, and it matches what
  Retro Bowl actually does — their level is *small* too, it is just visible.

My read is **(b) plus the valve**, because the alternative quietly turns a
transfer-market game into a training game, and Direction has never said that is
what this is.

---

# Q3 — where the money comes from

## Their faucet

**There is exactly one.** No gate receipts, no sponsorship, no subscriptions, no
money system at all. The chain is four links:

```
win / lose  →  fan %  →  three bands  →  coaching credits  →  everything
```

- One credit per third of the bar filled, **in full or in part** — so 1, 2 or 3 a
  game, and the floor is 1 rather than 0.
- **A loss pays nothing**, and losses move the meter more than wins do, so the
  economy pays for **consistency, not peaks**.
- Winning the Retro Bowl pays **+10**.
- A dominant season ≈ **70 credits**; a poor one ≈ **16–20**. That 3.5× spread is
  the entire mechanical footprint of their fan system.

And **one meter**. A single fan percentage does all of it.

## Ours, off the club's own books — a whole career, per season

| IN | | OUT | |
|---|---|---|---|
| Members' dues | **24.4** | The squad | 14.3 |
| The gate | 7.9 | Facilities | 10.7 |
| Prize money | 7.6 | The ground | 5.6 |
| The ground | 2.2 | The club | 5.6 |
| | | Kit and harness | 0.8 |
| | | Travel | 0.7 |

**58% of a career's income is a standing subscription**, and the gate — the thing
the whole arena, notoriety, turnout and fan apparatus exists to drive — is 19%.
Even after yesterday's venue work took it from 1.4 to 7.9.

## The thing worth saying plainly

`federation.gd` is explicit that this is deliberate:

> *"it is the income that does not move with results, so spending it on paperwork
> is a decision rather than an accounting entry."*

That is a good reason for the dues to **exist**. It is not a reason for them to
be the **biggest line**. `MEMBERS_MAX` is 60 and `DUES` is 1, so a mature club
banks 60 CC a season for belonging to itself, against a top-band National gate of
around 13 a home fight. The counterweight outweighs the thing it was built to
counterweight.

And underneath it: **we have three crowd nouns doing the job of their one.**

| ours | what it does |
|---|---|
| `notoriety` | 1–125, the turnout percentage, bands the gate |
| `fans` | the following, capped at capacity × 1.25 |
| `members` | pays the dues |

Retro Bowl has a fan percentage and nothing else. Three numbers that all mean
"how many people care about this club" is three numbers a player has to learn,
three screens to explain them on, and three places for the money to leak out of
the one the game actually wants him watching.

## What I would do

Not merge them — `fans` and `notoriety` genuinely do different work and Direction
argued for the split. But:

1. **Cap the dues against the gate rather than against a member count.** Members
   stay the federation's counterweight and stop being the club's main income.
2. **Or make the dues read results the way their fan meter does.** Members
   already move on a winning season, morale and a full bench; the move is slow and
   invisible. Retro Bowl's whole trick is that the meter that pays you changes on
   the results screen you are already looking at.

Either one makes fighting the main faucet, which is their design and is the thing
Pete noticed was wrong before any of these numbers existed.

---

# What I would not take

Unchanged from Part 1 and still the most important line in it: **their scarcity.**
Retro Bowl's early-game credit drought is priced against a 99-cent button and is
the most common complaint about the game. A premium title has no reason to
inherit a ramp that exists to sell something.

Their level price is `xp_level * 4`. Ours is half that rate with a `learn_rate`
term, and the register's reasoning for halving it stands: our credit economy is
smaller. Nothing here argues for closing that gap.

---

# Sources

- `REGISTER.md` §55, §59, §44, and "THE PRICES ARE VARIABLE" — decompile figures
  (`s_get_meeting_cost_levelup`, `s_has_xp_gain`, `s_team_interested`,
  `LangUS.txt` 911–923, `RetroBowl.js` 7714). Source, not analysis.
- Retro Bowl Wiki, *Coaching Credits* — the 1/2/3 bands and the +10 for the title.
- Rob's Complete Guide to Retro Bowl, *The Front Office* (2021) — facility pricing
  (`cost = the level you are buying`), the 100-credit salary-cap step, the
  one-upgrade-per-facility-per-week throttle, and the stadium's effect on the
  size of the fan swing in both directions.
- Ours: `tools/probe_dev.gd`, `tools/probe_run.gd`, `tools/probe_market2.gd`,
  `tools/probe_year1.gd`, `tools/probe_venue.gd`.

Trust: the stadium's exact fan percentages per win and per loss are **still not
public** and were not in the decompile session's notes. Everything attributed to
the stadium above is the direction of the effect, which is documented, not its
magnitude, which is not.
