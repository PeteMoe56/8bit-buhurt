# Harness-budget probe: Codex handoff

8 October 2026, US Central. Built and dry-run at local `d8cf2d5` on main, which
contains Claude's `RB_LV_REPORT=1` manager policy. No game code or `manager.gd`
edited; no commit or push. Claude's sealed screen score was not read.

## Delivered

- `tools/probe_harness_budget.gd`: three paired arms, five default bases
  `9001 5150 2718 6060 8123`, seeds `base + i * 7919`, manual LOW with
  report-triggered active-eight eligibility and whole-roster spending.
- `dry-9001/`: one seed, two seasons, all three arms. **Diagnostic only, before
  the approved CPU-payment, kit/ceiling and title-counter repairs.** These files
  support checking the instrument; they do not support balance conclusions.
- `validation.json`: independent money, XP, source, coverage and pairing checks.
  `validate_ledger.py` reproduces them against this exact dry-run snapshot.
- `dry-stdout.txt` and `dry-engine.log`: the engine output, including warnings.

Arms are `no_harness`, `harness_first`, `development_first`. The first keeps
ordinary repairs and the default armorer; it disables discretionary hiring and
harness upgrades. The second preserves the current highest-affordable-star,
worst-grade-first, one-rung purchase policy before sessions/ceiling raises. The
third attempts that same policy after development purchases. All retain the
same reserve, recruitment/facility policies, fixture handling, costs and
starting resources. Realized signings, facilities and later opponents can
diverge as consequences of those budgets/results. No gifted CC, XP or stats.

The shared manager provides winter, market, captain selection, stat allocation
and report-run behavior directly through inheritance. Its weekly method has no
ordering hook: the probe pins and copies that method, extracts its harness block
and changes its position for the third arm. A changed manager hash refuses to
run until this copy is reviewed. Hashing normalizes Windows/Linux line endings.
The dry run compares both original arms with the unmodified manager over the
same seed/window, using the whole `SaveGame.to_dict` payload except the
wall-clock `saved` timestamp. **Both comparisons pass.**

## Checks and limits

Godot exited 0. All three career ledgers reconcile cash and XP; all six closed
season rows reconcile with the game's books. Every money action's before/after
balance reconciles with the transactions inside its recorded sequence interval.
The independent validator also checks the three paired rows and attainment
table against raw career records. The final snapshot hashes match the run.

Two separate button checks call a paid session and an affordable ceiling raise
from fresh, normal 8-CC starting clubs. Each succeeds once and rejects its repeat;
both calls are logged accurately. These are instrument checks, outside the
career arms, with no resource injection and no championship interpretation.

The two-season careers never pass the manager's development budget gate, so
they do **not** demonstrate displacement of sessions or ceiling raises. They do
exercise signings, paid armorer hiring/upgrades/wages, repairs, report runs,
league/cup handling and rollover. Cash-in rows are present, but these careers
do not exercise a positive veteran cash-in. Full-run uncertainty remains.

These remain aggregate-power quick-sim careers with oracle recruitment, the
ordinary non-youth manager and fixed manual LOW allocation. Report timing is
faithful to the engaged-player route; this does not measure thumbed combat,
actual player's purchases, specialist melee effects or the average tester.

Independent XP conservation exposed a missing source during construction:
dilemmas can award XP between bouts. The final probe traces dilemmas and other
blocking decisions as well as bouts/sessions. The final ledgers conserve XP.

Runner: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`.
Actual `--version`: `4.6.2.stable.official.71f334935`.
The run uses workspace-local APPDATA and an explicit log. It still reports a
certificate-store error and shutdown ObjectDB/resource warnings. Exit 0 and
ledger checks establish this diagnostic's completion, **not** a clean Windows
test gate. No full balance tier or full experiment was run.

## Output schema

- `careers.tsv`: first National-title season, or an empty cell plus
  `right_censored=1`; explicit window, starting/final CC, totals, report runs.
  No missed-window sentinel is presented as an observed victory time.
- `seasons.tsv`: opening CC, closed-year income/outgo, and separate
  pre-/post-rollover bank, power and tier. Rollover belongs to the closing year.
- `paired.tsv`: all three pairwise arm contrasts for each base/seed; title
  difference is empty if either career is censored. Budget category, bank and
  power deltas are treatment minus reference over the same full window.
- `attainment.tsv`: observed titles and censor counts by arm/window.
- `metadata.json`: engine, normalized SHA-256 hashes of all game scripts,
  manager, probe and project configuration; per-career action counts and CC
  categories; diagnostic/validation flags. Sources are checked between careers
  and at completion; any change invalidates a partial run.
- `<arm>-<seed>.jsonl`: ordered transactions, calls, skipped budget decisions,
  report triggers, level spending, cash-in and roster/rollover boundaries.
  Every record carries arm/base/seed, elapsed season, world season and week.

Use `transaction` rows once for money totals, or metadata `costs_cc`. Nested
action CC deltas are inclusive and must not be added to those transactions.
Attempts mean actual API calls; `decision` rows with `called=false` are reserve
or scheduling refusals. A String-returning action completes only on `""`;
void actions mean the call returned, not necessarily that a fixture was played.
Armorer fees, recurring wages, harness upgrades and repairs are separate CC
categories; the wage record also preserves due/paid amounts and armorer change.

`xp_earned` is exclusive of nested earning calls. Arriving/departing fighters'
XP is stock entering/leaving the club, recorded separately. `level_spend` rows
give XP consumed, levels and retained men's raw stat delta; `cash_in` records
the separate XP/levels converted into actual received CC. Winter training has
its own roster/stat changes and the game's gained/lost report. Do not sum
nested raw stat deltas and call them total development. Fighter IDs are stable
within a career, not a promise of identical recruits across different arms.

## Next run, after the game fixes

From the verified headless runner, use:

```text
--script res://tools/probe_harness_budget.gd -- 5 20 --out=res://docs/bakeoff-2/harness/post-fix
```

This runs all five bases (75 careers). Supplying `5 20 BASE` runs one base.
The tool refuses an existing output directory. Do not compare this pre-fix dry
run with post-fix careers as a purchase-order effect. Review the manager pin if
Claude has changed that file; run all arms on one fixed post-fix snapshot.

Idea for Claude: reuse the independent XP conservation check in future flow
probes so story awards and roster turnover cannot silently disappear.
Question for Claude, via Pete: can you independently confirm the positive
cash-in boundary on the post-fix snapshot before interpreting the full sweep?
