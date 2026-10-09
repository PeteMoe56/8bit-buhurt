"""Returning rivals: 15 persistent nations per career, today's power band, each with its own
generation cycle (a golden generation rises and fades). Option: after the player's first Worlds
title the strongest nation that year is lifted to the elite band (the superpower is a rival you
already know, not a stranger). Measures pacing, late title rate and how often rivals recur."""
import an, wm, random, math, statistics as st, collections, sys

class Rivals:
    def __init__(self, rng, amp=5.0):
        self.rng = rng
        self.mid = [rng.uniform(72, 84) for _ in range(15)]
        self.amp = [rng.uniform(amp * 0.5, amp) for _ in range(15)]
        self.per = [rng.uniform(6, 12) for _ in range(15)]
        self.ph = [rng.uniform(0, 2 * math.pi) for _ in range(15)]
    def power(self, i, season):
        p = self.mid[i] + self.amp[i] * math.sin(2 * math.pi * season / self.per[i] + self.ph[i]) + self.rng.gauss(0, 1.5)
        return int(round(max(66, min(90, p))))

def run(careers, elite, R=30, seed=5):
    rng = random.Random(seed)
    first = []; lw = ln = 0; ko_repeat = []; final_opp = collections.Counter(); finals = 0; nem = []
    for c in careers:
        ent = an.entries(c)
        for _ in range(R):
            riv = Rivals(random.Random(rng.random()))
            titles = 0; f = None; prev_ko = set(); beaten_by = collections.Counter()
            for d in ent:
                s = d["season"]
                g = [riv.power(i, s) for i in range(15)]
                if elite and titles > 0:
                    top = max(range(15), key=lambda i: g[i]); g[top] = rng.randint(91, 98)
                allp = [d["pp"]] + g
                order = sorted(range(16), key=lambda i: -allp[i])
                powers = [allp[i] for i in order]; me = order.index(0)
                r = wm.Run(powers, me, rng)
                champ = wm.fmt_today(r, powers)
                ko = {order[b["opp"]] - 1 for b in r.log if b["elim"]}
                if prev_ko: ko_repeat.append(len(ko & prev_ko) > 0)
                prev_ko = ko
                for b in r.log:
                    if not b["won"] and b["elim"]: beaten_by[order[b["opp"]] - 1] += 1
                if r.finish in ("champion", "runner-up"):
                    finals += 1
                if 15 <= s <= 20: ln += 1; lw += champ == me
                if champ == me:
                    titles += 1; f = f or s
            first.append(f or 20)
            nem.append(beaten_by.most_common(1)[0][1] if beaten_by else 0)
    return st.mean(first), lw / ln, st.mean(ko_repeat), st.mean(nem)

for name in ["p4-d", "p4-h"]:
    cs = an.load(name)
    for lab, el in [("rivals, no elite", False), ("rivals + strongest rival lifted after 1st title", True)]:
        ft, late, rep, nem = run(cs, el)
        print(f"{name} {lab:48} first {ft:5.2f} late {late:.2f}  knockout rematch next year {rep:.0%}  most knockout defeats by one rival/career {nem:.1f}")
