# Fifth variant, fixed before its run

8 October 2026, 15:53:17 US Central (clock: 20:53:17 UTC).

This is an adaptive fifth test after all four original sweeps finished, not part
of the original frozen four. None of Claude's results or plan was read.

Observed: gentle's harness-first arm attained 25/25 titles but waited 12.28
seasons against no_harness 10.88; development_first attained 23/25 and waited
13.64. Both still displaced development spending. Lifetime kit cost averaged
657.20 and 633.84 CC per career respectively. Durability-only failed to cure
the penalty, whereas reducing costs improved attainment substantially.

**value** keeps gentle's wear, ceilings, repair rules and material benefit. It
only reduces the expense family further:

- scripts/league/quartermaster.gd: COST [6,14,28,48] → [1,2,4,7].
- scripts/league/armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3].

All upgrade and higher-armorer bills remain positive. The two early specialists
share a wage, while the last two still charge more. This tests whether a modest
combat benefit can repay affordable metal, rather than increasing that benefit
or penalizing Rust harder. Original primary probe, three arms, five default
bases, 5 seeds/base, 20 seasons; no new resources or changed manager.

An arm must be compared to its own no_harness control. If buying still delays
titles, report that failure explicitly; do not call the shop fixed just because
its penalty shrank. Price reductions undo Pete's earlier price increase only
in this experiment; Pete still chooses any landing.
