import json, random, math, statistics as st, sys, collections
import wm

GUEST_LO, GUEST_HI = 68, 88


def load(name):
    worlds = collections.OrderedDict()
    res = {}
    for line in open(f"/home/claude/wl/{name}.worlds"):
        tag, js = line.split(" ", 1)
        d = json.loads(js)
        if tag == "WORLDS_LOG":
            worlds.setdefault(d["w"], {})[d["season"]] = d
        else:
            res[(d["w"], d["season"])] = d
    careers = []
    for w, seasons in worlds.items():
        c = []
        for s in sorted(seasons):
            d = seasons[s]
            r = res.get((w, s), {})
            d = dict(d)
            d["champ"] = bool(r.get("champ", False)) and d["me"] != -1
            d["label"] = r.get("label", "")
            c.append(d)
        careers.append(c)
    return careers


def entries(career):
    return [d for d in career if d["me"] != -1]


# ------------------------------------------------------------------ fields
def field_logged(d, rng, season):
    return list(d["field"]), d["ids"].index(d["me"])


def make_field(pp, guests):
    allp = [pp] + guests
    order = sorted(range(len(allp)), key=lambda i: -allp[i])  # stable like sort_custom (ties arbitrary)
    powers = [allp[i] for i in order]
    return powers, order.index(0)


def g0(n=15):
    def f(d, rng, season):
        return make_field(d["pp"], [rng.randint(GUEST_LO, GUEST_HI) for _ in range(n)])
    return f


def g_rising(per_season=0.6, n=15):
    def f(d, rng, season):
        s = per_season * (season - 1)
        return make_field(d["pp"], [min(99, int(round(rng.randint(GUEST_LO, GUEST_HI) + s))) for _ in range(n)])
    return f


def g_elite(k=2, lo=90, hi=97, n=15):
    def f(d, rng, season):
        g = [rng.randint(lo, hi) for _ in range(k)] + [rng.randint(GUEST_LO, GUEST_HI) for _ in range(n - k)]
        return make_field(d["pp"], g)
    return f


def g_anchored(lo=-14, hi=4, n=15):
    def f(d, rng, season):
        return make_field(d["pp"], [max(40, min(99, d["pp"] + rng.randint(lo, hi))) for _ in range(n)])
    return f


class Nations:
    """Fifteen persistent rival nations per career. Each has a strength that drifts toward a
    rising world level with its own cycle (a golden generation comes and goes)."""

    def __init__(self, rng, n=15, start_lo=70, start_hi=88, world0=79.0, rise=0.5, pull=0.25, sd=2.5, amp=4.0):
        self.rng = rng
        self.n = n; self.rise = rise; self.pull = pull; self.sd = sd; self.amp = amp; self.world0 = world0
        self.base = [rng.uniform(start_lo, start_hi) for _ in range(n)]
        self.phase = [rng.uniform(0, 2 * math.pi) for _ in range(n)]
        self.period = [rng.uniform(6, 12) for _ in range(n)]
        self.season = 1
        self.off = [b - world0 for b in self.base]

    def powers(self, season):
        while self.season < season:
            self.season += 1
            for i in range(self.n):
                self.off[i] += self.pull * (0 - self.off[i]) * 0.5 + self.rng.gauss(0, self.sd * 0.5)
        world = self.world0 + self.rise * (season - 1)
        return [int(round(max(55, min(99, world + self.off[i] + self.amp * math.sin(2 * math.pi * season / self.period[i] + self.phase[i])))))
                for i in range(self.n)]


# ------------------------------------------------------------------ replay
def run_once(fmt, powers, me, rng, power_fn=None, scale=wm.RATING_SCALE):
    r = wm.Run(powers, me, rng, scale=scale, power_fn=power_fn)
    champ = fmt(r, powers)
    return r, champ


def p_title(fmt, d, field_fn, season, draws, rng, power_fn=None, nations=None):
    wins = 0; bouts = 0; dead = 0; pool_bouts = 0; elim = 0; finals = 0
    for _ in range(draws):
        if nations is not None:
            powers, me = make_field(d["pp"], nations.powers(season) if False else nations_cache[season])
        else:
            powers, me = field_fn(d, rng, season)
        r, champ = run_once(fmt, powers, me, rng, power_fn)
        wins += champ == me
        bouts += len(r.log)
        pool_bouts += sum(1 for b in r.log if not b["elim"] and b["stage"] == "pool")
        dead += sum(1 for b in r.log if b["dead"])
        elim += sum(1 for b in r.log if b["elim"])
        finals += r.finish in ("champion", "runner-up")
    return {"p": wins / draws, "bouts": bouts / draws, "dead": dead, "pool_bouts": pool_bouts, "elim": elim / draws, "final": finals / draws}


nations_cache = {}


def career_metrics(careers, fmt, field_fn=None, draws=400, seed=1, power_fn=None, nations_kw=None):
    """Per career: P(title) at every entry, then the restricted mean first-title time (20 for
    none), attainment, late title rate, dead rubbers. Nations designs draw one nation history per
    career per replicate set (kept small: draws spread over 8 histories)."""
    rng = random.Random(seed)
    times = []; attained = []; late_p = []; dead = 0; poolb = 0; bouts = []; first_entry = []
    for c in careers:
        ent = entries(c)
        if not ent:
            times.append(20.0); attained.append(0.0); continue
        if nations_kw is not None:
            # average over histories: compute p per entry per history, then the expectation
            H = 8; per = draws // H
            pk_hist = []
            for h in range(H):
                nat = Nations(random.Random(rng.random()), **nations_kw)
                pks = []
                for d in ent:
                    g = nat.powers(d["season"])
                    w = 0
                    for _ in range(per):
                        powers, me = make_field(d["pp"], g)
                        r, champ = run_once(fmt, powers, me, rng, power_fn)
                        w += champ == me
                        dead += sum(1 for b in r.log if b["dead"]); poolb += sum(1 for b in r.log if b["stage"] == "pool")
                        bouts.append(len(r.log))
                    pks.append(w / per)
                pk_hist.append(pks)
            T = []; A = []
            for pks in pk_hist:
                t, a = first_time(ent, pks); T.append(t); A.append(a)
            times.append(st.mean(T)); attained.append(st.mean(A))
            pk = [st.mean(x) for x in zip(*pk_hist)]
        else:
            pk = []
            for d in ent:
                m = p_title(fmt, d, field_fn, d["season"], draws, rng, power_fn)
                pk.append(m["p"]); dead += m["dead"]; poolb += m["pool_bouts"]; bouts.append(m["bouts"])
            t, a = first_time(ent, pk); times.append(t); attained.append(a)
        late_p += [p for d, p in zip(ent, pk) if 15 <= d["season"] <= 20]
        first_entry.append(ent[0]["season"])
    return {
        "first_title": st.mean(times),
        "attain": sum(attained),
        "n": len(careers),
        "late_rate": st.mean(late_p) if late_p else float("nan"),
        "dead_share": dead / poolb if poolb else 0.0,
        "bouts": st.mean(bouts) if bouts else 0.0,
        "first_entry": st.mean(first_entry) if first_entry else float("nan"),
    }


def first_time(ent, pk):
    surv = 1.0; t = 0.0
    for d, p in zip(ent, pk):
        t += surv * p * d["season"]
        surv *= 1 - p
    return t + surv * 20.0, 1 - surv


# ------------------------------------------------------- stateful career paths
def career_paths(careers, fmt, field_state, R=60, seed=9, power_fn=None, extra=None):
    """Each career walked R times; `field_state(d, rng, state)` returns (powers, me) and may
    read state['titles'], state['last_title'], state['season']. Records first title, late title
    rate, dead rubbers, bouts."""
    rng = random.Random(seed)
    times = []; att = 0; late_w = late_n = 0; dead = poolb = 0; bouts = 0; tours = 0; titles_per = []
    for c in careers:
        ent = entries(c)
        for _ in range(R):
            state = {"titles": 0, "last_title": None, "streak": 0, "hunt": 0.0}
            first = None
            for d in ent:
                state["season"] = d["season"]
                powers, me = field_state(d, rng, state)
                r, champ = run_once(fmt, powers, me, rng, power_fn)
                won = champ == me
                tours += 1; bouts += len(r.log)
                dead += sum(1 for b in r.log if b["dead"]); poolb += sum(1 for b in r.log if b["stage"] == "pool")
                if 15 <= d["season"] <= 20:
                    late_n += 1; late_w += won
                if won:
                    state["titles"] += 1; state["last_title"] = d["season"]; state["streak"] += 1
                    if first is None:
                        first = d["season"]
                else:
                    state["streak"] = 0
                if extra:
                    extra(state, won)
            times.append(first if first else 20); att += first is not None
            titles_per.append(state["titles"])
    n = len(careers)
    return {"first_title": st.mean(times), "attain": att / R, "n": n, "late_rate": late_w / late_n if late_n else float('nan'),
            "dead_share": dead / poolb if poolb else 0, "bouts": bouts / tours if tours else 0, "titles": st.mean(titles_per)}


def st_g0(d, rng, state):
    return make_field(d["pp"], [rng.randint(GUEST_LO, GUEST_HI) for _ in range(15)])


def st_elite_after(k=2, lo=90, hi=97, n=15):
    def f(d, rng, state):
        g = [rng.randint(GUEST_LO, GUEST_HI) for _ in range(n)]
        if state["titles"] > 0:
            for i in range(k):
                g[i] = rng.randint(lo, hi)
        return make_field(d["pp"], g)
    return f


def st_hunted(step=3.0, decay=1.0, k=3, n=15, cap=99):
    """THE HUNTED CHAMPION. Every Worlds the player wins, the top k nations raise their game by
    `step` (they study your film, their federations invest); every year you don't win, the
    pressure eases by `decay`. Applied on top of today's guest draw."""
    def f(d, rng, state):
        g = sorted([rng.randint(GUEST_LO, GUEST_HI) for _ in range(n)], reverse=True)
        for i in range(k):
            g[i] = min(cap, int(round(g[i] + state["hunt"])))
        return make_field(d["pp"], g)
    return f


def hunt_update(step, decay, maxh=99):
    def u(state, won):
        state["hunt"] = min(maxh, state["hunt"] + step) if won else max(0.0, state["hunt"] - decay)
    return u


def st_late_rise(start=12, per=0.8, n=15):
    def f(d, rng, state):
        s = per * max(0, state["season"] - start)
        return make_field(d["pp"], [min(99, int(round(rng.randint(GUEST_LO, GUEST_HI) + s))) for _ in range(n)])
    return f
