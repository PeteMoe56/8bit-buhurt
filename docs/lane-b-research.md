# Lane B — economy and balance research (handoff, 2 Oct 2026)

Branch `lane/balance` (from main at 29cfcc4). No PR opened yet. No REGISTER row
yet. Everything below is measured unless marked **open**.

## The brief

(a) The gold-button novice bot ends 60 seasons with ~18.6k CC unspent, signs
nobody, and yo-yos (9 up, 9 down). (b) Keep the bases (first National title)
between 9 and 13; the target is 10–12. Do not touch Pete's rulings: +3 points a
level, the armorer's winter repair, fights wearing kit, wages per year.

## 1. Before — main's behaviour

### Bases (`bash tools/bb.sh bases`, 5 × 20 seasons)

| base | title | t1 | t2 | t3 | power | cc |
|---|---|---|---|---|---|---|
| 9001 | 10.8 | 2.0 | 3.6 | 8.0 | 84.2 | 84.9 |
| 5150 | 10.0 | 2.2 | 4.6 | 7.6 | 82.2 | 83.5 |
| 2718 | 11.0 | 2.2 | 4.6 | 7.0 | 84.4 | 81.6 |
| 6060 | 11.2 | 2.0 | 3.6 | 6.8 | 81.8 | 80.8 |
| 8123 | 10.4 | 2.2 | 4.4 | 8.0 | 87.4 | 81.8 |
| **mean** | **10.68** | | | | | |

### Novice bots (CI run 36965671922; prompt and signing-starts switched off, so equivalent to main)

| run | seasons | promotions | relegations | top tier | CC at end | peak CC | Sign presses |
|---|---|---|---|---|---|---|---|
| gold_1 | 67 | 9 | 9 | 3 | 20541 | 20539 | 0 |
| gold_2 | 55 | 13 | 13 | 2 | 17179 | 17191 | 0 |
| gold_3 | 50 | 14 | 14 | 2 | 13352 | 13384 | 0 |
| simmer_1 | 128 | 4 | 4 | 1 | 901 | 3275 | 19 |
| simmer_2 | 73 | 5 | 5 | 1 | 2424 | 2611 | 23 |
| simmer_3 | 122 | 4 | 4 | 1 | 1532 | 4511 | 26 |
| spender_1 | 20 | 3 | 3 | 1 | 12 | 3 | 52 |
| spender_2 | 17 | 7 | 6 | 1 | 0 | 1 | 44 |
| spender_3 | 18 | 6 | 5 | 1 | 10 | 3 | 46 |

Division by season (0 Backyard … 3 National):

```
gold_1  0112122232212221101010111121000000000000000000000000000000000000000
gold_2  0001122212221210001111212100101010010101000000000000000
gold_3  01112221212212112121111212121211001110111121000000
simmer  0100000…  / 0101000… / 01110000…   (Backyard for life after season 2–4)
spender 00000000111111000000 / 00000000000000000 / 000001111111100000
```

Gold banks at a steady ~350 CC a season (CC at 10/20/30/40/50/60 for gold_1:
973 / 4777 / 8054 / 11208 / 14830 / 18330).

## 2. Why — what the code says

1. **The gold button never leads to the free agents.** The hub's primary is
   always the next fight or a blocker. The market is behind TEAM → "Free
   agents", which is never gold.
2. **A signing never fights.** `MeleeClub.sign()` puts a new man in the reserve.
   `starting_five()` walks `active_eight()` in roster order, so he plays only
   after a manual swap. `MeleeClub.best_line()` exists and fixes this, but only
   `tools/manager.gd` (the bases' manager) calls it; no button does. So even
   simmer's ~20 signings mostly sat in the reserve.
3. **The yo-yo:** gold wins the Backyard with its starting men, takes "Build
   now" at the gate (30.67), goes up on an unchanged squad, gets sent back down,
   and repeats. Once the original men age (~season 30) it can't win the Backyard
   either and banks for good.
4. **The bases cannot see any of this.** `ProbeManager` signs every winter and
   calls `best_line()`. Its average bank is ~82 CC, meaning it spends everything.
   That is why the bases sit at 10.7 while novices never climb.
5. **A market bug found on the way:** the Sign button was gold whenever the fee
   was affordable, even when the cap or a full roster would refuse the signing.
   With the free-agent prompt on, the gold bot pressed a refused Sign
   21,697 / 79,154 / 74,218 times (CI run 36965180870) and stalled; gold_2 got
   through 9 seasons.

## 3. What is on `lane/balance` now

Every change sits behind a named constant.

| constant | file | default | what |
|---|---|---|---|
| `MARKET_ASK` | `scripts/league/season_desk.gd` | true | Free-agent prompt (hub card) |
| `MARKET_ASK_ALWAYS` | same | false | Ask every season, not only the first season up |
| `MARKET_ASK_HOARD` | same | false | Also ask a club holding `Season.HOARD_SUMMERS` (4) summers' bills |
| `SIGNING_STARTS` | same | true | A signing who outrates a man on the eight takes his place (his own position first) |
| `PROMOTED_FEE_MULT` | `scripts/league/market.gd` | 1.0 | Fee multiplier in the first season after promotion |

- **Prompt.** `SeasonDesk.market_ask()` fires once a season (`Season.market_warned`, saved) before the
  first bout, with no blocker, when there is an upgrade on the list:
  `market_upgrades()` = rated above the weakest of the eight, fee payable with
  the summer bill still in hand, under the cap, a place on the books. The card is
  `SeasonClubTab._draw_market_ask` / `_market_ask_controls`. Its gold "Free agents"
  opens `Market.tscn` with that man picked (`Session.market_pick`); "Later" closes
  it for the season. It is shown after the ground prompt, never at the same time.
- **Market fix.** `SeasonDesk.sign_wall()` returns "fee" / "cap" / "full" / "".
  `market_scene.gd` makes Sign gold only on "", otherwise the label reads
  "Can't afford …", "Books full at 13" or "X: over the cap".
- **Strings** (all 8 languages, `bb.sh strings` run): "THE %s HITS HARDER",
  "The weakest man on your eight rates %d. %d free agents rate higher, and you
  can pay for them.", "Best of them: %s, %d, %d CC.", "Books full at %d",
  "%s: over the cap".
- **Tests:** `tests/test_market.gd` `_test_the_first_year_up` has five checks
  (ask, fee share, signing starts, once a season, gold Sign = signing goes
  through). `tests/test_queue.gd` closes the card like the ground card. Fast tier
  green on test_market, season, office, save, queue, roster, nav, edges, coach and
  untranslated. `RB_SECTIONS=shapes,langs` is green locally (28 runs).
- **Shots:** `bash tools/bb.sh shot market_ask 960x540 <dir> <locale>` produces
  the card and the picked market. Checked in en, de, ru and ja.
- **Tooling:** `tools/novice/summarize.py` gained peak CC, Sign presses and a
  division-by-season trace. `.github/workflows/novice.yml` takes `edits` (the
  same `[[file, sed]]` shape as `sweep.yml`) and prints the table to the
  summary job's log.

## 4. Sweep results so far

### Bases vs `PROMOTED_FEE_MULT` (CI run 36965188925)

| variant | mean first National title |
|---|---|
| 1.0 | 10.68 |
| 0.75 | 10.68 |
| 0.6 | 10.56 |

Inside the noise. The bases' manager already spends everything, so the fee curve
doesn't move the bases. `SIGNING_STARTS` can't move them either, because the
manager calls `best_line()` after signing. The prompt is UI only. **Every
candidate keeps the bases in 9–13.**

### Bots, round 1 (prompt + signing-starts, before the market fix; CI run 36965180870)

Not usable for gold: it was stuck on the refused Sign. For the record, gold_1
reached tier 3 and finished at 8.4k CC instead of 20.5k; simmer and spender
look like the baseline. Runs 36965183821 (fee 0.75) and 36965186307
(prompt every season) have the same bug in them, so ignore them.

### Bots, round 2 (with the market fix) — **open, still running when packed**

| CI run | variant (sha) |
|---|---|
| 36968619434 | prompt after promotion + signings start, fee 1.0 (db9aa30) |
| 36968622357 | same, `PROMOTED_FEE_MULT` 0.6 |
| 36968624593 | `MARKET_ASK_ALWAYS` true |
| 36968626808 | `MARKET_ASK` false (signings start alone) |
| 36968649875 | `MARKET_ASK_HOARD` true (9a78f70) |

Read each run's `summary` job log (the table is printed there) and compare it
with section 1.

## 5. What's left for Lane B

1. Read round 2. Pick the set where gold signs men, holds a division after
   promotion (fewer relegations, a higher division over the last 20 seasons) and
   doesn't hoard. Prediction: signings start + the prompt + `MARKET_ASK_HOARD` is
   what reaches the Backyard hoarders. If the hoard prompt wins, its card title
   ("THE %s HITS HARDER") needs a second wording for a club that wasn't promoted.
2. Watch spender: it is broke at 0–12 CC in every run. That is a separate
   question (it buys everything) and outside the brief unless a change makes it
   worse.
3. Set the winning constants and re-run `bash tools/bb.sh bases` (expect ~10.7).
4. Add a REGISTER row (next after 30.68) saying what changed and why.
5. Open ONE PR from `lane/balance` with the before/after tables. Post a status
   comment when it opens and when "Suite / gate" is green.
6. Explanations belong in the "?" popups and the Guide (Pete's rule). The prompt
   card only states numbers. Consider a Guide line under "team" or "money": a
   signing who outrates a man on the eight takes his place.

## 6. Other leads, not pursued

- Dues and upkeep scaling: the bank grows ~350 CC a season in the Backyard
  against a summer bill in the tens, so dues would need to be ~10× higher to
  bite, and that would punish the bases' manager. Not tried.
- Banked CC turning into something: the hoard prompt (`MARKET_ASK_HOARD`) is the
  lightest version. A heavier one would be a sink (e.g. a youth academy) and is a
  design question for Pete.
- No button calls `best_line()`. A "Pick my best eight" button on TEAM would let
  a player get what the bases' manager does every winter. It may make
  `SIGNING_STARTS` redundant; it's a design question for Pete.
