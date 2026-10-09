"""Collect derived confirmation evidence; leave every raw journal at its run location."""
import csv
import hashlib
import json
import shutil
from pathlib import Path

root=Path('C:/Dev/RetroBuhurt')
here=root/'docs/harness-2/codex/work-confirm'
primary=root/'docs/bakeoff-2/harness/codex-confirm'
scratch=Path('C:/Users/PeterM/Documents/Codex/work/harness-confirm-sensible')
sensible=scratch/'docs/bakeoff-2/harness/codex-confirm-sensible'
def read(path):return json.loads(path.read_text(encoding='utf-8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
a=read(primary/'analysis.json'); b=read(sensible/'analysis.json')
parity=[]
for path in sorted(primary.glob('*.jsonl')):
    other=sensible/path.name
    row={'journal':path.name,'primary_sha256':sha(path),'sensible_sha256':sha(other)}
    row['identical']=row['primary_sha256']==row['sensible_sha256']
    parity.append(row)
assert len(parity)==75 and all(r['identical'] for r in parity)
for arm in ['no_harness','harness_first','development_first']:
    assert a['arms'][arm]==b['arms'][arm],arm
for arm in ['harness_first','development_first','sensible_buyer']:
    assert b['arms'][arm]['cost_per_season']['harness_upgrade']>0,arm
dest=root/'docs/bakeoff-2/harness/codex-confirm-sensible'
dest.mkdir(exist_ok=False)
for name in ['careers.tsv','seasons.tsv','paired.tsv','attainment.tsv','metadata.json',
             'validation.json','analysis.json','base_contrasts.tsv']:
    shutil.copy2(sensible/name,dest/name)
(dest/'RAW-LOCATION.md').write_text('Raw journals remain where the scratch run created them:\n\n'+str(sensible)+'\n',encoding='utf-8')
(here/'journal-parity.json').write_text(json.dumps(parity,indent=2)+'\n',encoding='utf-8')
arms={**a['arms'],'sensible_buyer':b['arms']['sensible_buyer']}
never=arms['no_harness']['restricted_mean_time_20']
deltas={arm:arms[arm]['restricted_mean_time_20']-never for arm in arms if arm!='no_harness'}
passed=all(deltas[arm]<=0 for arm in ['harness_first','development_first'])
summary={'predeclared_pass':passed,'arms':arms,'buyer_minus_never':deltas,
         'contrasts':b['contrasts'],'identical_original_journals':len(parity),
         'primary_validation':read(primary/'validation.json'),
         'sensible_validation':read(sensible/'validation.json'),
         'sensible_raw_location':str(sensible)}
(here/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
with (here/'RESULTS.tsv').open('w',newline='',encoding='utf-8') as f:
    w=csv.writer(f,delimiter='\t')
    w.writerow(['arm','titles_out_of_25','right_censored','capped_wait','delta_vs_never'])
    for arm,stats in arms.items():
        w.writerow([arm,stats['titles'],stats['censored'],stats['restricted_mean_time_20'],
                    0 if arm=='no_harness' else deltas[arm]])
print(json.dumps({'predeclared_pass':passed,'buyer_minus_never':deltas,
                  'arms':{arm:{k:v for k,v in stats.items() if k in ['titles','censored','restricted_mean_time_20']} for arm,stats in arms.items()},
                  'base_deltas':{arm:b['contrasts'][arm+' minus no_harness']['base_restricted_time_deltas'] for arm in deltas},
                  'identical_original_journals':len(parity)},indent=2))
