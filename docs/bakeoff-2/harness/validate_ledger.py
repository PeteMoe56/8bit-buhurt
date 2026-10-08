"""Independent checks of emitted money, action intervals, XP and coverage."""
import csv
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUN = HERE / 'dry-9001'
ROOT = HERE.parents[2]
meta = json.loads((RUN / 'metadata.json').read_text())
assert meta['diagnostic_only'] and meta['validation_passed']
assert meta['bases'] == [9001] and meta['years'] == 2
assert len(meta['checks']) == 3
assert all(x['passed'] and not x['injected_resources'] for x in meta['button_checks'])
for path, digest in meta['source_sha256'].items():
    source = (ROOT / path.removeprefix('res://')).read_text(encoding='utf-8')
    assert hashlib.sha256(source.encode()).hexdigest() == digest, path

with (RUN / 'careers.tsv').open(newline='') as f:
    careers = list(csv.DictReader(f, delimiter='\t'))
with (RUN / 'seasons.tsv').open(newline='') as f:
    seasons = list(csv.DictReader(f, delimiter='\t'))
assert len(careers) == 3 and len(seasons) == 6
assert len({(r['arm'], r['seed']) for r in careers}) == 3
assert len({(r['arm'], r['seed'], r['elapsed_season']) for r in seasons}) == 6
assert {r['arm'] for r in careers} == set(meta['arms'])
assert all(r['shared_manager_parity'] == 'pass' for r in careers[:2])
with (RUN / 'paired.tsv').open(newline='') as f:
    pairs = list(csv.DictReader(f, delimiter='\t'))
with (RUN / 'attainment.tsv').open(newline='') as f:
    attainment = list(csv.DictReader(f, delimiter='\t'))
assert len(pairs) == 3 and len(attainment) == 3
by_arm = {r['arm']: r for r in meta['checks']}
for r in pairs:
    before, after = by_arm[r['reference']], by_arm[r['treatment']]
    assert int(r['final_cc_delta']) == after['final_cc'] - before['final_cc']
    assert int(r['final_power_delta']) == after['final_power'] - before['final_power']
    for k, v in r.items():
        if k.endswith('_cc_delta') and k != 'final_cc_delta':
            category = k.removesuffix('_cc_delta')
            assert int(v) == after['costs_cc'].get(category, 0) - before['costs_cc'].get(category, 0)
    if before['right_censored'] or after['right_censored']:
        assert r['title_delta_both_observed_only'] == ''
for c in careers:
    assert sum(by_arm[c['arm']]['costs_cc'].values()) == int(c['cc_out'])
for r in attainment:
    observed = int(not by_arm[r['arm']]['right_censored'])
    assert int(r['titles_observed']) == observed
    assert int(r['right_censored']) == 1-observed

checks = []
for path in sorted(RUN.glob('*.jsonl')):
    rows = [json.loads(s) for s in path.read_text().splitlines()]
    assert [r['seq'] for r in rows] == list(range(1, len(rows)+1)), path
    transactions = [r for r in rows if r['kind'] == 'transaction']
    initial = rows[0]['state']
    bank = initial['cc']
    for t in transactions:
        assert t['cc_before'] == bank, (path, t)
        sign = 1 if t['direction'] == 'in' else -1
        bank += sign*t['cc']
        assert t['cc_after'] == bank, (path, t)
    for r in rows:
        if r['kind'] == 'action':
            nested = [t for t in transactions
                      if r['transaction_seq_after'] < t['seq'] <= r['transaction_seq_through']]
            net = sum(t['cc'] * (1 if t['direction'] == 'in' else -1) for t in nested)
            assert r['cc_after'] - r['cc_before'] == net, (path, r['seq'])
            if isinstance(r['result'], str):
                assert r['completed'] == (r['result'] == ''), (path, r['seq'])
        if r['kind'] in ('action', 'level_spend', 'cash_in'):
            assert r['xp_earned'] >= 0 and r['xp_spent_levels'] >= 0 and r['xp_cashed'] >= 0
            if r['kind'] in ('level_spend', 'cash_in'):
                dx = sum(c['before']['xp'] - c['after']['xp']
                         for c in r['changed_men'] if 'before' in c)
                dl = sum(c['after']['level'] - c['before']['level']
                         for c in r['changed_men'] if 'before' in c)
                assert dx == r['xp_spent_levels'] + r['xp_cashed']
                assert dl == r['levels_spent'] + r['levels_cashed']

    # Replay changed cards once, including nested actions. A parent row may
    # repeat a child's final card: assigning it again changes no XP or stock.
    roster = initial['roster'].copy()
    entered = left = 0
    for r in rows:
        for c in r.get('changed_men', []):
            if 'arrival' in c:
                man = c['arrival']
                key = str(man['id'])
                if key not in roster:
                    entered += man['xp']
                roster[key] = man
            elif 'departure' in c:
                key = str(c['departure']['id'])
                if key in roster:
                    left += roster.pop(key)['xp']
            else:
                roster[str(c['after']['id'])] = c['after']
        if r['kind'] == 'boundary':
            assert roster == r['state']['roster'], (path, r['name'])
    earned = sum(r.get('xp_earned', 0) for r in rows)
    spent = sum(r.get('xp_spent_levels', 0) for r in rows)
    cashed = sum(r.get('xp_cashed', 0) for r in rows)
    xp_start = sum(m['xp'] for m in initial['roster'].values())
    xp_final = sum(m['xp'] for m in roster.values())
    assert xp_start + earned + entered - spent - cashed - left == xp_final, path

    if not path.name.startswith('button_check_'):
        career = next(c for c in careers if c['arm'] == rows[0]['arm'])
        assert bank == int(career['final_cc'])
        assert sum(r.get('levels_spent', 0) for r in rows
                   if r['context'] == 'report_level_run') == int(career['levels_spent_in_season'])
        for s in [s for s in seasons if s['arm'] == career['arm']]:
            y = int(s['elapsed_season'])
            tx = [t for t in transactions if t['elapsed_season'] == y]
            cin = sum(t['cc'] for t in tx if t['direction'] == 'in')
            cout = sum(t['cc'] for t in tx if t['direction'] == 'out')
            assert cin == int(s['cc_in']) and cout == int(s['cc_out'])
            assert int(s['opening_cc'])+cin-cout == int(s['cc_post_rollover'])
    checks.append({'ledger': path.name, 'rows': len(rows), 'money': 'pass', 'xp': 'pass'})

report = {'coverage': '3 arms / 6 season rows / 2 separate button checks',
          'source_snapshot': 'matches', 'parity': '2/2 pass', 'ledgers': checks,
          'balance_conclusions': 'not drawn'}
(HERE / 'validation.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
