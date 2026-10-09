import json,subprocess,time,itertools
F={'A':('scripts/league/season.gd','CREDITS_WIN: int =','2','4'),
   'B':('scripts/league/season.gd','PURSE_TOP: int =','6','10'),
   'C':('scripts/league/league_world.gd','RATING_SCALE: float =','22.0','30.0'),
   'D':('scripts/league/arena.gd','GATE_PER_LEVEL: float =','0.35','0.50'),
   'E':('scripts/game/career.gd','DECLINE_RATE: float =','0.30','0.20'),
   'F':('scripts/game/career.gd','PRACTICE_PER_GRADE: float =','2.6','3.6')}
runs=[]
for a,b,c,d in itertools.product([0,1],repeat=4):
    e=(a+b+c)%2; f=(b+c+d)%2
    lv=dict(A=a,B=b,C=c,D=d,E=e,F=f)
    name='F'+''.join(k for k in 'ABCDEF' if lv[k]) if any(lv.values()) else 'F0'
    spec=[[F[k][0],'^const '+F[k][1].replace('.','\\.')+' '+F[k][2].replace('.','\\.')+r'\b','const '+F[k][1]+' '+F[k][3]] for k in 'ABCDEF' if lv[k]]
    runs.append((name,json.dumps(spec)))
json.dump([r[0] for r in runs],open('/home/claude/b3/factorial_names.json','w'))
running=[]
for name,spec in runs:
    if name=='F0': continue   # F0 == base
    while len(running)>=2:
        running=[p for p in running if p.poll() is None]; time.sleep(5)
    running.append(subprocess.Popen(['bash','/home/claude/b3/run_variant.sh',name,spec,'3'])); time.sleep(2)
for p in running: p.wait()
print('ALL DONE',time.strftime('%H:%M'))
