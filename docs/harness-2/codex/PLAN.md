# Codex Harness #2 plan, fixed before measurements

8 October 2026, 15:36:02 US Central (clock: 20:36:02 UTC).
Base: 7c79a7f3522529a06a503b6b07e69236b08ad937. Four detached worktrees.
No Claude outputs or claude-* results read. Primary probe and manager unchanged.

Grades below are Rust, Mild, Hardened, Stainless, Titanium, in that order.

1. **wear** — isolate durability.
   `scripts/league/quartermaster.gd: WEAR [1.00,0.86,0.72,0.58,0.50] → [1.30,0.95,0.55,0.30,0.12]`.
   Prices, repair rules, TOP and grade rating remain unchanged. Tests whether
   longevity alone can repay today's purchase and wage burden. Rust above 1.00
   intentionally contradicts the superseded no-nerf assertion under Pete's ruling.
2. **economy** — wear variant plus one expense family.
   `scripts/league/quartermaster.gd: COST [6,14,28,48] → [3,6,10,18]`.
   `scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,2,3,5]`.
   Upfront fees follow wages through the existing API. Reduces annual staff drag
   and the cost of replacing kit on new recruits without removing either bill.
3. **grade** — economy variant plus a modest on-field material benefit.
   `scripts/melee/fighter_card.gd: HARNESS_BASE_BONUS absent → [0.00,0.02,0.05,0.09,0.12]`.
   `effective_base base*condition_factor → min(99,base*(1+grade_bonus)*condition_factor)`.
   Full Titanium adds at most roughly 2.5 weighted rating points; ability() and
   all XP/ceiling rules remain raw-stat based. Rust's direct multiplier remains 1.
4. **gentle** — grade variant, but Rust durability nearly preserves the old baseline.
   `scripts/league/quartermaster.gd: WEAR [1.00,0.86,0.72,0.58,0.50] → [1.05,0.90,0.48,0.28,0.10]`.
   Tests whether purchases can earn their keep without a large nonbuyer penalty.

All wear ladders strictly improve by uneven steps. No XP, income, inspection,
repair, fixture, recruitment or manager changes. No gifted resources or fourth arm.

Measure all four with the unchanged primary probe, 5 seeds/base, 20 seasons,
five default bases, three original arms. Record censoring and full-window CC.
Reconcile raw cash/XP, inspect below-inspection crossings and zero-power states.
Report that boundary observations do not prove actual forfeits the probe does
not log. Run the quartermaster checks and relevant constraint diagnostics; do
not call them the full Windows gate. Never select by title mean alone: preserve
nonbuyer pacing and attainment, C1–C6, and the engaged-player ~10.4-season target.

The previous 27367d2 control (10.88,19.36,18.60 capped means) is usable only after
confirming no intervening career-mechanics change. UI-only changes are excluded
from that claim, and all new variant hashes are retained.
