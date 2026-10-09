from pathlib import Path
import subprocess, shutil
MAIN=Path('C:/Dev/RetroBuhurt')
PARENT=Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2')
ROOT=PARENT/'sponsor-gas'
assert not ROOT.exists()
subprocess.run(['git','worktree','add','--detach',str(ROOT),'7c79a7f'],cwd=MAIN,check=True)
subprocess.run(['git','apply',str(MAIN/'docs/harness-2/codex/r2-sponsor.patch')],cwd=ROOT,check=True)
shutil.copyfile(PARENT/'gas/scripts/melee/fighter_card.gd',ROOT/'scripts/melee/fighter_card.gd')
diff=subprocess.run(['git','diff','--','scripts/'],cwd=ROOT,check=True,capture_output=True).stdout
(MAIN/'docs/harness-2/codex/r2-sponsor-gas.patch').write_bytes(diff)
subprocess.run(['git','diff','--check'],cwd=ROOT,check=True)
code=(MAIN/'docs/harness-2/codex/work-r2/fixture-sponsor.gd').read_text()
gas=(MAIN/'docs/harness-2/codex/work-r2/fixture-gas.gd').read_text()
gasbody=gas[gas.index('\tf.harness = 4\n',gas.index('"uneven steps include Titanium"')):gas.index('\tprint("FIXTURE')]
code=code.replace('\tprint("FIXTURE',gasbody+'\tprint("FIXTURE')
(ROOT/'tools/probe_harness_r2_fixture.gd').write_text(code,encoding='utf-8',newline='\n')
(MAIN/'docs/harness-2/codex/work-r2/fixture-sponsor-gas.gd').write_text(code,encoding='utf-8',newline='\n')
