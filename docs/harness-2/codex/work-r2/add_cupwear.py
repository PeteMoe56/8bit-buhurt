from pathlib import Path
import subprocess, shutil
MAIN=Path('C:/Dev/RetroBuhurt')
ROOT=Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2/cupwear')
assert not ROOT.exists()
subprocess.run(['git','worktree','add','--detach',str(ROOT),'7c79a7f'],cwd=MAIN,check=True)
subprocess.run(['git','apply',str(MAIN/'docs/harness-2/codex/value.patch')],cwd=ROOT,check=True)
p=ROOT/'scripts/league/season_cups.gd'
s=p.read_text(encoding='utf-8')
old='''\tvar res: Array = s.world.quick_bout(pa, pb)
\tc.record(m, int(res[0]), int(res[1]), int(res[2]), int(res[3]))
\ts._finish_cup_round(c, int(m.get("winner", -1)) == s.world.player_club,
\t\tint(m.get("winner", -1)) == -1)'''
assert s.count(old)==1
s=s.replace(old,old+'''\n\t## Experiment: quick cup ties carry the same kit wear as fought ties.
\tSeasonBouts.bout_wear(s)
\ts.sync_power()''')
p.write_text(s,encoding='utf-8',newline='\n')
diff=subprocess.run(['git','diff','--','scripts/'],cwd=ROOT,check=True,capture_output=True).stdout
(MAIN/'docs/harness-2/codex/r2-cupwear.patch').write_bytes(diff)
subprocess.run(['git','diff','--check'],cwd=ROOT,check=True)
shutil.copyfile(MAIN/'docs/harness-2/codex/work-r2/fixture-control.gd',ROOT/'tools/probe_harness_r2_fixture.gd')
