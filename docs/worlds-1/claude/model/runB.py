import an, wm, json, time
out={}
opp=[("G0 today",an.g0()),("G1 rising 0.4",an.g_rising(0.4)),("G1 rising 0.6",an.g_rising(0.6)),("G1 rising 0.8",an.g_rising(0.8)),
     ("G3 2 elite 90-97",an.g_elite(2,90,97)),("G3 3 elite 89-96",an.g_elite(3,89,96)),("G4 anchored",an.g_anchored())]
nat=[("G2 nations r0.5",dict(rise=0.5)),("G2 nations r0.7",dict(rise=0.7)),("G2 nations r0.7 amp6",dict(rise=0.7,amp=6.0))]
for name in ['p4-d','p4-h']:
    cs=an.load(name)
    for lab,ff in opp:
        t=time.time(); m=an.career_metrics(cs,wm.fmt_today,ff,draws=120,seed=5); out[f"{name}|{lab}"]=m
        print(f"{name:5} {lab:22} first {m['first_title']:5.2f} attain {m['attain']:5.1f} late {m['late_rate']:.2f} dead {m['dead_share']:.2f} ({time.time()-t:.0f}s)",flush=True)
    for lab,kw in nat:
        t=time.time(); m=an.career_metrics(cs,wm.fmt_today,None,draws=120,seed=5,nations_kw=kw); out[f"{name}|{lab}"]=m
        print(f"{name:5} {lab:22} first {m['first_title']:5.2f} attain {m['attain']:5.1f} late {m['late_rate']:.2f} dead {m['dead_share']:.2f} ({time.time()-t:.0f}s)",flush=True)
json.dump(out,open('resB.json','w'),indent=1)
