# Harness #2 — Codex blind report

8 October 2026, 16:18:08 US Central. Base **7c79a7f3522529a06a503b6b07e69236b08ad937**; Pete's 15:50 update applies. Claude's plan and results were not read. Main game code, primary probe and manager remain unchanged; no commit or push.

## Recommendation

**Recommend `value` for Pete's selection and Claude's gate.** It meets the updated title criterion in this measured cohort: development-first buyers won **25/25**, averaging **10.44** seasons against nonbuyers' **10.88**; harness-first also won **25/25**, tying **10.88**. Nonbuyer wait moved **+0.00** from the supplied control. The restrained buyer separately won **25/25**, waiting **10.48** (**-0.40** versus its nonbuyer). These are cohort means, not a promise for every seed or player. Sources: respective `careers.tsv`, `first_title_season/right_censored`; [RESULTS.tsv](RESULTS.tsv).

## Designs and patches

Every `.patch` is a **standalone diff against the base**, not an incremental patch stack. Grades are Rust / Mild / Hardened / Stainless / Titanium. Unlisted mechanics stay at the base.

1. [wear.patch](wear.patch): `scripts/league/quartermaster.gd: WEAR [1,.86,.72,.58,.50] → [1.30,.95,.55,.30,.12]`. Isolates persistent durability.
2. [economy.patch](economy.patch): wear plus `scripts/league/quartermaster.gd: COST [6,14,28,48] → [3,6,10,18]`; `scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,2,3,5]`.
3. [grade.patch](grade.patch): economy plus `scripts/melee/fighter_card.gd: HARNESS_BASE_BONUS absent → [0,.02,.05,.09,.12]`; `effective_base base*condition_factor → min(99,base*(1+grade_bonus)*condition_factor)`.
4. [gentle.patch](gentle.patch): grade with `scripts/league/quartermaster.gd: WEAR [1,.86,.72,.58,.50] → [1.05,.90,.48,.28,.10]`.
5. [value.patch](value.patch): gentle with `scripts/league/quartermaster.gd: COST [6,14,28,48] → [1,2,4,7]`; `scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3]`.
6. [prices.patch](prices.patch): **only** `scripts/league/quartermaster.gd: COST [6,14,28,48] → [1,2,4,7]`.
7. [wages.patch](wages.patch): **only** `scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3]`.
8. [bonus.patch](bonus.patch): **only** the grade bonus/formula in item 3.

The isolated controls retain the base's uneven wear steps; combinations strengthen the ladder. TOP, inspection threshold, repair formula/step, XP and raw growth ceilings never change. WAGE also sets the hire fee through the existing API: wage-only isolates that table, not recurring costs from upfront fees. This is not a full factorial: isolated price/wage controls use value settings, not economy's intermediate settings. Value was designed after the first four results; the three isolation controls followed Pete's update. Frozen decisions and clock times: [PLAN.md](PLAN.md), [VALUE-PLAN.md](VALUE-PLAN.md), [CONTROLS-PLAN.md](CONTROLS-PLAN.md).

**Where the bonus acts:** `effective_base()` feeds fighter rating, position-adjusted club power, melee defence through `MeleeSim.Man.eff_base()`, and the card's overall. Raw stat bars, `ability()`, potential and growth headroom remain unchanged. Condition multiplies the bonus too: at the inspection line it retains 85.7% of its full-condition amount; it does not fade fully. The sim additionally applies its live harness multiplier. WEAR changes persistent post-bout condition, **not** the sim's separate within-bout depletion. See `fighter_card.gd: effective_base/ability/overall`, `melee_club.gd: power_exact`, `melee_sim.gd: eff_base`, and `season_bouts.gd: bout_wear`.

## Per-arm results

Titles column gives observed titles, then censored careers in parentheses, out of 25. Wait = mean `min(first National title season,20)`; a censored career contributes 20, never an invented later win. Income is CC per closed season. Kit CC is mean **all 20 seasons per career**, including upgrades, armorer hire/wages and repairs; it includes spending after the first title.

| Variant | Arm | Titles (censored) | Capped wait | Income CC/season | Kit CC/career |
|---|---|---:|---:|---:|---:|
| wear | no harness | 25 (0) | 10.84 | 309.304 | 0.00 |
| wear | harness first | 9 (16) | 18.96 | 184.718 | 1091.88 |
| wear | development first | 5 (20) | 18.80 | 195.232 | 650.36 |
| economy | no harness | 25 (0) | 10.84 | 309.304 | 0.00 |
| economy | harness first | 25 (0) | 13.28 | 256.104 | 649.60 |
| economy | development first | 20 (5) | 13.88 | 242.894 | 622.20 |
| grade | no harness | 25 (0) | 10.84 | 309.304 | 0.00 |
| grade | harness first | 25 (0) | 12.44 | 271.938 | 655.12 |
| grade | development first | 24 (1) | 13.52 | 254.966 | 635.32 |
| gentle | no harness | 25 (0) | 10.88 | 308.596 | 0.00 |
| gentle | harness first | 25 (0) | 12.28 | 271.816 | 657.20 |
| gentle | development first | 23 (2) | 13.64 | 254.140 | 633.84 |
| value | no harness | 25 (0) | 10.88 | 308.596 | 0.00 |
| value | harness first | 25 (0) | 10.88 | 299.210 | 279.16 |
| value | development first | 25 (0) | 10.44 | 303.612 | 281.44 |
| prices | no harness | 25 (0) | 10.88 | 309.640 | 0.00 |
| prices | harness first | 16 (9) | 15.44 | 231.328 | 517.48 |
| prices | development first | 15 (10) | 17.48 | 214.658 | 505.64 |
| wages | no harness | 25 (0) | 10.88 | 309.640 | 0.00 |
| wages | harness first | 23 (2) | 14.08 | 244.102 | 1146.72 |
| wages | development first | 21 (4) | 13.96 | 251.690 | 508.72 |
| bonus | no harness | 25 (0) | 10.88 | 309.640 | 0.00 |
| bonus | harness first | 8 (17) | 18.44 | 200.592 | 1139.76 |
| bonus | development first | 12 (13) | 16.92 | 207.566 | 689.80 |
| value-sensible | sensible buyer | 25 (0) | 10.48 | 312.512 | 67.04 |

Raw sources: `docs/bakeoff-2/harness/codex-<variant>/careers.tsv` columns `first_title_season,right_censored,cc_in`; `seasons.tsv: cc_in`; `metadata.json: checks[].costs_cc` (`harness_upgrade,armorer_hire,armorer_wage,repair`). Denominators: 25 careers × 20 seasons = 500 closed seasons per arm. `analysis.json` and [RESULTS.tsv](RESULTS.tsv) retain exact values and budget categories. Policy row comes from `codex-value-sensible`; its repeated original arms match value byte-for-byte across all 75 journals ([policy-parity.json](policy-parity.json)).

## What the comparisons establish

- Durability alone leaves buyers much slower; no-harness wait is **10.84**, just **−0.04** from 10.88. Across all variants, observed inspection crossings and calendar/cup actions ending with zero club power are **0** in every arm. Repairs are nearly free under this manager, so buying cannot repay itself chiefly by avoiding a maintenance bill. Source: `analysis.json: arms.*.ledger_metrics_total`, `metadata.json: checks[].costs_cc.repair`; all per-arm counts are in RESULTS.tsv.
- Costs are the main lever in this instrument. Price-only waits are **15.44/17.48**, wage-only **14.08/13.96**, bonus-only **18.44/16.92** (harness-first/development-first): none passes. Intermediate combinations improve them, but only value reaches the cohort's no-delay criterion. Full-window incomes also depend on promotion and titles; they are not independent proof of return on investment.
- For value, development-first's paired capped difference is **−0.44** seasons; the five base means are **+0.60, −0.40, −1.00, −1.60, +0.20**. Three bases improve and two worsen. All title times are observed here, so censoring does not drive the advantage. Source: `codex-value/base_contrasts.tsv: restricted_time_delta_mean`, `careers.tsv`; with only five seed groups and an adaptive design, evidence for a general advantage is still limited.
- Value still displaces budget: development-first versus nonbuyer spends **-4.524** CC/season on sessions, **-6.712** on ceiling raises and **-4.344** on signing. The modest grade benefit plus cheaper gear offsets that loss in this cohort. Source: `codex-value/paired.tsv: session_cc_delta,ceiling_raise_cc_delta,signing_cc_delta` (divide each career's 20-season delta by 20).

**Sensible policy:** develops first, buys for current starters aged ≤30, stops at Hardened, hires at most a three-star armorer, and reserves increased future wages. It made **777** successful upgrades across **25/25** careers, so it genuinely buys. This is a policy check of value, not a ninth mechanics variant. [SENSIBLE-PLAN.md](SENSIBLE-PLAN.md), [sensible-policy.patch](sensible-policy.patch), and [probe_harness_budget_sensible.gd](probe_harness_budget_sensible.gd) retain its exact implementation. Source for counts: `codex-value-sensible/metadata.json: checks[].counts.harness_upgrade.completed`.

## Validation, limits and next step

Eight unchanged-primary-probe sweeps used `-- 5 20`, bases **9001 5150 2718 6060 8123**, seed `base+i*7919`; the additive four-arm check repeats those inputs. All **700 career runs / 14,000 closed seasons** finished with `validation_passed=true`; independent replay reconciled **6,010,921** ledger rows and **915,748** transactions, cash, XP, source hashes, censor flags and paired summaries. These include 75 deliberately repeated careers, not 700 independent samples. Each raw folder contains `validation.json` and a SHA-256 manifest is saved alongside this report.

The quartermaster suite passes **19/20** checks for wear/economy/grade/gentle/value; its only failure is Pete's overridden no-nerf assertion. Prices/wages/bonus pass **20/20**. The additional all-five-grade fixture passes, including Titanium, actual wear dose and unchanged ability/headroom. Its first unevenness assertion omitted the last step; that test-only mistake was corrected and rerun, with the original error log retained.

The targeted melee fixture retains the Rust C6 relationships. With Titanium on the weaker club, at a 12-point raw-stat deficit it wins **9/48** on each of seed bases **30000/61000**; at 16 points it wins **2/48** and **0/47 decided** (one undecided), both below C6's 40% limit. This shows the roster still wins over the bonus in those fixtures; it does not establish the whole gate. Source: [grade-quality-stdout.txt](grade-quality-stdout.txt), `CELL.result`, and the retained quality tool. C1–C6 and engaged pacing near 10.4 remain required; C1/C4/C5 code is unchanged, and camera/readability need rendered checks. The full Windows gate was **not** run or claimed. Claude must run the selected balance tier and gate.

Engine: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`; actual `--version`: **4.6.2.stable.official.71f334935**. Headless, workspace APPDATA. Some successful runs emitted existing shutdown ObjectDB/two-resource warnings; those logs are retained.

The careers use aggregate-power quick bouts, oracle recruitment and automatic frequent repairs; they cannot measure human shopping, repair effort, thumb play, or actual forfeits. The ledger omits the pre-fielding lineup/emergency outcome. Zero recorded zero-power states and inspection crossings is not proof that none occurred transiently. The earlier 27367d2 control is retained unchanged; intervening source changes are screen/layout only, while career mechanics, manager and probe match.

**One next measurement:** freeze value, run the same primary probe for 5×20 careers on five untouched bases **17011 29033 43049 67061 91081**, then repeat the sensible tool on those bases. Use fresh output directories and the same engine; retain source hashes, title/censor records and ledger reconciliation. Decide on the held-out paired title deltas and attainment, not re-tune on this cohort. This tests whether the modest benefit survives fresh career paths.

**Pete's design question:** should Titanium be affordable equipment for regular starters, or a late-career luxury? Value substantially reverses the previous price increase. Numbers can support the first-title criterion; they cannot choose that meaning for the shop.

**For Claude:** compare the same paired title/CC definitions when both reports unseal. If Pete chooses a stat benefit, expose it separately from raw ability/growth ceiling in the card and retain glossary/text-fit checks; the prototype changes calculation, not its explanation.
