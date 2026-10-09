# Harness #2 — fresh-seed confirmation

8 October 2026, 21:49:39 US Central, from the clock. Tested **main as it stood at fae6fba7954f6e968a1df85943c6b0e2eea32246**, without a pull or patch. No tuning, commits or pushes.

**PASS: both original buyer arms are no slower than never buys on the predeclared fresh set.** Harness first is -1.00 seasons and development first -1.08 versus never buys. The sensible arm is supplementary, not part of the pass rule. That rule was frozen before results in `work-confirm/PLAN.md`.

| Arm | Mean capped wait | Buyer minus never | National titles | Censored |
|---|---:|---:|---:|---:|
| Never buys | 11.44 | +0.00 | 25/25 | 0 |
| Harness first | 10.44 | -1.00 | 25/25 | 0 |
| Development first | 10.36 | -1.08 | 25/25 | 0 |
| Sensible buyer | 10.24 | -1.20 | 25/25 | 0 |

Wait = mean `min(first National title season,20)`; a censored career contributes 20, not an invented title. Five careers per base; seed = base + i × 7919, i = 0…4. All careers continue for 20 seasons. Source: `docs/bakeoff-2/harness/codex-confirm/careers.tsv`, columns `arm,base,seed,first_title_season,right_censored`; sensible results use the same columns in `codex-confirm-sensible/careers.tsv`. Title counts cross-check `attainment.tsv: titles_observed,right_censored` in each folder.

Paired **buyer minus never** mean seasons within each base; negative is faster:

| Base | Harness first | Development first | Sensible buyer |
|---|---:|---:|---:|
| 110017 | -0.40 | -0.40 | -0.80 |
| 130021 | -2.00 | -1.60 | -1.80 |
| 150041 | -1.00 | -1.80 | -1.20 |
| 170047 | -2.00 | -2.00 | -1.80 |
| 190027 | +0.40 | +0.40 | -0.40 |

Source: each folder's `base_contrasts.tsv: reference,treatment,base,restricted_time_delta_mean`, independently derived from seed-matched careers. The mean-set pass does not imply every base or career wins.

Never buys waits **11.44**, +0.56 versus the earlier default-set **10.88** (`REPORT-R2.md`, sponsor/default). That is a different-seed comparison, not evidence of a mechanical nonbuyer penalty. The new never-buys journals record zero sponsorship and zero discretionary harness purchases (`codex-confirm/analysis.json: arms.no_harness.ledger_metrics_total.harness_sponsorship_cc,cost_per_season.harness_upgrade`). No same-fresh-seed pre-sponsor counterfactual was run.

**Landed-source audit.** The preserved scratch files reproduce `r2-sponsor.patch` exactly. Main retains its rates, rounding/carry/save logic, prices, wages, wear, grade bonus, raw growth ceilings, payment timing and forfeit exclusion. `sponsor_rate` extracts the identical calculation; `LINE_SPONSOR`, translations, ordered books and the Maintenance estimate change presentation/accounting labels, not cash or career rules. Full comparison: `work-confirm/landed-versus-r2-sponsor.diff`; source pins: `work-confirm/source-pins.json`.

**Cup caveat:** “same five paid and worn” is not guaranteed for fought cups: `SeasonCups._finish_cup_round` pays first, then `post_cup_bout` applies injuries/resting and calls `bout_wear` on a newly selected line (`scripts/league/season_cups.gd:200–208,254–257`). Quick cup ties pay but do not call bout wear (`sim_cup_tie`). Both were already in my tested patch; neither is a landing regression. League payout and wear use consecutive starting-five selections without intervening substitutions.

**Checks and limits.** Unchanged primary probe on main: `75` careers, `1500` seasons; existing sensible probe copied unchanged into `tools/` in a detached fae6fba worktree: `100` careers, `2000` seasons. Both built-in validations and independent money/closed-books/XP/source-hash reconciliation pass. All **75** repeated original-arm journals are byte-identical between probes (`work-confirm/journal-parity.json`); those repeats are not additional independent evidence. The sensible policy develops first, reserves upkeep, targets starters age ≤30 through Hardened and caps armorer hiring at three stars. These are quick-result careers with report-triggered level spending and the shared manager's oracle knowledge of hidden ceilings (`tools/manager.gd: reading`). They do not establish live-player behaviour or real-melee injury/payout attribution. Claude reports the full gate/balance tier green; this confirmation did not repeat that gate.

Engine: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`; actual `--version`: **4.6.2.stable.official.71f334935**. Both sweeps exit 0; logs retain exit leak/resource warnings, and main also reports a certificate-store error. No probe validation or script failure. Logs are under `work-confirm/logs/`.

Raw journals left where generated: primary under `C:\Dev\RetroBuhurt\docs\bakeoff-2\harness\codex-confirm`; sensible under `C:\Users\PeterM\Documents\Codex\work\harness-confirm-sensible\docs\bakeoff-2\harness\codex-confirm-sensible`. Only sensible derived tables/metadata/validation were copied into main's `codex-confirm-sensible/`.

For Claude: add an injured fought-cup fixture recording the IDs paid and worn before changing that ordering. Design question for Pete: should sponsorship follow actual participants or the replacement line used by current wear? No change is proposed or applied on this confirmation set.
