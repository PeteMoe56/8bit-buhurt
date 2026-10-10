# Custom dial ranges (Claude, 9 Oct 2026)

Patch: `custom-dial-ranges.patch` (applies to main `c34feac`; touches `scripts/melee/grade.gd` and
`tests/test_grade.gd`). Two ranges widen; nothing else changes. A new test checks that every dial
reaches past the easiest and the hardest preset (test_grade: 35/35 pass).

Easier direction: "lower" means a lower number is kinder to the player.

| Dial | What it does | Easier | Friendly · Sanctioned · Full Steel · Hard List | Custom range (step) |
|---|---|---|---|---|
| scale | Opponent strength | lower | 0.96 · 1.00 · 1.04 · 1.04 (+ceiling, cap 1.08) | 0.90 – 1.10 (0.02) |
| pauses | Corner calls, change from base 2 | higher | +1 · 0 · −1 · −1 | −2 – +2 (1) |
| corner | Corner time, seconds added | higher | +4 · 0 · −4 · −4 | −8 – +8 (2) |
| bills | Dues and federation bills | lower | 0.8 · 1.0 · 1.2 · 1.2 | 0.5 – 1.5 (0.1) |
| knocks | Training-injury rate | lower | 0.4 · 0.6 · 1.0 · 1.0 | 0.2 – **1.4** (0.1), was 1.0 |
| swing | Free swing on arrival | higher | 0.75 · 0.5 · 0.25 · 0.0 | 0.0 – 1.0 (0.25) |
| fall | Your failed bullrush puts him down | lower | 0.10 · 0.20 · 0.30 · 0.30 | 0.0 – 0.4 (0.1) |
| pass | A free enemy trips/grabs your runner | lower | 0.08 · 0.12 · 0.16 · 0.16 | 0.0 – 0.24 (0.04) |
| read | Bullrush bonus on a man off balance | higher | 0.40 · 0.30 · 0.20 · 0.10 | 0.0 – **0.6** (0.1), was 0.4 |
| ceiling | Hard List rule: opponents rated off your division's top | off | off · off · off · on | on/off |

The one exception: the free swing's hard end is 0 (Hard List), since there is nothing below no swing.
Harder-than-Hard-List comes from the other dials.
For the Custom-extremes test, "all easiest" = scale 0.90, pauses +2, corner +8, bills 0.5,
knocks 0.2, swing 1.0, fall 0.0, pass 0.0, read 0.6, ceiling off; "all hardest" = scale 1.10,
pauses −2, corner −8, bills 1.5, knocks 1.4, swing 0.0, fall 0.4, pass 0.24, read 0.0, ceiling on.
