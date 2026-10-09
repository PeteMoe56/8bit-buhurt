# Harness budget — Codex verdict

8 October 2026, US Central; fixed game snapshot **27367d2**, including REGISTER
31.01–31.02. **Putting harness purchases after development recovers some
training spending, but does not rescue this manager's championship progression.**
Both purchasing arms have longer capped waits than no-harness in every seed pair.

The experiment completed **75 careers**, **25 per arm**, on **five bases**, each
observed for **20 seasons**. “Capped wait” is mean `min(first-title season, 20)`:
a censored career contributes the observation limit, not an invented victory.

| Arm | Titles by season 20 | Right-censored | Mean capped wait |
|---|---:|---:|---:|
| No discretionary harness | 25/25 | 0 | 10.88 |
| Harness first | 7/25 | 18 | 19.36 |
| Development first | 5/25 | 20 | 18.60 |

Source: `full/careers.tsv`, `arm`, `window`, `first_title_season`,
`right_censored`; counts cross-check `full/attainment.tsv`.

Against no-harness, paired capped-wait penalties are **+8.48** and **+7.72 seasons**.
Among pairs with both titles actually observed, the delays are **+7.14 (7 pairs)**
and **+3.20 (5 pairs)**; these selected subsets exclude the hardest failures.
Development-first minus harness-first is **−0.76 capped seasons**, but has fewer
winners and mixed base effects (**−3.0 to +1.8**). Only **one** pair has both
purchasing-arm titles observed; its actual delta is **−2 seasons**. That is
insufficient evidence of a dependable ordering winner.
Sources: `full/paired.tsv`, title/censor columns; `full/base_contrasts.tsv`,
`restricted_time_delta_mean`. Calculations: `full/analysis.json`, `contrasts`.

**Budget displacement — mean CC per closed season, over the same complete window:**

| Category | No harness | Harness first | Development first |
|---|---:|---:|---:|
| Paid sessions | 88.83 | 32.46 | 45.07 |
| Ceiling raises | 72.54 | 21.20 | 37.11 |
| Signing fees | 22.59 | 0.85 | 1.36 |
| Armorer hiring fees | 0.00 | 1.58 | 1.58 |
| Recurring armorer wages | 0.00 | 12.90 | 12.92 |
| Harness upgrades | 0.00 | 38.50 | 18.51 |
| Repairs | 0.00 | 0.00 | 0.00 |
| Total income | 309.64 | 182.46 | 194.29 |

Costs: `full/metadata.json`, `checks[].costs_cc`, summed by arm and divided by
**500 closed seasons**. Income: `full/seasons.tsv.cc_in`, same denominator.
Transaction categories are independently reconciled in `full/validation.json`.

Reordering recovers **12.61 CC/season** for sessions and **15.92** for ceilings,
while cutting upgrades by **20.00**, versus harness-first. Signing spend still
remains **21.24 below** no-harness. These are whole-career consequences, including
promotion/income feedback, not transfers from an identical fixed purse.
Source: `full/analysis.json.contrasts`, `cc_delta_per_season`.

**Confidence and limits:** all career cash/XP ledgers, all **1,500** closed-year
balances and snapshot hashes pass independent checks. The **two** positive
veteran cash-in rows also reconcile XP/levels with received CC.
Source: `full/validation.json`. The harness penalty points the same way in all
five bases; the ordering comparison does not. Seasons are not independent samples.
This tests oracle recruitment, manual LOW, report-faithful spending and aggregate
quick-sim bouts. It cannot value harness protection in thumbed melee, represent
tester purchasing habits, identify which equipment/wage price causes the loss,
or tell when censored careers eventually win. Prices are unchanged between arms;
the result supports diagnosing this purchasing policy, not selecting a new price.
