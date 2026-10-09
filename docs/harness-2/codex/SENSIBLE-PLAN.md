# Sensible-buyer policy check of value (same game variant)

8 October 2026, 16:00:44 US Central (clock: 21:00:44 UTC), before this run.

Pete expressly allows an additional buyer arm. The original policy always hires
the best eligible specialist it can afford and climbs all metals on starters;
that is an eager-shopper test, not a sufficient definition of sensible buying.

Use exactly value's game patch, not a ninth mechanics variant. Add a fourth
policy through a separate tool, tools/probe_harness_budget_sensible.gd; leave
tools/probe_harness_budget.gd and tools/manager.gd untouched. Preserve all three
original arms and run all four for 5 seeds across each default base, 20 seasons.
Output codex-value-sensible. Check that the repeated original arms match value.

The fourth arm follows development_first's sequence, then equips only the
current starting five aged at most 30, and stops each man at Hardened. Hire
at most a three-star armorer, preserve the original reserve plus any increase
in future annual wages, and recompute the reserve after hiring. Lowest grade
first, younger first on ties, one upgrade attempt per fixture week. No condition
gate that would accidentally buy nothing, no hidden-ceiling use beyond the shared
manager, no gifted resources, no extra repairs, no changed roster/level policy.

This policy uses visible age and grades and accepts lower maximum kit quality
to protect development. It is a testable stand-in, not an optimal buyer search.
Report its actual purchase count; a no-purchase arm cannot satisfy worth buying.
Age 30 and Hardened are policy choices only, not proposed game constants.
