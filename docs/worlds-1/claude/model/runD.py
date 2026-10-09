import an, wm, json, time
out={}
F=[("W0 today",wm.fmt_today,15),("W1 32 clubs",wm.fmt_32,31),("W2 second group",wm.fmt_second_group,15),("W5 winners choose",wm.fmt_choose,15)]
def g0n(n):
    return lambda d,rng,s: an.make_field(d["pp"],[rng.randint(68,88) for _ in range(n)])
O=lambda n:[("G0",g0n(n),None),("E1 1 elite",an.st_elite_after(1,91,98,n=n),None),
     ("E2 hunted +3/-2 top2",an.st_hunted(k=2,n=n),an.hunt_update(3,2,12)),("E3 late rise 0.8",an.st_late_rise(12,0.8,n=n),None)]
for name in ['p4-d','p4-h']:
    cs=an.load(name)
    for fl,f,n in F:
        for ol,ff,ex in O(n):
            t=time.time(); m=an.career_paths(cs,f,ff,R=30,seed=17,extra=ex); out[f"{name}|{fl}|{ol}"]=m
            print(f"{name:5} {fl:18} {ol:22} first {m['first_title']:5.2f} attain {m['attain']:5.1f} late {m['late_rate']:.2f} titles {m['titles']:.1f} dead {m['dead_share']:.2f} bouts {m['bouts']:.1f}",flush=True)
json.dump(out,open('resD.json','w'),indent=1)
