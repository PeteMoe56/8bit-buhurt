# Balance #3: Claude's report (9 Oct 2026, 04:20 US Central)

Plan and every addition, timestamped before results: [PLAN.md](PLAN.md). Instrument:
`tools/probe_harness_budget.gd`, unchanged. N is the engaged player who never buys kit,
H buys harness first, D buys kit after development. Main is `c9c79c8`.

## Verdict: no change recommended from my side

The game already meets every target I set. Nothing I found beats it robustly; the
effects worth having are at the noise floor of 25 careers per seed set.

| Target | Today, Codex's seeds / fresh seeds | Mark |
|---|---|---|
| Engaged first title (N) | 10.88 / 10.40 | 9.5–11.0 ✔ |
| Buyers no slower (H, D) | 10.28 / 10.16; 10.28 / 9.76 | ✔ |
| Bank at season 5 / 10 | 41 / 72 CC (income about 310 a season) | ✔ neither balloons nor starves |
| Relegations per career | 0.72 / 0.64 | the one soft spot |

## Stage 1: screen (3 careers per base, 15 per run; noise about ±0.5 seasons)

From [screen.txt](screen.txt):

- **Pacing:** `LEVEL_XP` and `POINTS_PER_LEVEL` each move the first title by 4–5
  seasons, more than every other lever combined. They're Pete's pacing ruling (31.02)
  and were held.
- **Money:** win credits, the finishing prize (`PURSE_TOP`), cup purses
  (`CUP_TIE_SHARE`) and gate per arena level each move income 10–35%. Cup ×2 starts
  a balloon: the season-20 bank reaches 381 against 162.
- **Dead in simulated careers:**
  - `XP_BOUT`: simmed bouts use `Season.XP_SIMMED`.
  - `ClubEvent.GATE_K`: the probe manager never hosts a show.

  These matter only in played fights and to players who host shows, which no probe
  measures.
- **`RATING_SCALE`:** 16 speeds the title to 9.47 seasons but leaves buyers 0.47
  slower, erasing the kit edge. At 30 it brakes pacing and adds relegations (stage 2).

## Stage 2: 2^(6-2) factorial (3 careers per base)

From [factorial.txt](factorial.txt). Approximate main effects:

| Change | First title | Relegations |
|---|---|---|
| Finishing prize 6 → 10 | −0.8 seasons | −0.14 |
| Captain training 2.6 → 3.6 | −0.8 seasons | −0.14 |
| Win credits 2 → 4 | −0.6 seasons | 0 |
| Gate per arena level 0.35 → 0.50 | −0.3 seasons | −0.05 |
| Decline rate 0.30 → 0.20 | 0 | −0.06 |
| `RATING_SCALE` 22 → 30 | **+1.2 seasons** | **+0.19** |

## Stage 3: finalists (5 careers per base, both seed sets)

| Variant | Codex's seeds: N / H / D, relegations | Fresh seeds: N / H / D, relegations | Verdict |
|---|---|---|---|
| Today | 10.88 / 10.28 / 10.28, 0.72 | 10.40 / 10.16 / 9.76, 0.64 | — |
| K1: prize 10, `RATING_SCALE` 30, gate 0.50, training 3.6 | 9.76 / 9.12 / 9.44, 0.56 | 9.16 / 8.68 / 8.80, 0.60 | fails pacing on fresh seeds |
| K2: prize 10, training 3.6, `LEVEL_XP` 9 | 9.40 / 8.96 / 9.16, 0.48 | 9.32 / 9.24 / 9.52, 0.48 | fast; D 0.2 behind N on fresh seeds |
| K3: prize 10, training 3.6, `LEVEL_XP` 10 | 9.36 / 9.68 / 9.60, 0.52 | 10.24 / 9.20 / 9.40, 0.72 | buyers behind on Codex's seeds; no relegation gain on fresh seeds |

K2 and K3 differ only in one point of `LEVEL_XP`, yet K3 came out *faster* on one set
and lost the relegation gain on the other. That's noise, not a mechanism, so I stopped
rather than tune on it.

## For Codex's round and for Pete

1. **The relegation lever worth testing at scale** is finishing prize + captain training
   (0.72 → 0.48 in K2 on both sets). It needs more than 25 careers per set to tell from
   noise, and it pulls pacing faster, so it needs a pacing trim.
2. **The probes are blind to played fights and hosted shows.** XP per bout and own-show
   gate are untested by any career run. A probe that plays the melee for the player's
   bouts would close that gap.
3. **Pete:** a quarter fewer relegations is worth having only if the yo-yo bothers
   players. Do you want the climb to feel steadier, or is a club bouncing between
   divisions part of the story?
