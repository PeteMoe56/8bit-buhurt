# Difficulty #1: finding the right difficulty scaling (handoff to Codex, 9 Oct 2026, US Central)

**For:** Codex, on Pete's PC. **From:** Claude. Same rules as every round (scratch copy only, no
changes to main, no commits or pushes, plan written with the clock time before any result, US
Central times, Claude lands and translates).

## Pete's ask (9 Oct 2026)

> "I like the idea of Skipping fights being lower percentage, it pushes the player toward actually
> fighting. … I think we'll need you and Codex to find the proper difficulty scaling. Normal mode
> should be that 10-12 seasons range. Do we have a completion hours estimate on those as well?
> Plus, we need those 'Custom settings' gauges to be meaningful with it's settings (being able to
> make it easier than easiest and harder than hardest)."

Pete also ruled that the strong Worlds team that appears after your first Worlds title **stays as
tuned**: losing more often when you skip fights is intended.

## What "right" means (proposed; Pete can change it)

Measured on the player who **fights his own bouts** (your good-thumb script), first Worlds title:

| Difficulty | Target | Today (your Endgame #1 runs) |
|---|---|---|
| Friendly | 8–9 seasons | 10.64 fought on auto / 9.44 skipped |
| **Sanctioned (Normal)** | **10–12 seasons** | 10.68 / 10.56 good-thumb ✔ |
| Full Steel | 13–15 seasons | 14.04 fought on auto |
| Hard List | 16–18 seasons, and still won by most careers in 20 | 15.32 fought on auto, 21/25 won |
| Matched | adapts to the player; report where it lands | 14.04 fought on auto, 23/25 won |
| Custom, every dial at its easiest | clearly faster than Friendly | not measured |
| Custom, every dial at its hardest | clearly slower than Hard List | not measured |

Skipping fights should stay slower than fighting on every difficulty (Pete's ruling).

## The work split

| Codex | Claude |
|---|---|
| **D1. Every preset in fought careers**: Friendly, Sanctioned, Full Steel, Hard List and Matched, with the good-thumb script and on auto, tune and check seeds, 25 careers each. This is the ladder above, measured. | **D5. The money and injury dials in simulated careers** (strength, bills, knocks): how many seasons each one moves the first Worlds title, step by step across its whole range. |
| **D2. Each fight-only dial, one at a time** (pauses, corner time, free swing, bullrush fall, trip/grab on the pass, bullrush read): how much each one moves the fought win rate and the first-title season, low to high. These dials do nothing when a fight is skipped, so only real fights can measure them. | **D6. New dial ranges** so every dial reaches past both ends of the presets (today "read" stops at Friendly's value and "swing" stops at Hard List's), and a test that each dial always moves difficulty the same way. |
| **D3. Time to play**: real seconds per fought bout (fight, corners, screens), bouts per season, and so hours per season and hours to a first Worlds title, on each difficulty, fighting and skipping. | **D7. The gauges**: each Custom dial shows what it does in plain words, plus an overall estimate ("about 12 seasons to a first Worlds title"), built from D2 and D5. |
| **D4. Custom at both extremes in fought careers**: every dial at its easiest, and every dial at its hardest, with the new D6 ranges. | **D8. Tune the presets** to the targets from D1–D5, then one confirmation run on fresh seeds, the full test gate, and landing. |

Order: D1 and D3 first (they answer Pete's two questions), then D2 and D4. Claude does D5 and D6
now, and D7 and D8 once your numbers are in.

## Seeds

Tune 9001 5150 2718 6060 8123, check 17011 29033 43049 67061 91081, five careers a base. Fresh set
for your final check: **1210003 1250017 1290001 1330021 1370011**. Do not use any earlier fresh set.

## Base

Main at `84ceeea` plus the agreed changes: 4 stat points per level, cup fights pay XP like league
fights, same-pool teams kept apart until the final, and the strong Worlds team after your first
Worlds title (`docs/endgame-1/step1-candidate.patch` gives all four). Plus your real-fight testing
tool from Endgame #1.

## Deliverable

`docs/difficulty-1/codex/REPORT.md`: D1–D4 with every number per difficulty, per seed base and per
player type; seconds per bout and hours per season; a list of any dial that moves the wrong way or
does nothing; and questions only Pete can answer. Plain words in the report; no code names.
