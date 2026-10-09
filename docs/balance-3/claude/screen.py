import json,subprocess,os,time,sys
L=[('L1','scripts/game/career.gd','LEVEL_XP: int = 8',6,11),
('L2','scripts/game/career.gd','XP_BOUT: int = 2',1,4),
('L3','scripts/game/career.gd','RAISE_COST_PER: int = 4',2,6),
('L4','scripts/game/career.gd','POINTS_PER_LEVEL: int = 3',2,4),
('L5','scripts/league/season.gd','CREDITS_WIN: int = 2',1,4),
('L6','scripts/league/season.gd','CREDITS_PROMOTED: int = 4',2,10),
('L7','scripts/league/season.gd','PURSE_TOP: int = 6',3,10),
('L8','scripts/league/league_world.gd','RATING_SCALE: float = 22.0',16.0,30.0),
('L9','scripts/league/season_cups.gd','CUP_TIE_SHARE := 0.06',0.03,0.12),
('L10','scripts/league/club_event.gd','GATE_K: float = 0.16',0.10,0.24),
('L11','scripts/league/arena.gd','GATE_PER_LEVEL: float = 0.35',0.20,0.50),
('L12','scripts/game/career.gd','DECLINE_RATE: float = 0.30',0.20,0.45),
('L13','scripts/game/career.gd','PRACTICE_PER_GRADE: float = 2.6',1.6,3.6),
('L14','scripts/league/club_office.gd','SESSION_SHARE: float = 0.12',0.06,0.20)]
jobs=[('base','[]')]
for lid,f,txt,lo,hi in L:
    key,val=txt.rsplit(' ',1)
    for tag,v in (('lo',lo),('hi',hi)):
        jobs.append((f'{lid}{tag}',json.dumps([[f,'^const '+key.replace('.','\\.')+' '+val.replace('.','\\.')+r'\b','const '+key+' '+str(v)]])))
# wait for gate
while True:
    g='/tmp/claude-0/gate3.log'
    if os.path.exists(g) and 'SUITE' in open(g).read(): break
    time.sleep(30)
running=[]
for name,spec in jobs:
    while len(running)>=2:
        running=[p for p in running if p.poll() is None]; time.sleep(5)
    running.append(subprocess.Popen(['bash','/home/claude/b3/run_variant.sh',name,spec,'3']))
    time.sleep(2)
for p in running: p.wait()
print('ALL DONE', time.strftime('%H:%M'))
