from pathlib import Path
import json, shutil, subprocess, sys
MAIN=Path('C:/Dev/RetroBuhurt')
WORK=MAIN/'docs/harness-2/codex/work-r2'
ROOT=Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2')
names=sys.argv[1:] or ['control','sponsor','turnout','gas','reuse','resale']
for name in names:
    for cohort in ['default','heldout']:
        rel=f'docs/bakeoff-2/harness/codex-r2-{name}/{cohort}'
        src=ROOT/name/rel
        if not (src/'metadata.json').exists():
            print(name,cohort,'still running',flush=True)
            continue
        dst=MAIN/rel
        if (dst/'validation.json').exists():
            print(name,cohort,'already validated',flush=True)
            continue
        assert not dst.exists(), dst
        shutil.copytree(src,dst)
        args=[sys.executable,str(WORK/'analyse.py'),str(ROOT/name),str(dst)]
        if cohort=='heldout': args.append('--heldout')
        result=subprocess.run(args,capture_output=True,text=True)
        (WORK/f'logs/{name}-{cohort}-validation.txt').write_text(result.stdout+result.stderr,encoding='utf-8')
        assert result.returncode==0,(name,cohort,result.stderr[-2000:])
        data=json.loads((dst/'analysis.json').read_text())
        print(name,cohort,[(arm,x['titles'],x['restricted_mean_time_20']) for arm,x in data['arms'].items()],flush=True)
