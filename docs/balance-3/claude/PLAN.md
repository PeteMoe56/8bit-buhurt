# Balance #3 — Claude's plan (written 9 Oct 2026, 01:01 US Central, before any result)

Base: main 95cd1d1 + REGISTER 31.05 (fought-line fix; no effect on simmed careers).
Instrument: tools/probe_harness_budget.gd (engaged player, report-faithful LOW; arms
no_harness = engaged non-buyer N, development_first = engaged buyer D), unchanged.

## Stage 1 — screen (one lever at a time, low and high)
3 careers per base, default bases 9001 5150 2718 6060 8123, 20 seasons. Metrics per arm:
capped wait to first National title, titles/15, income CC/season, bank after seasons
5/10/20, relegations per career. Effect = variant minus the same-size baseline.

| id | lever | low | base | high |
|---|---|---|---|---|
| L1 | Career.LEVEL_XP | 6 | 8 | 11 |
| L2 | Career.XP_BOUT | 1 | 2 | 4 |
| L3 | Career.RAISE_COST_PER | 2 | 4 | 6 |
| L4 | Career.POINTS_PER_LEVEL | 2 | 3 | 4 |
| L5 | Season.CREDITS_WIN | 1 | 2 | 4 |
| L6 | Season.CREDITS_PROMOTED | 2 | 4 | 10 |
| L7 | Season.PURSE_TOP | 3 | 6 | 10 |
| L8 | LeagueWorld.RATING_SCALE | 16 | 22 | 30 |
| L9 | SeasonCups.CUP_TIE_SHARE | 0.03 | 0.06 | 0.12 |
| L10 | ClubEvent.GATE_K | 0.10 | 0.16 | 0.24 |
| L11 | Arena.GATE_PER_LEVEL | 0.20 | 0.35 | 0.50 |
| L12 | Career.DECLINE_RATE | 0.20 | 0.30 | 0.45 |
| L13 | Career.PRACTICE_PER_GRADE | 1.6 | 2.6 | 3.6 |
| L14 | ClubOffice.SESSION_SHARE | 0.06 | 0.12 | 0.20 |

## Stage 2 — combine
Levers whose screen moves N wait by >= 0.6 seasons or the season-10 bank by >= 25%
go into a combination round (2-level fractional factorial over at most 6 levers).

## Pass marks (decided now)
- Engaged non-buyer N: first title 9.5–11.0 seasons; 15/15 (stage 1) or 25/25 titles.
- Buyer D no slower than N (Harness #2 must survive).
- Bank never balloons: season-10 mean bank under 3x season-10 income; never starves:
  season-5 mean bank >= 10 CC.
- Relegations per career no higher than baseline + 0.3.
- Final candidate: 5 careers/base on default AND held-out (17011 29033 43049 67061 91081),
  then the passive player (career_score, RB_LV=auto) and the full gate. No fresh-seed
  confirmation of my own: Codex holds the next fresh set.

## Stage 2 — logged 02:55 after the screen
Excluded on Pete's standing ruling (31.02 pacing): L1 LEVEL_XP, L4 POINTS_PER_LEVEL.
No effect in simmed careers: L2 XP_BOUT (simmed bouts use Season.XP_SIMMED), L10 ClubEvent.GATE_K (the manager runs no shows).
Combination: 2^(6-2) fractional factorial (E=ABC, F=BCD), 3 careers/base, default bases:
A CREDITS_WIN 2→4, B PURSE_TOP 6→10, C RATING_SCALE 22→30, D GATE_PER_LEVEL 0.35→0.50,
E DECLINE_RATE 0.30→0.20, F PRACTICE_PER_GRADE 2.6→3.6. Pick: lowest relegations with N wait
9.5–11.0, D no slower than N, bank10 under 3x income.

## Stage 2 result and stage 3 — logged 03:40
13 of 15 combos in (FABCE lost to a full disk, FABCDEF never started; both rerunning).
Pre-registered pick: **FBCDF** (PURSE_TOP 10, RATING_SCALE 30, GATE_PER_LEVEL 0.50,
PRACTICE_PER_GRADE 3.6): N 9.80, D-N -0.67, relegations 0.40 (base 0.67), bank10 91 vs income 358.
Main effects (approx.): PURSE_TOP -0.78 wait/-0.14 releg; PRACTICE -0.82/-0.14; RATING_SCALE 30
+1.23/+0.19 (a pace brake that costs relegations).
Added now: **K2** = PURSE_TOP 10 + PRACTICE_PER_GRADE 3.6 + LEVEL_XP 8→9 (the pacing knob
re-trimmed instead of RATING_SCALE). Both FBCDF and K2 at 5 careers/base on default and held-out.

## Stage 3 results — logged 04:06 (5 careers/base; baseline = codex-r2-sponsor, same code for sims)
| set | baseline N/H/D, releg | K1 (FBCDF) | K2 (B+F+LEVEL_XP 9) |
|---|---|---|---|
| default | 10.88/10.28/10.28, 0.72 | 9.76/9.12/9.44, 0.56 | 9.40/8.96/9.16, 0.48 |
| held-out | 10.40/10.16/9.76, 0.64 | 9.16/8.68/8.80, 0.60 | 9.32/9.24/9.52, 0.48 |
K1 fails pacing on held-out (9.16) and barely moves relegations there. K2 cuts relegations on both
sets by a quarter-plus but runs fast (9.3-9.4) and its held-out buyer D is 0.2 behind N (noise-level).
Both fail a pre-set mark, so neither is a recommendation yet. Added: **K3** = B+F+LEVEL_XP 10, both
sets. The held-out set is now a tuning input, so any K3 result needs a fresh set before it can be called confirmed.
