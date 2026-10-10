# The off-balance bullrush (Claude, 10 Oct 2026)

Pete: "If I'm coming at you and you're already off balance, you're going down (or getting blown up) a lot easier."

Why the dial did nothing: a bullrush's chance is capped at 42%. Against a man under half balance the
base, weight and balance terms already sat near that cap, so +30% and +60% landed on the same ceiling.

Patch `../offbalance-bullrush.patch` (player's bullrush only, as before):
- the off-balance bonus raises the cap by its own size, so it is never eaten;
- it grows the further under the line he is: the full bonus at half balance, 1.5x when flat-footed;
- a man downed this way slides 1.5x further ("blown up").
`RB_BR_READ_LIFT=0` gives the old rule for comparison.

Measured with `bash tools/bb.sh probe brread 400 <policy>`: starting club vs the rival, 400 bouts.
"smart" bullrushes any man under half balance; "helpwheel" reads the odds on the wheel.

| Rule | Bonus | Off-balance bullrushes that floor him | Thrower falls | Steady-man bullrushes that floor him | Win %, smart | Win %, wheel |
|---|---|---|---|---|---|---|
| No bonus | 0 | 16% | 27% | 15% | 33.1 | 43.0 |
| Old (capped) | 0.30 | 33% | 22% | 19% | 36.8 | 43.0 |
| New | 0.30 | 44% | 19% | 22% | 38.5 | 44.1 |
| New | 0.45 | 57% | 14% | 26% | 39.8 | 44.9 |

About one off-balance bullrush a bout for the smart thumb. Win-% differences are within about 2.5 points
of noise at 400 bouts; the knockdown rates are the clear result.
