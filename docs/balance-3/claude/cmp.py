import csv,sys,statistics as st,collections
def row(label,d):
    car=list(csv.DictReader(open(d+'/careers.tsv'),delimiter='\t')); sea=list(csv.DictReader(open(d+'/seasons.tsv'),delimiter='\t'))
    out=[]
    for arm in ['no_harness','harness_first','development_first']:
        r=[x for x in car if x['arm']==arm]; w=[20 if x['right_censored']=='1' else min(20,int(x['first_title_season'])) for x in r]
        out.append(st.mean(w))
    s=[x for x in sea if x['arm']=='no_harness']; r=[x for x in car if x['arm']=='no_harness']
    rel=sum(int(x['tier_post_rollover'])<int(x['tier_pre_rollover']) for x in s)/len(r)
    inc=st.mean(int(x['cc_in']) for x in s); b10=st.mean(int(x['cc_post_rollover']) for x in s if int(x['elapsed_season'])==10)
    t=sum(x['right_censored']=='0' for x in r)
    # per-base N wait
    pb=collections.defaultdict(list)
    for x in r: pb[x['base']].append(20 if x['right_censored']=='1' else min(20,int(x['first_title_season'])))
    print(f"{label:22} N {out[0]:5.2f}  H {out[1]:5.2f}  D {out[2]:5.2f}  titles {t}/{len(r)}  releg {rel:.2f}  inc {inc:4.0f}  bank10 {b10:4.0f}  perbaseN {[round(st.mean(v),1) for v in pb.values()]}")
for a in sys.argv[1:]:
    l,d=a.split('=',1); row(l,d)
