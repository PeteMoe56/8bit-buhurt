from pathlib import Path
from collections import Counter
import hashlib,json,csv
MAIN=Path('C:/Dev/RetroBuhurt')
OUT=MAIN/'docs/harness-2/codex'
names=['control','sponsor','turnout','gas','reuse','resale','cupwear','sponsor-gas']
totals=Counter(); metrics=Counter(); source_pins={}; files=[]
for name in names:
    for cohort in ['default','heldout']:
        root=MAIN/f'docs/bakeoff-2/harness/codex-r2-{name}/{cohort}'
        v=json.loads((root/'validation.json').read_text())
        a=json.loads((root/'analysis.json').read_text())
        m=json.loads((root/'metadata.json').read_text())
        assert v['validation_passed'] and m['validation_passed']
        totals.update(v['totals'])
        for n in ['careers','seasons','pairs']: totals[n]+=v[n]
        for arm,s in a['arms'].items():
            for n in ['inspection_crossings','zero_power_calendar_or_cup_actions','low_condition_arrivals','low_condition_rollover_stock_observations']:
                metrics[n]+=s['ledger_metrics_total'][n]
        source_pins[name+' '+cohort]=m['source_sha256']
        for path in sorted(root.iterdir()):
            if path.is_file(): files.append((str(path.relative_to(MAIN)).replace('\\','/'),hashlib.sha256(path.read_bytes()).hexdigest(),path.stat().st_size))
assert totals['careers']==1200 and totals['seasons']==24000 and totals['pairs']==1200
with (OUT/'SHA256-R2.tsv').open('w',newline='') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['path','sha256','bytes']);w.writerows(files)
(OUT/'SOURCE-PINS-R2.json').write_text(json.dumps(source_pins,indent=2)+'\n')
(OUT/'VALIDATION-TOTALS-R2.json').write_text(json.dumps({'counts':dict(totals),'stock_metrics':dict(metrics)},indent=2)+'\n')
print(json.dumps({'counts':dict(totals),'stock_metrics':dict(metrics)},indent=2))
