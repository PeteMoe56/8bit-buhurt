# Difficulty #1: Claude's plan (09 Oct 2026, 19:30 US Central, before any result)

Split and targets: [HANDOFF-CODEX.md](HANDOFF-CODEX.md). My half: D5 (money and injury dials and
the strength dial in simulated careers, whole range, step by step), D6 (dial ranges past both
preset ends, and a test that every dial moves difficulty one way only), D7 (gauges with plain
words and a seasons estimate), D8 (preset tuning, fresh confirmation 1410013 1450007 1490021
1530011 1570003, full gate, landing).
Marks: Normal 10–12 seasons for a fighting player; each dial monotonic; Custom extremes beyond the
easiest and hardest presets; skipping slower than fighting on every difficulty.

## D5 design (19:58 CT, before any result)
Skipped-fight careers (`probe_harness_budget`, three engaged arms, 3 careers a base on the tune
set = 45 careers a variant, 20 seasons) on main + the step-1 changes, with the Custom difficulty
set as the default and one dial moved at a time from Sanctioned's values:
- opponent strength 0.90 0.94 0.96 0.98 1.00 1.02 1.04 1.06 1.08 1.10
- bills 0.5 0.8 1.2 1.5 · training injuries 0.2 1.0 · the Hard List ceiling rule on
Measured: first Worlds title (non-winners counted as 20) and Worlds winners, bank, relegations.
This is the "seasons per step" table the gauges will use; Codex's real-fight runs give the same
for fighting players. Each dial must move pacing one way only (checked on the full range).

## Creative idea: Federation Sanctions (20:16 CT, before any result)
Optional handicaps taken at the start of a season for bigger rewards. Prototype: each sanction
makes opponents 2% stronger (one strength-dial step) and pays 25% more prize and tournament
money. Measurement stand-in for the player's choice: take N every season from the season after
the first Worlds title (N = 1, 2, 3), and N = 1 from the first season. Same tune set and size as
D5, compared with the control. Questions: what each sanction costs in Worlds titles, what it
pays in CC, and whether money can be the reward at all once banks run 200+ CC late in a career.

## Addition (21:10 CT, after the one-dial results, before these)
Do the dials add up? Skipped-fight runs of the Friendly, Full Steel and Hard List presets and of
Custom at all-easiest and all-hardest (the table in custom-dial-ranges.md), same size as D5. The
sum of the one-dial effects predicts: Friendly 9.2, Full Steel 12.6, Hard List 13.4; all-easiest
about 7.6; all-hardest beyond 18 (many careers never win). If the sums miss by more than 0.6 of a
season, the estimate on the Custom screen needs a combined model instead of a sum.

## Skip handicap (21:18 CT, before any result)
Pete, 21:18: skipping should add "about 3-4 seasons onto it if you're habitual with it".
Mechanism: opponents x SKIP_HANDICAP in skipped bouts only (league skip and skipped cup ties);
fought bouts untouched. Chosen 1.07 from the strength sweep (skipper at Normal: 1.06 → 13.33,
1.08 → 14.09; Codex's fighting Normal 10.24 / 10.68). Marks: habitual skipper 3-4 seasons slower
than Codex's fighting player on each preset where both exist; most careers still win a Worlds.
Runs: Friendly, Normal, Full Steel x tune and check, 3 careers a base, all bouts skipped.
