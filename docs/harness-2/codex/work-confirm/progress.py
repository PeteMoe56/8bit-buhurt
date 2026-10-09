"""Read only sealed journal files while the sensible sweep is running."""
import hashlib
import json
from pathlib import Path

root=Path('C:/Dev/RetroBuhurt')
primary=root/'docs/bakeoff-2/harness/codex-confirm'
run=Path('C:/Users/PeterM/Documents/Codex/work/harness-confirm-sensible/docs/bakeoff-2/harness/codex-confirm-sensible')
complete=[]; parity=[]
for path in sorted(run.glob('*.jsonl')):
    with path.open('rb') as f:
        f.seek(0,2)
        f.seek(max(0,f.tell()-16384))
        tail=f.read().splitlines()
    if not tail:continue
    try:last=json.loads(tail[-1])
    except (json.JSONDecodeError,UnicodeDecodeError):continue
    if last.get('kind')!='validation':continue
    assert not last['failures'],path
    complete.append(path.name)
    ref=primary/path.name
    if ref.exists():
        assert hashlib.sha256(ref.read_bytes()).digest()==hashlib.sha256(path.read_bytes()).digest(),path
        parity.append(path.name)
print(json.dumps({'completed_careers':len(complete),'completed_original_journals_identical':len(parity)},indent=2))
