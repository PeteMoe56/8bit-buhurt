from pathlib import Path
import csv, json, hashlib, sys
MAIN=Path('C:/Dev/RetroBuhurt')
OUT=MAIN/'docs/harness-2/codex'
names=sys.argv[1:] or ['control','sponsor','turnout','gas','reuse','resale']
data={}; rows=[]; bases=[]
for name in names:
    data[name]={}
    for cohort in ['default','heldout']:
        run=MAIN/f'docs/bakeoff-2/harness/codex-r2-{name}/{cohort}'
        if not (run/'validation.json').exists(): continue
        a=json.loads((run/'analysis.json').read_text())
        v=json.loads((run/'validation.json').read_text())
        meta=json.loads((run/'metadata.json').read_text())
        baseline=10.88 if cohort=='default' else 10.40
        n=a['arms']['no_harness']['restricted_mean_time_20']
        a['strict_pass']=all(a['arms'][arm]['restricted_mean_time_20']<=n and a['arms'][arm]['titles']==25 for arm in ['harness_first','development_first']) and abs(n-baseline)<=.5
        a['nonbuyer_reference_shift']=n-baseline
        a['validation']=v
        data[name][cohort]=a
        for arm,x in a['arms'].items():
            costs=x['cost_per_season']
            kit=sum(costs[c] for c in ['harness_upgrade','armorer_hire','armorer_wage','repair'])*20
            rows.append([name,cohort,arm,x['titles'],x['censored'],x['restricted_mean_time_20'],x['restricted_mean_time_20']-n,n-baseline,x['cc_in_per_season'],kit]+[costs[c] for c in ['session','ceiling_raise','signing','harness_upgrade','armorer_hire','armorer_wage','repair']])
        for arm in ['harness_first','development_first']:
            pair=a['contrasts'][arm+' minus no_harness']
            for base in meta['bases']:
                bases.append([name,cohort,arm,base,pair['base_restricted_time_deltas'][str(base)]])
        print(name,cohort,'PASS' if a['strict_pass'] else 'FAIL',[(arm,x['restricted_mean_time_20']) for arm,x in a['arms'].items()])
(OUT/'SUMMARY-R2.json').write_text(json.dumps(data,indent=2)+'\n')
with (OUT/'RESULTS-R2.tsv').open('w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['variant','set','arm','titles','censored','capped_wait','buyer_minus_nonbuyer','nonbuyer_reference_shift','income_cc_per_season','kit_cc_per_20_season_career','session_cc_per_season','ceiling_cc_per_season','signing_cc_per_season','upgrade_cc_per_season','armorer_hire_cc_per_season','armorer_wage_cc_per_season','repair_cc_per_season']);w.writerows(rows)
with (OUT/'BASES-R2.tsv').open('w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['variant','set','buyer','base','buyer_minus_nonbuyer_capped_wait']);w.writerows(bases)
parity={}
for name, sets in data.items():
    for cohort in sets:
        root=MAIN/f'docs/bakeoff-2/harness/codex-r2-{name}/{cohort}'
        control=MAIN/f'docs/bakeoff-2/harness/codex-r2-control/{cohort}'
        if not (control/'validation.json').exists(): continue
        equal=[];different=[]
        for p in root.glob('no_harness-*.jsonl'):
            (equal if hashlib.sha256(p.read_bytes()).digest()==hashlib.sha256((control/p.name).read_bytes()).digest() else different).append(p.name)
        parity[name+' '+cohort]={'nonbuyer_journals_equal':len(equal),'different':different}
old=MAIN/'docs/bakeoff-2/harness/codex-value'
new=MAIN/'docs/bakeoff-2/harness/codex-r2-control/default'
if (new/'validation.json').exists():
    p=sorted(new.glob('*.jsonl'))
    parity['control versus round1 value']={'all_journals_equal':sum(hashlib.sha256(f.read_bytes()).digest()==hashlib.sha256((old/f.name).read_bytes()).digest() for f in p),'journals':len(p)}
(OUT/'PARITY-R2.json').write_text(json.dumps(parity,indent=2)+'\n')
