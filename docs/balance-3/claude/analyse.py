import csv,sys,os,statistics as st
ROOT='/home/claude/b3'
def load(name):
    d=None
    for c in [f'{ROOT}/wt-{name}/docs/bakeoff-2/harness/b3-{name}']:
        if os.path.isdir(c): d=c
    if not d: return None
    car=list(csv.DictReader(open(d+'/careers.tsv'),delimiter='\t'))
    sea=list(csv.DictReader(open(d+'/seasons.tsv'),delimiter='\t'))
    out={}
    for arm in ['no_harness','development_first']:
        r=[x for x in car if x['arm']==arm]
        w=[20 if x['right_censored']=='1' else min(20,int(x['first_title_season'])) for x in r]
        s=[x for x in sea if x['arm']==arm]
        bank=lambda k: st.mean(int(x['cc_post_rollover']) for x in s if int(x['elapsed_season'])==k)
        rel=sum(1 for x in s if int(x['tier_post_rollover'])<int(x['tier_pre_rollover']))/len(r)
        out[arm]=dict(wait=st.mean(w),titles=sum(x['right_censored']=='0' for x in r),n=len(r),
            inc=st.mean(int(x['cc_in']) for x in s),b5=bank(5),b10=bank(10),b20=bank(20),rel=rel)
    return out
names=sys.argv[1:]
print(f"{'variant':18} {'N wait':>7} {'D wait':>7} {'D-N':>6} {'inc':>6} {'bank5':>6} {'bank10':>7} {'bank20':>7} {'releg':>5}")
for nm in names:
    o=load(nm)
    if not o: print(nm,'missing'); continue
    N,D=o['no_harness'],o['development_first']
    print(f"{nm:18} {N['wait']:7.2f} {D['wait']:7.2f} {D['wait']-N['wait']:+6.2f} {N['inc']:6.0f} {N['b5']:6.0f} {N['b10']:7.0f} {N['b20']:7.0f} {N['rel']:5.2f}  titles {N['titles']}/{N['n']}")
