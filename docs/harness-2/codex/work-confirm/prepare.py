import difflib
import hashlib
import json
import subprocess
from pathlib import Path

root = Path('C:/Dev/RetroBuhurt')
here = root/'docs/harness-2/codex/work-confirm'
old = Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2/sponsor')
scratch = Path('C:/Users/PeterM/Documents/Codex/work/harness-confirm-sensible')
commit = 'fae6fba7954f6e968a1df85943c6b0e2eea32246'
def read(p): return p.read_text(encoding='utf-8')
def sha(p): return hashlib.sha256(read(p).encode()).hexdigest()
files = ['scripts/league/armorer.gd','scripts/league/club_office.gd',
         'scripts/league/quartermaster.gd','scripts/league/season_bouts.gd',
         'scripts/league/season_cups.gd','scripts/melee/fighter_card.gd',
         'scripts/game/season_tab_armorer.gd']
frozen_patch = subprocess.check_output(['git','-C',str(old),'diff','--',*files]).decode('utf-8').replace('\r\n','\n')
assert frozen_patch == read(root/'docs/harness-2/codex/r2-sponsor.patch'), 'Saved round-2 scratch must exactly reproduce standalone sponsor patch'
diff = ''.join(''.join(difflib.unified_diff(read(old/p).splitlines(True),read(root/p).splitlines(True),
                fromfile='r2-sponsor/'+p,tofile='fae6fba/'+p)) for p in files)
(here/'landed-versus-r2-sponsor.diff').write_text(diff,encoding='utf-8')
pins = {'commit':commit,'engine_path':'C:/Users/PeterM/Desktop/Godot_v4.6.2-stable_win64.exe',
        'old_scratch_exactly_matches_r2_sponsor_patch':True,
        'main_primary_sha256':sha(root/'tools/probe_harness_budget.gd'),
        'main_manager_sha256':sha(root/'tools/manager.gd'),
        'sensible_source_sha256':sha(root/'docs/harness-2/codex/probe_harness_budget_sensible.gd'),
        'unchanged_from_round2':{},'scratch_game_matches_main':{}}
for p in ['tools/probe_harness_budget.gd','tools/manager.gd']:
    pins['unchanged_from_round2'][p] = sha(old/p)==sha(root/p)
    assert pins['unchanged_from_round2'][p]
for p in root.joinpath('scripts').rglob('*.gd'):
    rel=p.relative_to(root)
    pins['scratch_game_matches_main'][rel.as_posix()]=sha(p)==sha(scratch/rel)
    assert pins['scratch_game_matches_main'][rel.as_posix()]
assert sha(root/'docs/harness-2/codex/probe_harness_budget_sensible.gd')==sha(scratch/'tools/probe_harness_budget_sensible.gd')
(here/'source-pins.json').write_text(json.dumps(pins,indent=2)+'\n',encoding='utf-8')
source=read(root/'docs/harness-2/codex/work-r2/analyse.py')
source=source.replace("BASES = [17011,29033,43049,67061,91081] if '--heldout' in sys.argv else [9001,5150,2718,6060,8123]",'BASES = [110017,130021,150041,170047,190027]')
source=source.replace('7c79a7f3522529a06a503b6b07e69236b08ad937',commit)
source=source.replace("t['line'] == 'Harness sponsorship'","t['line'] == 'Sponsors'")
(here/'analyse.py').write_text(source,encoding='utf-8')
print(json.dumps({k:v for k,v in pins.items() if k!='scratch_game_matches_main'},indent=2))
