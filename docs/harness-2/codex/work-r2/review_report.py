from pathlib import Path
import json
MAIN=Path('C:/Dev/RetroBuhurt')
OUT=MAIN/'docs/harness-2/codex'
D=json.loads((OUT/'SUMMARY-R2.json').read_text())
T=json.loads((OUT/'VALIDATION-TOTALS-R2.json').read_text())
p=OUT/'REPORT-R2.md'
s=p.read_text(encoding='utf-8')
verdict='''**Recommend `sponsor` alone as the candidate for Pete’s decision and Claude’s gate.** It passes both original buyers in both cohorts: **10.28 / 10.28** against **10.88** default; **10.16 / 9.76** against **10.40** held-out. All observed titles, no censored careers. Nonbuyers move **0.00** versus their same-set control; held-out’s **−0.48** versus the old 10.88 is a cohort difference, not a mechanical penalty. Sources: sponsor’s respective `careers.tsv: first_title_season,right_censored`; [PARITY-R2.json](PARITY-R2.json).

The mechanism is a maintained-kit sponsorship receipt, rather than a further price reduction or larger base bonus. It earns roughly 57 CC per buyer-season in the measured window. This is conditional on the existing value platform, not a claim about the original expensive shop. Prefer this isolated mechanism to the combination: the gas addition fails a matched real-melee symmetry check. **Do not land the gas variants on these results.**

The means do not erase counterexamples: sponsor’s held-out base **43049** is **+1.60** seasons for H and **+0.20** for D. Default base **9001** is **+0.40** for D. Source: sponsor’s `base_contrasts.tsv: restricted_time_delta_mean`. The pass mark is met in the requested cohorts; a reliable benefit across arbitrary seeds is still unestablished.'''
s=s.replace('<!-- Insert reviewed recommendation here. -->',verdict)
budget='\nFor sponsorship, paired budget differences versus the same-set nonbuyer are:\n\n| Set | Buyer | Direct sponsorship CC/season | Sessions Δ | Ceiling raises Δ | Signing Δ |\n|---|---|---:|---:|---:|---:|\n'
for cohort in ['default','heldout']:
    a=D['sponsor'][cohort]
    for arm in ['harness_first','development_first']:
        pair=a['contrasts'][arm+' minus no_harness']
        direct=a['arms'][arm]['ledger_metrics_total']['harness_sponsorship_cc']/500
        costs=pair['cc_delta_per_season']
        budget += f'| {cohort} | {arm} | {direct:.3f} | {costs["session"]:+.3f} | {costs["ceiling_raise"]:+.3f} | {costs["signing"]:+.3f} |\n'
budget+='\nDirect receipt source: `*.jsonl` transaction rows `direction=in,line=Harness sponsorship,cc`; denominator 500 seasons/arm. Budget deltas: `paired.tsv: session_cc_delta,ceiling_raise_cc_delta,signing_cc_delta`, averaged over 25 pairs and divided by 20 seasons. These are full-window effects, not a decomposition of the first-title gain.\n\nHand-downs cut default kit spending by **71.40 / 72.24 CC per career** versus value (H/D), but do not pass title timing. Source: each `metadata.json: checks[].costs_cc`, same four kit categories. Resale also fails; cash recovered is not proof of a faster title.\n'
s=s.replace('## Designs and standalone patches',budget+'\n## Designs and standalone patches')
c=T['counts']
audit=f'''All **{c['careers']:,} careers / {c['seasons']:,} closed seasons / {c['pairs']:,} paired rows** finished with probe validation true and independent validation passed. The independent replay reconciled **{c['ledger_rows']:,} journal rows and {c['transaction_rows']:,} transactions**, source hashes, every cash movement, closed books, XP, censoring and paired summaries. This includes repeated controls, not that many independent samples. Sources: each `metadata.json: validation_passed,checks`; `validation.json: careers,seasons,pairs,totals`; [VALIDATION-TOTALS-R2.json](VALIDATION-TOTALS-R2.json), [SHA256-R2.tsv](SHA256-R2.tsv), [SOURCE-PINS-R2.json](SOURCE-PINS-R2.json).

All nonbuyer journals outside cupwear match their same-set control byte-for-byte; the default control’s **75** journals match round 1 value. [PARITY-R2.json](PARITY-R2.json). Cupwear alone records **14 / 2** nonbuyer inspection crossings (default/held-out), **0** in its buyers, and shifts held-out N **+0.36**. All cases record **0** calendar/cup actions ending at zero power. Sources: `analysis.json: arms.*.ledger_metrics_total.{{inspection_crossings,zero_power_calendar_or_cup_actions}}`. These observations do not prove absence of a transient failed lineup or an actual forfeit: the primary ledger omits the pre-fielding eligibility state and emergency outcome.

The focused grade/feature fixtures pass on all eight cases; they verify actual wear order and uneven steps through Titanium, unchanged raw ability/headroom, fractional saved receipts, gas fading, conserved physical kit and consumed resale. Initial fixture setup errors (missing/wrong Season constructor argument) were corrected; original error logs are retained. Existing save suite: **21** checks; reuse/resale market suites: **26** each. Source: `work-r2/logs/*-fixture-stdout.txt`, `sponsor-save-stdout.txt`, `reuse-market-stdout.txt`, `resale-market-stdout.txt`.

The short invariant runs pass **118** checks, **17** save round trips and **15** fought bouts, but **do not prove buyer coverage**: even enabling RB_HARNESS does not call the seasonal shop in that test. The guarded buyer fixture instead records **103 CC** in the manager’s tracked harness/hire purchases, **5** paid starters, **3** fought bouts and **9 CC** sponsorship; whole-career cash/books/fraction survive reload, and nonfight regime processing pays nothing. Source: `work-r2/logs/sponsor-fought-check-stdout.txt: PURCHASE_GUARD,FOUGHT_SPONSORSHIP,CHECK`.

**Gas is rejected for landing.** Its heavy-deficit fixture still gives Titanium **1/48** wins at a 16-point raw-stat deficit on each base **30000 / 61000**, below C6’s 40% wall. However, its 400-bout Titanium mirror yields **153 wins / 246 losses / 1 undecided** (**38.35%** of decided bouts), failing the existing symmetry band (50±9). The identical control fixture yields **198 / 202 / 0** (**49.50%**), passing symmetry and C3. Gas narrowly passes C3’s lower threshold; the failed check is symmetry, not C3. Sources: `gas-quality-stdout.txt: CELL,TARGETED_CHECK_FAILURES`; `gas-mirror-stdout.txt` and `control-mirror-stdout.txt: mirror,TITANIUM_MIRROR_CHECKS`; retained fixtures in `work-r2/`. The sponsor-gas patch shares gas’s combat formulas, so a career pass does not clear this failure. These are targeted checks; **the full balance tier and Windows gate were not run or claimed**.

Instrument limits:

- Career outcomes use aggregate-power quick bouts, not melee play. Quick bouts do not call `_apply_bout_injuries`; an injury-protection change cannot establish its value with this required probe. No injury variant was pretended to do so.
- Quick cup ties currently skip persistent wear; fought ties do not. Cupwear measures the correction but fails the shop criterion. Sponsorship uses the actual cup-result path with forfeits excluded, so it does not depend on that missing wear hook.
- League wear/payment follows the existing post-injury-substitution lineup. It is not an audited record of every man who actually fought; correct participation attribution before landing. The ledger lacks availability/position and fractional receipts, so its independent replay verifies booked cash, not the complete attendance/accrual rule. Dedicated feature/save fixtures cover that rule separately.
- The manager knows hidden ceilings, repairs frequently at effectively zero CC, and buys by its preset policy. Neither human shopping nor repair effort is measured. Crowd draw is cached and refreshed through the existing setter; immediate purchase-to-gate display needs integration acceptance.
- All prototypes retain the old value base bonus: it reaches rating/club power, melee defence and card overall, not raw ability; its condition factor does not fade completely. Gas’s extra bonus does. No kit changes growth ceilings. C1/C4/C5, C2/C6 and pacing remain required in Claude’s selected gate; income gains and ledger checks are not substitutes for them.

Engine: `C:\\Users\\PeterM\\Desktop\\Godot_v4.6.2-stable_win64.exe`; fresh **`--version`: 4.6.2.stable.official.71f334935** (`work-r2/logs/engine-version.txt`). Some otherwise validated exit-zero sweeps retain existing ObjectDB/two-resource shutdown warnings. Main remains at the base; the pre-existing deletion of `tools/probe_scouting.gd.uid` was left alone.'''
s=s.replace('<!-- Insert checked totals and limitations here. -->',audit)
next='''**One next measurement:** freeze sponsor’s standalone patch and run the unchanged primary probe on a third, predeclared set **110017 130021 150041 170047 190027**, five seeds per base, 20 seasons, original three arms, fresh output `res://docs/bakeoff-2/harness/codex-r2-sponsor-confirm`. Retain the same source pins, title/censor columns, per-base paired deltas and independent cash/XP validation. Require both buyers no slower than their same-set nonbuyer, with its wait reported separately; do not tune the payout on those results. This is confirmation, not another R2 variant already measured.

**Pete’s design question:** does a maintained-kit sponsorship contract fit the shop’s meaning, and is roughly 57 extra CC per buyer-season an acceptable return? The experiments support the first-title criterion; they cannot choose that fiction or its presentation. If selected, Claude should correct fought-line attribution, expose the payout and existing kit benefit on the card/books using the shared glossary and text-fit checks, then run the balance tier and full gate. The inherited cheap prices remain an explicit part of the candidate. No main game change is applied here.'''
s=s.replace('<!-- Insert reviewed next measurement and question here. -->',next)
assert '<!--' not in s
p.write_text(s,encoding='utf-8',newline='\n')
print('Reviewed report written',len(s),'characters')
