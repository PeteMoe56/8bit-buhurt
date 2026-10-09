import an, wm, json, sys, time
out={}
designs=[("W0 today",wm.fmt_today,an.field_logged),("W1 32 clubs",wm.fmt_32,an.g0(31)),
 ("W2 second group",wm.fmt_second_group,an.field_logged),("W3 double elim",wm.fmt_double,an.field_logged),
 ("W4 bo3 final",wm.fmt_bo3_final,an.field_logged),("W5 winners choose",wm.fmt_choose,an.field_logged)]
for name in ['p4-d','p4-h']:
    cs=an.load(name)
    for lab,f,ff in designs:
        t=time.time(); m=an.career_metrics(cs,f,ff,draws=150,seed=3)
        out[f"{name}|{lab}"]=m
        print(f"{name:5} {lab:18} first {m['first_title']:5.2f} attain {m['attain']:5.1f}/{m['n']} late {m['late_rate']:.2f} dead {m['dead_share']:.2f} bouts {m['bouts']:.1f}  ({time.time()-t:.0f}s)",flush=True)
json.dump(out,open('resA.json','w'),indent=1)
