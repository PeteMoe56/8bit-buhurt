"""THE WORLDS VILLAGE, between week 1 (pools) and week 2 (the bracket). Pick ONE:
  physio  - clears your week-1 fatigue
  loan    - a star from an eliminated nation fights for you all week 2: +LOAN power
  film    - the federation's film on the strongest nation left: +FILM power against them only
Fatigue (assumed): every round fought in week 1 costs FAT power; the rest days give back REST.
It applies to every club, so only your own recovery is an edge."""
import an, wm, random, sys, statistics as st, json

def run_shop(careers, field_fn, FAT=0.6, REST=3.0, LOAN=2.0, FILM=4.0, sits=300, M=150, seed=21):
    rng = random.Random(seed)
    ent = [d for c in careers for d in an.entries(c)]
    rng.shuffle(ent)
    best = {"physio": 0, "loan": 0, "film": 0}; n = 0; gain = {"physio": [], "loan": [], "film": []}; pnone = []
    for d in ent:
        if n >= sits: break
        powers, me = field_fn(d, rng, {"season": d["season"], "titles": 0, "hunt": 0.0})
        r = wm.Run(powers, me, rng)
        rounds = {}
        def track(rr, c, base, info): return base
        ent_ids = list(range(len(powers)))
        quals, _ = r.pools(ent_ids, 4)
        if me not in quals: continue
        # rounds fought per club in week 1, from pool tables (rf+ra = rounds won by either side)
        fought = {}
        # recompute from the pool tables the Run kept? approximate: 3 bouts x expected rounds
        # use the player's own log for him, and 2.4 rounds a bout for the others
        my_rounds = 0
        for b in r.log:
            my_rounds += 2.4  # same expectation as everyone; fatigue spread comes from below
        fat = {c: max(0.0, FAT * (3 * rng.uniform(2.0, 3.0)) - REST) for c in ent_ids}
        n += 1
        alive_strong = max((c for c in quals if c != me), key=lambda c: powers[c])
        res = {}
        for opt in ["none", "physio", "loan", "film"]:
            w = 0
            for _ in range(M):
                rr = wm.Run(powers, me, rng)
                def pf(run, c, base, info, opt=opt):
                    p = base - fat[c]
                    if c == me:
                        if opt == "physio": p = base
                        if opt == "loan": p += LOAN
                    return p
                def pf2(run, c, base, info, opt=opt):
                    return pf(run, c, base, info)
                rr.power_fn = pf2
                # film: boost only in the bout against the target -> do it via opponent's power
                if opt == "film":
                    def pf3(run, c, base, info):
                        p = base - fat[c]
                        if c == alive_strong and info.get("vs_me"): p -= FILM
                        return p
                    rr.power_fn = pf3
                champ = bracket_vs(rr, quals, ent_ids)
                w += champ == me
            res[opt] = w / M
        pnone.append(res["none"])
        top = max(["physio", "loan", "film"], key=lambda o: (res[o], rng.random()))
        best[top] += 1
        for o in gain: gain[o].append(res[o] - res["none"])
    return n, best, {o: st.mean(v) for o, v in gain.items()}, st.mean(pnone)

def bracket_vs(r, quals, seed_order):
    # the bracket, telling power_fn when a bout involves the player
    me = r.me
    orig = r.bout
    def bout(a, b, info):
        info = dict(info); info["vs_me"] = me in (a, b)
        return orig(a, b, info)
    r.bout = bout
    return r.bracket(quals, seed_order)

if __name__ == "__main__":
    out = {}
    for name in ["p4-d", "p4-h"]:
        cs = an.load(name)
        for lab, ff in [("G0", an.st_g0), ("E1 1 elite (after title)", lambda d, rng, s: an.make_field(d["pp"], [rng.randint(91, 98)] + [rng.randint(68, 88) for _ in range(14)]))]:
            for FAT, LOAN, FILM in [(0.6, 2.0, 4.0), (0.8, 2.0, 5.0), (0.5, 1.5, 5.0)]:
                n, best, gain, p0 = run_shop(cs, ff, FAT=FAT, LOAN=LOAN, FILM=FILM)
                share = {k: v / n for k, v in best.items()}
                print(f"{name} {lab:26} fat {FAT} loan {LOAN} film {FILM}: P(title) no item {p0:.2f}; best pick share " + " ".join(f"{k} {v:.0%}" for k, v in share.items()) + "; mean gain " + " ".join(f"{k} {v:+.3f}" for k, v in gain.items()), flush=True)
                out[f"{name}|{lab}|{FAT}|{LOAN}|{FILM}"] = {"n": n, "share": share, "gain": gain, "p0": p0}
    json.dump(out, open("resS.json", "w"), indent=1)
