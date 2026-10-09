# Harness #2 — Codex round 2

8 October 2026, 17:58:06 US Central, from the clock. Base **7c79a7f3522529a06a503b6b07e69236b08ad937**. Eight cases including the repeated value control; seven additions/combination tests. Main game code, primary probe and manager unchanged; no commits or pushes. Blind is over; Claude’s supplied findings were read, not his V2 outputs.
## Verdict

**Recommend `sponsor` alone as the candidate for Pete’s decision and Claude’s gate.** It passes both original buyers in both cohorts: **10.28 / 10.28** against **10.88** default; **10.16 / 9.76** against **10.40** held-out. All observed titles, no censored careers. Nonbuyers move **0.00** versus their same-set control; held-out’s **−0.48** versus the old 10.88 is a cohort difference, not a mechanical penalty. Sources: sponsor’s respective `careers.tsv: first_title_season,right_censored`; [PARITY-R2.json](PARITY-R2.json).

The mechanism is a maintained-kit sponsorship receipt, rather than a further price reduction or larger base bonus. It earns roughly 57 CC per buyer-season in the measured window. This is conditional on the existing value platform, not a claim about the original expensive shop. Prefer this isolated mechanism to the combination: the gas addition fails a matched real-melee symmetry check. **Do not land the gas variants on these results.**

The means do not erase counterexamples: sponsor’s held-out base **43049** is **+1.60** seasons for H and **+0.20** for D. Default base **9001** is **+0.40** for D. Source: sponsor’s `base_contrasts.tsv: restricted_time_delta_mean`. The pass mark is met in the requested cohorts; a reliable benefit across arbitrary seeds is still unestablished.
The previous recommendation is superseded: value’s default advantage did not generalize. Both buyer arms must be no slower than the nonbuyer **separately in both sets**, with title attainment reported and nonbuyer movement within 0.5 seasons. A pass below is a measured-cohort pass; it is not evidence of a universal benefit. These evaluation sets are now reused design inputs, so neither is a fresh confirmation of the adaptive combination.
## Title results

N = no harness; H = harness first; D = development first. Wait is mean `min(first National title season,20)`. A never-winner contributes 20, with its censor flag retained. Cells show **wait; observed titles/25**. All careers continue for the full 20-season window.
### default: bases 9001, 5150, 2718, 6060, 8123

| Case | N | H | D | Nonbuyer movement | Set criterion |
|---|---:|---:|---:|---:|---|
| control | 10.88; 25/25 | 10.88; 25/25 | 10.44; 25/25 | +0.00 | pass |
| sponsor | 10.88; 25/25 | 10.28; 25/25 | 10.28; 25/25 | +0.00 | pass |
| turnout | 10.88; 25/25 | 10.72; 25/25 | 10.84; 25/25 | +0.00 | pass |
| gas | 10.88; 25/25 | 10.76; 25/25 | 10.40; 25/25 | +0.00 | pass |
| reuse | 10.88; 25/25 | 10.88; 25/25 | 11.04; 25/25 | +0.00 | fail |
| resale | 10.88; 25/25 | 11.00; 25/25 | 10.40; 25/25 | +0.00 | fail |
| cupwear | 10.88; 25/25 | 11.20; 25/25 | 11.04; 25/25 | +0.00 | fail |
| sponsor-gas | 10.88; 25/25 | 9.80; 25/25 | 9.80; 25/25 | +0.00 | pass |

### heldout: bases 17011, 29033, 43049, 67061, 91081

| Case | N | H | D | Nonbuyer movement | Set criterion |
|---|---:|---:|---:|---:|---|
| control | 10.40; 25/25 | 10.76; 25/25 | 10.80; 25/25 | +0.00 | fail |
| sponsor | 10.40; 25/25 | 10.16; 25/25 | 9.76; 25/25 | +0.00 | pass |
| turnout | 10.40; 25/25 | 10.96; 25/25 | 10.56; 25/25 | +0.00 | fail |
| gas | 10.40; 25/25 | 10.40; 25/25 | 10.52; 25/25 | +0.00 | fail |
| reuse | 10.40; 25/25 | 10.56; 25/25 | 10.72; 25/25 | +0.00 | fail |
| resale | 10.40; 25/25 | 10.76; 25/25 | 10.64; 25/25 | +0.00 | fail |
| cupwear | 10.76; 25/25 | 11.40; 25/25 | 10.80; 25/25 | +0.36 | fail |
| sponsor-gas | 10.40; 25/25 | 9.56; 25/25 | 10.08; 25/25 | +0.00 | pass |

Timing sources: `docs/bakeoff-2/harness/codex-r2-<case>/<set>/careers.tsv`, columns `base,seed,first_title_season,right_censored`; `attainment.tsv: titles_observed,right_censored`. Nonbuyer reference is 10.88 default / 10.40 held-out. Exact summaries and budget values: [RESULTS-R2.tsv](RESULTS-R2.tsv), [SUMMARY-R2.json](SUMMARY-R2.json).
## Paired per-base spread

Each list is **buyer minus N**, averaged over the five matched seeds in each base, in the base order printed above. Negative means faster. No pooling of the two sets.

| Case | Set | H − N, by base | D − N, by base |
|---|---|---|---|
| control | default | +1.6, -0.6, -0.4, -1.0, +0.4 | +0.6, -0.4, -1.0, -1.6, +0.2 |
| control | heldout | +0.2, +0.6, +1.2, -0.6, +0.4 | +0.8, -0.4, +2.2, -0.4, -0.2 |
| sponsor | default | -0.6, -0.2, +0.0, -1.4, -0.8 | +0.4, -1.0, -0.8, -1.4, -0.2 |
| sponsor | heldout | -0.8, -0.8, +1.6, -0.8, -0.4 | -1.0, -0.4, +0.2, -1.2, -0.8 |
| turnout | default | +0.6, -0.2, -0.6, -1.4, +0.8 | +1.6, -0.6, -0.6, -1.2, +0.6 |
| turnout | heldout | +0.6, +0.0, +2.2, +0.4, -0.4 | +0.2, +0.0, +1.6, -0.4, -0.6 |
| gas | default | -1.0, -0.6, -0.6, -0.8, +2.4 | -0.8, -0.2, +0.0, -1.2, -0.2 |
| gas | heldout | -0.6, +0.2, +1.0, -0.4, -0.2 | -1.0, +0.6, +1.0, -0.2, +0.2 |
| reuse | default | +1.6, -0.6, -0.8, -0.8, +0.6 | +1.2, -0.8, +0.0, -0.4, +0.8 |
| reuse | heldout | +0.0, +0.0, +1.2, -0.6, +0.2 | +0.8, -0.4, +2.0, -0.6, -0.2 |
| resale | default | +0.6, -0.4, +0.6, -0.8, +0.6 | +0.4, -0.4, -0.2, -2.6, +0.4 |
| resale | heldout | +0.8, +0.0, +1.4, -0.6, +0.2 | +0.0, +0.4, +2.0, -0.6, -0.6 |
| cupwear | default | -1.0, -0.2, +0.2, +0.8, +1.8 | -0.8, -0.2, +0.8, +0.0, +1.0 |
| cupwear | heldout | +1.2, -0.2, +0.8, +1.8, -0.4 | +0.2, -0.8, +0.0, +1.4, -0.6 |
| sponsor-gas | default | -1.0, -1.8, -0.4, -1.8, -0.4 | -0.8, -1.8, -0.8, -1.6, -0.4 |
| sponsor-gas | heldout | -2.2, -0.8, +0.6, -0.8, -1.0 | -2.0, -0.6, +1.4, +0.2, -0.6 |

Sources: each output’s `base_contrasts.tsv: reference,treatment,base,restricted_time_delta_mean`, derived from the matched career rows. [BASES-R2.tsv](BASES-R2.tsv) combines them. A positive base remains a counterexample even when its set’s mean passes.
## Income and kit budget

Triples are **N / H / D**. Income is CC per closed season across the full window. Kit is CC per 20-season career: upgrades + armorer hire + wages + repairs. It includes spending after the first title. Faster promotion itself changes income, so the income difference is not all direct kit return.

| Case | Set | Income CC/season, N/H/D | Kit CC/career, N/H/D |
|---|---|---|---|
| control | default | 308.60 / 299.21 / 303.61 | 0.00 / 279.16 / 281.44 |
| control | heldout | 312.84 / 299.97 / 298.23 | 0.00 / 281.64 / 275.00 |
| sponsor | default | 308.60 / 378.45 / 379.40 | 0.00 / 291.40 / 285.12 |
| sponsor | heldout | 312.84 / 383.85 / 383.00 | 0.00 / 282.24 / 285.80 |
| turnout | default | 308.60 / 306.30 / 307.81 | 0.00 / 283.20 / 285.20 |
| turnout | heldout | 312.84 / 305.03 / 305.76 | 0.00 / 282.28 / 281.48 |
| gas | default | 308.60 / 309.88 / 304.54 | 0.00 / 286.16 / 282.76 |
| gas | heldout | 312.84 / 304.74 / 305.48 | 0.00 / 283.88 / 281.88 |
| reuse | default | 308.60 / 305.87 / 295.65 | 0.00 / 207.76 / 209.20 |
| reuse | heldout | 312.84 / 300.31 / 301.30 | 0.00 / 215.04 / 206.60 |
| resale | default | 308.60 / 304.26 / 306.81 | 0.00 / 283.08 / 281.40 |
| resale | heldout | 312.84 / 303.84 / 301.14 | 0.00 / 284.40 / 278.36 |
| cupwear | default | 295.36 / 298.09 / 294.37 | 147.84 / 293.08 / 292.08 |
| cupwear | heldout | 293.32 / 292.15 / 294.84 | 135.24 / 289.64 / 295.00 |
| sponsor-gas | default | 308.60 / 385.54 / 384.79 | 0.00 / 295.84 / 300.12 |
| sponsor-gas | heldout | 312.84 / 390.89 / 384.16 | 0.00 / 289.24 / 285.80 |

Income source: `seasons.tsv: cc_in` (500 seasons/arm). Kit source: `metadata.json: checks[].costs_cc.{harness_upgrade,armorer_hire,armorer_wage,repair}` (25 careers/arm). Sessions, ceiling raises and signing remain separate in RESULTS-R2.tsv.

For sponsorship, paired budget differences versus the same-set nonbuyer are:

| Set | Buyer | Direct sponsorship CC/season | Sessions Δ | Ceiling raises Δ | Signing Δ |
|---|---|---:|---:|---:|---:|
| default | harness_first | 56.772 | +13.546 | +11.124 | +8.584 |
| default | development_first | 56.994 | +15.722 | +11.000 | +10.540 |
| heldout | harness_first | 56.992 | +10.488 | +13.498 | +11.916 |
| heldout | development_first | 57.492 | +11.040 | +15.208 | +10.954 |

Direct receipt source: `*.jsonl` transaction rows `direction=in,line=Harness sponsorship,cc`; denominator 500 seasons/arm. Budget deltas: `paired.tsv: session_cc_delta,ceiling_raise_cc_delta,signing_cc_delta`, averaged over 25 pairs and divided by 20 seasons. These are full-window effects, not a decomposition of the first-title gain.

Hand-downs cut default kit spending by **71.40 / 72.24 CC per career** versus value (H/D), but do not pass title timing. Source: each `metadata.json: checks[].costs_cc`, same four kit categories. Resale also fails; cash recovered is not proof of a faster title.

## Designs and standalone patches

Apply **one** r2 patch to the base, not over value.patch. Every patch retains the same platform: `scripts/league/quartermaster.gd: WEAR [1,.86,.72,.58,.50] → [1.05,.90,.48,.28,.10]`, `COST [6,14,28,48] → [1,2,4,7]`; `scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3]`; `scripts/melee/fighter_card.gd: HARNESS_BASE_BONUS absent → [0,.02,.05,.09,.12]`, effective base capped at 99. **R2 does not further cut prices or enlarge this base bonus.** Thus these results are conditional on the value platform; they do not establish success at the original shop prices. Round 1’s price, wage, base-bonus and wear isolation controls remain in REPORT.md.

- [r2-control.patch](r2-control.patch): unchanged value, repeated on both sets.
- [r2-sponsor.patch](r2-sponsor.patch): `scripts/league/quartermaster.gd: APPEARANCE_CC absent → [0,.08,.20,.40,.65]` CC per maintained man per actual bout, times condition. `scripts/league/club_office.gd: harness_receipts absent → saved fractional carry`; whole credits go through `take`, a separate sponsorship income line. League regime processing and cup-result processing pay; forfeits do not. No extra combat stat.
- [r2-turnout.patch](r2-turnout.patch): `scripts/league/office_crowd.gd: HARNESS_DRAW absent → [0,.01,.025,.04,.06]`; add each traveling fighter’s grade draw × condition to the existing capped crowd multiplier. It affects attendance, gate bands and pull, not a guaranteed flat gate increase.
- [r2-gas.patch](r2-gas.patch): `scripts/melee/fighter_card.gd: HARNESS_GAS_BONUS absent → [0,.01,.03,.05,.07]`; `effective_gas raw → min(99,raw*(1+bonus*condition))`. Rating and club power, melee tank via fighting_gas, and card overall use it. The raw gas bar, ability, potential and growth ceilings do not. Only its added bonus fades to zero with condition.
- [r2-reuse.patch](r2-reuse.patch): `scripts/league/quartermaster.gd: hand_down absent → grade/condition swap on a successful release, retirement or contract departure`; active recipients first, lowest grade, age ≤30, outgoing condition ≥.40. Both physical kits retain condition; no refill or cash. Recompute fighter trade value after the swap. Club splits excluded.
- [r2-resale.patch](r2-resale.patch): `scripts/league/quartermaster.gd: RESALE_FRACTION absent → .50`; outgoing kit returns `floor(.50*condition*cumulative rung cost)` on those same departures, is consumed, and cannot pay twice. Separate resale income; no purchase discount.
- [r2-cupwear.patch](r2-cupwear.patch): `scripts/league/season_cups.gd: sim_cup_tie no wear → bout_wear + sync_power` after settlement, matching the existing fought cup path. Added from the instrument audit before any complete results were read.
- [r2-sponsor-gas.patch](r2-sponsor-gas.patch): sponsor + gas exactly as isolated above. Adaptive to default-set results; frozen before held-out results were read.

The tests beside each case measure its addition against control; the combination has both constituent controls. TOP, repair step/formula, inspection threshold, XP and raw growth ceilings are unchanged. Prices/wages/base bonus are inherited dependencies, not newly isolated R2 changes. Freeze times and selection rule: [PLAN-R2.md](PLAN-R2.md). Commands: [COMMANDS-R2.md](COMMANDS-R2.md).
## Instrument and validation

All **1,200 careers / 24,000 closed seasons / 1,200 paired rows** finished with probe validation true and independent validation passed. The independent replay reconciled **11,204,940 journal rows and 1,873,111 transactions**, source hashes, every cash movement, closed books, XP, censoring and paired summaries. This includes repeated controls, not that many independent samples. Sources: each `metadata.json: validation_passed,checks`; `validation.json: careers,seasons,pairs,totals`; [VALIDATION-TOTALS-R2.json](VALIDATION-TOTALS-R2.json), [SHA256-R2.tsv](SHA256-R2.tsv), [SOURCE-PINS-R2.json](SOURCE-PINS-R2.json).

All nonbuyer journals outside cupwear match their same-set control byte-for-byte; the default control’s **75** journals match round 1 value. [PARITY-R2.json](PARITY-R2.json). Cupwear alone records **14 / 2** nonbuyer inspection crossings (default/held-out), **0** in its buyers, and shifts held-out N **+0.36**. All cases record **0** calendar/cup actions ending at zero power. Sources: `analysis.json: arms.*.ledger_metrics_total.{inspection_crossings,zero_power_calendar_or_cup_actions}`. These observations do not prove absence of a transient failed lineup or an actual forfeit: the primary ledger omits the pre-fielding eligibility state and emergency outcome.

The focused grade/feature fixtures pass on all eight cases; they verify actual wear order and uneven steps through Titanium, unchanged raw ability/headroom, fractional saved receipts, gas fading, conserved physical kit and consumed resale. Initial fixture setup errors (missing/wrong Season constructor argument) were corrected; original error logs are retained. Existing save suite: **21** checks; reuse/resale market suites: **26** each. Source: `work-r2/logs/*-fixture-stdout.txt`, `sponsor-save-stdout.txt`, `reuse-market-stdout.txt`, `resale-market-stdout.txt`.

The short invariant runs pass **118** checks, **17** save round trips and **15** fought bouts, but **do not prove buyer coverage**: even enabling RB_HARNESS does not call the seasonal shop in that test. The guarded buyer fixture instead records **103 CC** in the manager’s tracked harness/hire purchases, **5** paid starters, **3** fought bouts and **9 CC** sponsorship; whole-career cash/books/fraction survive reload, and nonfight regime processing pays nothing. Source: `work-r2/logs/sponsor-fought-check-stdout.txt: PURCHASE_GUARD,FOUGHT_SPONSORSHIP,CHECK`.

**Gas is rejected for landing.** Its heavy-deficit fixture still gives Titanium **1/48** wins at a 16-point raw-stat deficit on each base **30000 / 61000**, below C6’s 40% wall. However, its 400-bout Titanium mirror yields **153 wins / 246 losses / 1 undecided** (**38.35%** of decided bouts), failing the existing symmetry band (50±9). The identical control fixture yields **198 / 202 / 0** (**49.50%**), passing symmetry and C3. Gas narrowly passes C3’s lower threshold; the failed check is symmetry, not C3. Sources: `gas-quality-stdout.txt: CELL,TARGETED_CHECK_FAILURES`; `gas-mirror-stdout.txt` and `control-mirror-stdout.txt: mirror,TITANIUM_MIRROR_CHECKS`; retained fixtures in `work-r2/`. The sponsor-gas patch shares gas’s combat formulas, so a career pass does not clear this failure. These are targeted checks; **the full balance tier and Windows gate were not run or claimed**.

Instrument limits:

- Career outcomes use aggregate-power quick bouts, not melee play. Quick bouts do not call `_apply_bout_injuries`; an injury-protection change cannot establish its value with this required probe. No injury variant was pretended to do so.
- Quick cup ties currently skip persistent wear; fought ties do not. Cupwear measures the correction but fails the shop criterion. Sponsorship uses the actual cup-result path with forfeits excluded, so it does not depend on that missing wear hook.
- League wear/payment follows the existing post-injury-substitution lineup. It is not an audited record of every man who actually fought; correct participation attribution before landing. The ledger lacks availability/position and fractional receipts, so its independent replay verifies booked cash, not the complete attendance/accrual rule. Dedicated feature/save fixtures cover that rule separately.
- The manager knows hidden ceilings, repairs frequently at effectively zero CC, and buys by its preset policy. Neither human shopping nor repair effort is measured. Crowd draw is cached and refreshed through the existing setter; immediate purchase-to-gate display needs integration acceptance.
- All prototypes retain the old value base bonus: it reaches rating/club power, melee defence and card overall, not raw ability; its condition factor does not fade completely. Gas’s extra bonus does. No kit changes growth ceilings. C1/C4/C5, C2/C6 and pacing remain required in Claude’s selected gate; income gains and ledger checks are not substitutes for them.

Engine: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`; fresh **`--version`: 4.6.2.stable.official.71f334935** (`work-r2/logs/engine-version.txt`). Some otherwise validated exit-zero sweeps retain existing ObjectDB/two-resource shutdown warnings. Main remains at the base; the pre-existing deletion of `tools/probe_scouting.gd.uid` was left alone.
## Next measurement and Pete’s decision

**One next measurement:** freeze sponsor’s standalone patch and run the unchanged primary probe on a third, predeclared set **110017 130021 150041 170047 190027**, five seeds per base, 20 seasons, original three arms, fresh output `res://docs/bakeoff-2/harness/codex-r2-sponsor-confirm`. Retain the same source pins, title/censor columns, per-base paired deltas and independent cash/XP validation. Require both buyers no slower than their same-set nonbuyer, with its wait reported separately; do not tune the payout on those results. This is confirmation, not another R2 variant already measured.

**Pete’s design question:** does a maintained-kit sponsorship contract fit the shop’s meaning, and is roughly 57 extra CC per buyer-season an acceptable return? The experiments support the first-title criterion; they cannot choose that fiction or its presentation. If selected, Claude should correct fought-line attribution, expose the payout and existing kit benefit on the card/books using the shared glossary and text-fit checks, then run the balance tier and full gate. The inherited cheap prices remain an explicit part of the candidate. No main game change is applied here.
