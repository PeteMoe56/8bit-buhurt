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
