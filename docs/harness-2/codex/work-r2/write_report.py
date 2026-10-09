from pathlib import Path
from statistics import mean
from collections import Counter
import csv,json,sys
MAIN=Path('C:/Dev/RetroBuhurt')
OUT=MAIN/'docs/harness-2/codex'
NAMES=['control','sponsor','turnout','gas','reuse','resale','cupwear','sponsor-gas']
D=json.loads((OUT/'SUMMARY-R2.json').read_text())
assert all(set(D[n])=={'default','heldout'} for n in NAMES)
stamp=sys.argv[1]
arms=['no_harness','harness_first','development_first']
def fmt(x): return f'{x:.2f}'
def trip(a,key): return ' / '.join(fmt(a['arms'][arm][key]) for arm in arms)
def kit(a,arm): return 20*sum(a['arms'][arm]['cost_per_season'][c] for c in ['harness_upgrade','armorer_hire','armorer_wage','repair'])
def vector(a,arm): return ', '.join(f'{v:+.1f}' for v in a['contrasts'][arm+' minus no_harness']['base_restricted_time_deltas'].values())
lines=[f'# Harness #2 — Codex round 2\n\n8 October 2026, {stamp} US Central, from the clock. Base **7c79a7f3522529a06a503b6b07e69236b08ad937**. Eight cases including the repeated value control; seven additions/combination tests. Main game code, primary probe and manager unchanged; no commits or pushes. Blind is over; Claude’s supplied findings were read, not his V2 outputs.\n',
'## Verdict\n\n<!-- Insert reviewed recommendation here. -->\n',
'The previous recommendation is superseded: value’s default advantage did not generalize. Both buyer arms must be no slower than the nonbuyer **separately in both sets**, with title attainment reported and nonbuyer movement within 0.5 seasons. A pass below is a measured-cohort pass; it is not evidence of a universal benefit. These evaluation sets are now reused design inputs, so neither is a fresh confirmation of the adaptive combination.\n',
'## Title results\n\nN = no harness; H = harness first; D = development first. Wait is mean `min(first National title season,20)`. A never-winner contributes 20, with its censor flag retained. Cells show **wait; observed titles/25**. All careers continue for the full 20-season window.\n']
for cohort in ['default','heldout']:
    bases=[9001,5150,2718,6060,8123] if cohort=='default' else [17011,29033,43049,67061,91081]
    lines += [f'### {cohort}: bases {", ".join(map(str,bases))}\n\n', '| Case | N | H | D | Nonbuyer movement | Set criterion |\n|---|---:|---:|---:|---:|---|\n']
    for n in NAMES:
        a=D[n][cohort]
        cells=[f'{fmt(a["arms"][arm]["restricted_mean_time_20"])}; {a["arms"][arm]["titles"]}/25' for arm in arms]
        lines.append(f'| {n} | '+ ' | '.join(cells)+f' | {a["nonbuyer_reference_shift"]:+.2f} | '+('pass' if a['strict_pass'] else 'fail')+' |\n')
    lines.append('\n')
lines += ['Timing sources: `docs/bakeoff-2/harness/codex-r2-<case>/<set>/careers.tsv`, columns `base,seed,first_title_season,right_censored`; `attainment.tsv: titles_observed,right_censored`. Nonbuyer reference is 10.88 default / 10.40 held-out. Exact summaries and budget values: [RESULTS-R2.tsv](RESULTS-R2.tsv), [SUMMARY-R2.json](SUMMARY-R2.json).\n',
'## Paired per-base spread\n\nEach list is **buyer minus N**, averaged over the five matched seeds in each base, in the base order printed above. Negative means faster. No pooling of the two sets.\n\n| Case | Set | H − N, by base | D − N, by base |\n|---|---|---|---|\n']
for n in NAMES:
    for cohort in ['default','heldout']:
        a=D[n][cohort]
        lines.append(f'| {n} | {cohort} | {vector(a,"harness_first")} | {vector(a,"development_first")} |\n')
lines += ['\nSources: each output’s `base_contrasts.tsv: reference,treatment,base,restricted_time_delta_mean`, derived from the matched career rows. [BASES-R2.tsv](BASES-R2.tsv) combines them. A positive base remains a counterexample even when its set’s mean passes.\n',
'## Income and kit budget\n\nTriples are **N / H / D**. Income is CC per closed season across the full window. Kit is CC per 20-season career: upgrades + armorer hire + wages + repairs. It includes spending after the first title. Faster promotion itself changes income, so the income difference is not all direct kit return.\n\n| Case | Set | Income CC/season, N/H/D | Kit CC/career, N/H/D |\n|---|---|---|---|\n']
for n in NAMES:
    for cohort in ['default','heldout']:
        a=D[n][cohort]
        lines.append(f'| {n} | {cohort} | {trip(a,"cc_in_per_season")} | '+ ' / '.join(fmt(kit(a,arm)) for arm in arms)+' |\n')
lines += ['\nIncome source: `seasons.tsv: cc_in` (500 seasons/arm). Kit source: `metadata.json: checks[].costs_cc.{harness_upgrade,armorer_hire,armorer_wage,repair}` (25 careers/arm). Sessions, ceiling raises and signing remain separate in RESULTS-R2.tsv.\n',
'## Designs and standalone patches\n\nApply **one** r2 patch to the base, not over value.patch. Every patch retains the same platform: `quartermaster.gd: WEAR [1,.86,.72,.58,.50] → [1.05,.90,.48,.28,.10]`, `COST [6,14,28,48] → [1,2,4,7]`; `armorer.gd: WAGE [0,0,2,4,9,18] → [0,0,1,1,2,3]`; `fighter_card.gd: HARNESS_BASE_BONUS absent → [0,.02,.05,.09,.12]`, effective base capped at 99. **R2 does not further cut prices or enlarge this base bonus.** Thus these results are conditional on the value platform; they do not establish success at the original shop prices. Round 1’s price, wage, base-bonus and wear isolation controls remain in REPORT.md.\n\n',
'- [r2-control.patch](r2-control.patch): unchanged value, repeated on both sets.\n',
'- [r2-sponsor.patch](r2-sponsor.patch): `quartermaster.gd: APPEARANCE_CC absent → [0,.08,.20,.40,.65]` CC per maintained man per actual bout, times condition. `club_office.gd: harness_receipts absent → saved fractional carry`; whole credits go through `take`, a separate sponsorship income line. League regime processing and cup-result processing pay; forfeits do not. No extra combat stat.\n',
'- [r2-turnout.patch](r2-turnout.patch): `office_crowd.gd: HARNESS_DRAW absent → [0,.01,.025,.04,.06]`; add each traveling fighter’s grade draw × condition to the existing capped crowd multiplier. It affects attendance, gate bands and pull, not a guaranteed flat gate increase.\n',
'- [r2-gas.patch](r2-gas.patch): `fighter_card.gd: HARNESS_GAS_BONUS absent → [0,.01,.03,.05,.07]`; `effective_gas raw → min(99,raw*(1+bonus*condition))`. Rating and club power, melee tank via fighting_gas, and card overall use it. The raw gas bar, ability, potential and growth ceilings do not. Only its added bonus fades to zero with condition.\n',
'- [r2-reuse.patch](r2-reuse.patch): `quartermaster.gd: hand_down absent → grade/condition swap on a successful release, retirement or contract departure`; active recipients first, lowest grade, age ≤30, outgoing condition ≥.40. Both physical kits retain condition; no refill or cash. Recompute fighter trade value after the swap. Club splits excluded.\n',
'- [r2-resale.patch](r2-resale.patch): `quartermaster.gd: RESALE_FRACTION absent → .50`; outgoing kit returns `floor(.50*condition*cumulative rung cost)` on those same departures, is consumed, and cannot pay twice. Separate resale income; no purchase discount.\n',
'- [r2-cupwear.patch](r2-cupwear.patch): `season_cups.gd: sim_cup_tie no wear → bout_wear + sync_power` after settlement, matching the existing fought cup path. Added from the instrument audit before any complete results were read.\n',
'- [r2-sponsor-gas.patch](r2-sponsor-gas.patch): sponsor + gas exactly as isolated above. Adaptive to default-set results; frozen before held-out results were read.\n\n',
'The tests beside each case measure its addition against control; the combination has both constituent controls. TOP, repair step/formula, inspection threshold, XP and raw growth ceilings are unchanged. Prices/wages/base bonus are inherited dependencies, not newly isolated R2 changes. Freeze times and selection rule: [PLAN-R2.md](PLAN-R2.md). Commands: [COMMANDS-R2.md](COMMANDS-R2.md).\n',
'## Instrument and validation\n\n<!-- Insert checked totals and limitations here. -->\n',
'## Next measurement and Pete’s decision\n\n<!-- Insert reviewed next measurement and question here. -->\n']
(OUT/'REPORT-R2.md').write_text(''.join(lines),encoding='utf-8',newline='\n')
