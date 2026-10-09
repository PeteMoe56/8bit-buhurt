# Harness round 2 — frozen initial designs

8 October 2026, 17:10:24 US Central (clock). Base 7c79a7f. Blind is over.

All designs use round 1 value unchanged as a fixed platform: wear [1.05,.90,.48,.28,.10], rung costs [1,2,4,7], wages [0,0,1,1,2,3], existing base bonus [0,.02,.05,.09,.12]. No further price cut or larger base bonus. Round 1 isolated controls remain available. Fresh value control is rerun on both cohorts.

Five additions, each isolated against that platform:

- sponsor: per actual bout, fielded fighters accrue CC at [0,.08,.20,.40,.65] per man times condition; fractional carry persists in saves. Forfeits earn nothing. Real and quick league bouts and cup ties use the same payment helper.
- turnout: traveling fighters add [0,.01,.025,.04,.06] times condition to the existing crowd draw multiplier, respecting its existing cap. No flat gate gift.
- gas: effective gas = min(99,raw gas*(1+[0,.01,.03,.05,.07]*condition)). Rating, club power, melee stamina and overall use it; raw bars, ability and growth ceilings do not. Only the added bonus fades with condition.
- reuse: outgoing paid kit is swapped to the lowest-grade younger (age <=30) remaining fighter, active first, provided its condition is >=.40. Preserve both condition values; no refill, no cash, no duplicate. Applies to successful release, retirement and expired-contract departures, not club splits. Recompute fighter trade value after the swap.
- resale: successful release, retirement or contract departure pays floor(.50*condition*sum of purchased rung costs). Consumes the outgoing kit; no credit for Rust and no refund twice. Does not discount a shop purchase.

The final two slots are reserved for adaptive combinations; any combination uses families already isolated here. No injury variant: quick careers do not generate bout injuries, so the required instrument cannot establish its benefit. Do not duplicate Claude's stronger base-bonus V2.

Run each unchanged primary probe with 5 seeds/base and 20 seasons on default [9001,5150,2718,6060,8123] and held-out [17011,29033,43049,67061,91081]. Held-out is now another evaluation cohort, not untouched confirmation after tuning. Output codex-r2-<variant>/default and /heldout.

Strict pass: BOTH original buyer means <= the nonbuyer mean separately in BOTH sets; report attainment/censoring and all five paired base means. Nonbuyer movement is checked against 10.88 default / 10.40 held-out, tolerance .5. These are measured-cohort passes, not a universal benefit claim. Independent source, cash, XP and journal replay plus focused mechanical fixtures; full gate remains Claude's job.

Only scratch worktrees receive game changes. No main game changes, commits or pushes.

## Instrument audit addition, 17:25:05 US Central (clock)

Before reading any complete career results, add `cupwear`: value plus `scripts/league/season_cups.gd: sim_cup_tie no wear → SeasonBouts.bout_wear(s); s.sync_power()` after result settlement. The fought cup path already does this; the quick cup path does not. This isolates actual wear parity, exercises the existing uneven durability ladder in all cup ties, and may change the nonbuyer; the same .5 tolerance still applies. It is the seventh tested case including control; one slot remains for an adaptive combination. The original five additions remain frozen.

## Last slot, adaptive combination, 17:31:31 US Central (clock)

Default-set independent validation: sponsorship buyers both 10.28 versus 10.88 nonbuyer; gas 10.76/10.40; turnout 10.72/10.84; reuse 10.88/11.04. Held-out results are not read yet. Add `sponsor-gas`, the unchanged sponsorship and gas changes together. No new number or mechanism. This is the eighth case including control and is explicitly adaptive to default results. Prefer a simpler isolated mechanism if it passes both sets; the combination must independently pass both too. Both constituent families have their own two-set tests. No further mechanics variants.
