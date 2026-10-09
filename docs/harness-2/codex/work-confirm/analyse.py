"""Independent full-run validation and paired, censor-aware summaries.

Reads the frozen probe output; never changes game code or raw results.
"""
import bisect
import sys
import csv
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean

HERE = Path(__file__).resolve().parent
ROOT = Path(sys.argv[1]).resolve()
RUN = Path(sys.argv[2]).resolve()
ARMS = ['no_harness', 'harness_first', 'development_first']
if '--four-arm' in sys.argv:
    ARMS.append('sensible_buyer')
CAREER_COUNT = len(ARMS)*25
SEASON_COUNT = CAREER_COUNT*20
PAIR_COUNT = len(ARMS)*(len(ARMS)-1)//2*25
BASES = [110017,130021,150041,170047,190027]
CATEGORIES = ['session', 'ceiling_raise', 'signing', 'armorer_hire',
              'armorer_wage', 'harness_upgrade', 'repair']

def read_tsv(name):
    with (RUN / name).open(newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f, delimiter='\t'))

def key(r):
    return r['arm'], int(r['base']), int(r['seed'])

meta = json.loads((RUN / 'metadata.json').read_text(encoding='utf-8'))
assert not meta['diagnostic_only'] and meta['validation_passed']
assert meta['bases'] == BASES and meta['years'] == 20 and meta['seeds_per_base'] == 5
assert meta['arms'] == ARMS
for path, digest in meta['source_sha256'].items():
    source = (ROOT / path.removeprefix('res://')).read_text(encoding='utf-8')
    assert hashlib.sha256(source.encode()).hexdigest() == digest, path
careers, seasons, pairs, attainment = map(read_tsv,
    ['careers.tsv', 'seasons.tsv', 'paired.tsv', 'attainment.tsv'])
assert len(careers) == CAREER_COUNT and len(seasons) == SEASON_COUNT and len(pairs) == PAIR_COUNT
by_key = {key(r): r for r in careers}
checks = {key(r): r for r in meta['checks']}
assert len(by_key) == len(checks) == CAREER_COUNT
expected = {(arm, base, base+i*7919) for arm in ARMS for base in BASES for i in range(5)}
assert set(by_key) == set(checks) == expected
assert len({(*key(s), int(s['elapsed_season'])) for s in seasons}) == SEASON_COUNT
seasons_by_key = defaultdict(list)
for r in seasons:
    seasons_by_key[key(r)].append(r)
for k, c in by_key.items():
    assert int(c['window']) == 20 and int(c['initial_cc']) == 8
    assert c['shared_manager_parity'] == 'not_run'
    assert bool(int(c['right_censored'])) == (c['first_title_season'] == '')
    assert checks[k]['right_censored'] == bool(int(c['right_censored']))
    assert int(c['first_title_season'] or 0) == checks[k]['first_title_season']
    assert sum(checks[k]['costs_cc'].values()) == int(c['cc_out'])
    assert sorted(int(s['elapsed_season']) for s in seasons_by_key[k]) == list(range(1,21))
for r in pairs:
    k1 = r['reference'], int(r['base']), int(r['seed'])
    k2 = r['treatment'], int(r['base']), int(r['seed'])
    before, after = checks[k1], checks[k2]
    assert int(r['final_cc_delta']) == after['final_cc'] - before['final_cc']
    assert int(r['final_power_delta']) == after['final_power'] - before['final_power']
    for c in CATEGORIES:
        assert int(r[c+'_cc_delta']) == after['costs_cc'].get(c,0) - before['costs_cc'].get(c,0)
    if before['right_censored'] or after['right_censored']:
        assert r['title_delta_both_observed_only'] == ''
    else:
        assert int(r['title_delta_both_observed_only']) == after['first_title_season']-before['first_title_season']
for r in attainment:
    group = [c for c in careers if c['arm'] == r['arm']]
    wins = sum(not int(c['right_censored']) for c in group)
    assert int(r['careers']) == 25 and int(r['titles_observed']) == wins
    assert int(r['right_censored']) == 25-wins
    assert abs(float(r['attainment_fraction'])-wins/25) < 1e-6

ledger_checks = []
totals = Counter()
ledger_metrics = defaultdict(Counter)
for k in sorted(expected):
    arm, base, seed = k
    path = RUN / f'{arm}-{seed}.jsonl'
    rows = [json.loads(s) for s in path.read_text(encoding='utf-8').splitlines()]
    assert all(key(r) == k for r in rows)
    assert [r['seq'] for r in rows] == list(range(1,len(rows)+1))
    assert rows[-1]['kind'] == 'validation' and not rows[-1]['failures']
    assert len(rows) == checks[k]['rows']
    tx = [r for r in rows if r['kind'] == 'transaction']
    initial = rows[0]['state']
    bank = initial['cc']
    positions, prefix = [], [0]
    tx_year = defaultdict(Counter)
    costs = Counter()
    for metric in ['harness_sponsorship_cc','harness_resale_cc','retained_grade_increases']:
        ledger_metrics[k][metric] = 0
    for t in tx:
        assert t['cc_before'] == bank
        sign = 1 if t['direction'] == 'in' else -1
        if sign > 0 and t['line'] == 'Sponsors': ledger_metrics[k]['harness_sponsorship_cc'] += t['cc']
        if sign > 0 and t['line'] == 'Harness resale': ledger_metrics[k]['harness_resale_cc'] += t['cc']
        bank += sign*t['cc']
        assert t['cc_after'] == bank
        positions.append(t['seq'])
        prefix.append(prefix[-1]+sign*t['cc'])
        tx_year[t['elapsed_season']][t['direction']] += t['cc']
        if sign < 0:
            costs[t['category']] += t['cc']
    assert dict(costs) == checks[k]['costs_cc']
    actual_counts = defaultdict(Counter)
    for r in rows:
        if r['kind'] == 'action':
            lo = bisect.bisect_right(positions, r['transaction_seq_after'])
            hi = bisect.bisect_right(positions, r['transaction_seq_through'])
            assert r['cc_after']-r['cc_before'] == prefix[hi]-prefix[lo], (path,r['seq'])
            if isinstance(r['result'],str):
                assert r['completed'] == (r['result'] == '')
            actual_counts[r['action']]['attempted'] += 1
            actual_counts[r['action']]['completed'] += int(r['completed'])
        if r['kind'] in ('action','level_spend','cash_in'):
            assert r['xp_earned'] >= 0 and r['xp_spent_levels'] >= 0 and r['xp_cashed'] >= 0
            if r['kind'] in ('level_spend','cash_in'):
                dx = sum(c['before']['xp']-c['after']['xp'] for c in r['changed_men'] if 'before' in c)
                dl = sum(c['after']['level']-c['before']['level'] for c in r['changed_men'] if 'before' in c)
                assert dx == r['xp_spent_levels']+r['xp_cashed']
                assert dl == r['levels_spent']+r['levels_cashed']
    assert {n:dict(c) for n,c in actual_counts.items()} == checks[k]['counts']
    inspection_crossings = 0
    low_arrivals = 0
    zero_steps = sum(r['kind']=='action' and r['action'] in ('calendar_step','cup_tie') and r['power_after']==0 for r in rows)
    low_boundary_stock = sum(sum(f['condition'] < .35 for f in r['state']['roster'].values()) for r in rows if r['kind']=='boundary' and r['name'] in ('pre_rollover','post_rollover'))
    roster = initial['roster'].copy()
    entered = left = 0
    for r in rows:
        for c in r.get('changed_men',[]):
            if 'arrival' in c:
                man = c['arrival']; fid = str(man['id'])
                if fid not in roster:
                    entered += man['xp']
                    low_arrivals += int(man['condition'] < .35)
                roster[fid] = man
            elif 'departure' in c:
                fid = str(c['departure']['id'])
                if fid in roster: left += roster.pop(fid)['xp']
            else:
                fid = str(c['after']['id'])
                # Nested parent deltas repeat changes; replay current state avoids counting twice.
                if fid in roster:
                    inspection_crossings += int(roster[fid]['condition'] >= .35 and c['after']['condition'] < .35)
                    if r.get('action') != 'harness_upgrade' and c['after']['grade'] > roster[fid]['grade']:
                        ledger_metrics[k]['retained_grade_increases'] += 1
                roster[fid] = c['after']
        if r['kind'] == 'boundary':
            assert roster == r['state']['roster'], (path,r['name'],r['seq'])
    earned = sum(r.get('xp_earned',0) for r in rows)
    spent = sum(r.get('xp_spent_levels',0) for r in rows)
    cashed = sum(r.get('xp_cashed',0) for r in rows)
    xp_initial = sum(f['xp'] for f in initial['roster'].values())
    xp_final = sum(f['xp'] for f in roster.values())
    assert xp_initial+earned+entered-spent-cashed-left == xp_final, (path,earned,spent,cashed,entered,left,xp_final)
    career = by_key[k]
    assert bank == int(career['final_cc'])
    assert sum(r.get('levels_spent',0) for r in rows if r['context']=='report_level_run') == int(career['levels_spent_in_season'])
    cash_rows = [r for r in rows if r['kind']=='cash_in']
    assert len(cash_rows) == 20
    for r in cash_rows:
        # The cash-in boundary is before subsequent roster splits/payments.
        assert r['cc_after']-r['cc_before'] == r['cash_in_cc']
        assert bool(r['cash_in_cc']) == bool(r['levels_cashed'])
    previous = 8
    for s in sorted(seasons_by_key[k],key=lambda r:int(r['elapsed_season'])):
        y = int(s['elapsed_season'])
        assert int(s['opening_cc']) == previous
        assert tx_year[y]['in'] == int(s['cc_in']) and tx_year[y]['out'] == int(s['cc_out'])
        assert previous+int(s['cc_in'])-int(s['cc_out']) == int(s['cc_post_rollover'])
        previous = int(s['cc_post_rollover'])
    for metric in ['xp_earned','xp_spent_levels','xp_cashed','levels_spent','levels_cashed']:
        ledger_metrics[k][metric] = sum(r.get(metric,0) for r in rows)
    ledger_metrics[k]['inspection_crossings'] = inspection_crossings
    ledger_metrics[k]['low_condition_arrivals'] = low_arrivals
    ledger_metrics[k]['zero_power_calendar_or_cup_actions'] = zero_steps
    ledger_metrics[k]['low_condition_rollover_stock_observations'] = low_boundary_stock
    ledger_metrics[k]['cash_in_cc'] = sum(r['cash_in_cc'] for r in cash_rows)
    ledger_metrics[k]['positive_cash_in_rows'] = sum(r['cash_in_cc']>0 for r in cash_rows)
    totals['ledger_rows'] += len(rows)
    totals['transaction_rows'] += len(tx)
    totals['positive_cash_in_rows'] += ledger_metrics[k]['positive_cash_in_rows']
    ledger_checks.append({'arm':arm,'base':base,'seed':seed,'rows':len(rows),'money':'pass','xp':'pass'})
    print(f'Validated {arm} base={base} seed={seed}',flush=True)

validation = {'snapshot_commit':'fae6fba7954f6e968a1df85943c6b0e2eea32246',
              'careers':CAREER_COUNT,'seasons':SEASON_COUNT,'pairs':PAIR_COUNT,'source_hashes':'match',
              'validation_passed':True,'totals':dict(totals),'ledgers':ledger_checks}
(RUN/'validation.json').write_text(json.dumps(validation,indent=2)+'\n')

def bounded_time(c):
    # E[min(T,20)] is identifiable at the 20-season administrative cutoff.
    # A censored career contributes 20, never an invented win in season 21.
    return int(c['first_title_season']) if c['first_title_season'] else 20

arms = {}
for arm in ARMS:
    group = [c for c in careers if c['arm']==arm]
    won = [int(c['first_title_season']) for c in group if c['first_title_season']]
    kk = [key(c) for c in group]
    arms[arm] = {'titles':len(won),'censored':25-len(won),
        'restricted_mean_time_20':mean(map(bounded_time,group)),
        'observed_win_mean':mean(won) if won else None,
        'cc_in_per_season':sum(int(c['cc_in']) for c in group)/500,
        'cc_out_per_season':sum(int(c['cc_out']) for c in group)/500,
        'final_cc_mean':mean(int(c['final_cc']) for c in group),
        'final_power_mean':mean(checks[k]['final_power'] for k in kk),
        'cost_per_season':{cat:sum(checks[k]['costs_cc'].get(cat,0) for k in kk)/500 for cat in CATEGORIES},
        'actions_per_season':{cat:{metric:sum(checks[k]['counts'].get(cat,{}).get(metric,0) for k in kk)/500
                             for metric in ['attempted','completed']} for cat in ['session','ceiling_raise','signing']},
        'ledger_metrics_total':{m:sum(ledger_metrics[k][m] for k in kk) for m in ledger_metrics[kk[0]]}}

contrasts = {}
base_rows = []
for i, ref in enumerate(ARMS):
    for treatment in ARMS[i+1:]:
        group = [r for r in pairs if r['reference']==ref and r['treatment']==treatment]
        dt = []; seen_dt = []; base_dt = defaultdict(list)
        for p in group:
            a = by_key[(ref,int(p['base']),int(p['seed']))]
            b = by_key[(treatment,int(p['base']),int(p['seed']))]
            difference = bounded_time(b)-bounded_time(a)
            dt.append(difference); base_dt[int(p['base'])].append(difference)
            if p['title_delta_both_observed_only']:
                seen_dt.append(int(p['title_delta_both_observed_only']))
        tag = treatment+' minus '+ref
        contrasts[tag] = {'pairs':len(group),'restricted_time_delta_mean':mean(dt),
                         'paired_delta_counts':dict(Counter(dt)),
                         'both_titles_observed':len(seen_dt),
                         'observed_pair_title_delta_mean':mean(seen_dt) if seen_dt else None,
                         'base_restricted_time_deltas':{str(k):mean(v) for k,v in base_dt.items()},
                         'cc_delta_per_season':{c:mean(int(r[c+'_cc_delta']) for r in group)/20 for c in CATEGORIES},
                         'final_cc_delta_mean':mean(int(r['final_cc_delta']) for r in group),
                         'final_power_delta_mean':mean(int(r['final_power_delta']) for r in group)}
        for base, values in base_dt.items():
            base_rows.append([ref,treatment,base,mean(values)])
analysis = {'time_definition':'mean min(first National title season,20); censored contributes20',
            'budget_denominator':'25 careers * 20 seasons = 500 closed seasons per arm',
            'arms':arms,'contrasts':contrasts}
(RUN/'analysis.json').write_text(json.dumps(analysis,indent=2)+'\n')
with (RUN/'base_contrasts.tsv').open('w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['reference','treatment','base','restricted_time_delta_mean']);w.writerows(base_rows)
print(json.dumps(analysis,indent=2))
