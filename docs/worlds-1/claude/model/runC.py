import an, wm, json, time
out={}
D=[("G0 today",an.st_g0,None),
   ("E1 2 elite after 1st title",an.st_elite_after(2,90,97),None),
   ("E1 1 elite after 1st title",an.st_elite_after(1,91,98),None),
   ("E2 hunted +3/-1 top3",an.st_hunted(k=3),an.hunt_update(3,1,12)),
   ("E2 hunted +4/-1 top3",an.st_hunted(k=3),an.hunt_update(4,1,14)),
   ("E2 hunted +3/-2 top2",an.st_hunted(k=2),an.hunt_update(3,2,12)),
   ("E3 late rise 12, 0.8",an.st_late_rise(12,0.8),None),
   ("E3 late rise 12, 1.2",an.st_late_rise(12,1.2),None)]
for name in ['p4-d','p4-h']:
    cs=an.load(name)
    for lab,ff,ex in D:
        t=time.time(); m=an.career_paths(cs,wm.fmt_today,ff,R=40,seed=13,extra=ex); out[f"{name}|{lab}"]=m
        print(f"{name:5} {lab:28} first {m['first_title']:5.2f} attain {m['attain']:5.1f} late {m['late_rate']:.2f} titles {m['titles']:.1f} dead {m['dead_share']:.2f} ({time.time()-t:.0f}s)",flush=True)
json.dump(out,open('resC.json','w'),indent=1)
