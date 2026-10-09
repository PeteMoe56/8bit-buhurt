"""Worlds format model: a port of LeagueWorld.quick_bout/_draw_margin, League tables and Cup.

Clubs are indices into a `powers` list that is already seeded best first (as _build_worlds sorts).
`hooks` lets a design change a club's power for a given bout (fatigue, shop items).
"""
import random

RATING_SCALE = 22.0
DRAW_ROUND = 0.06
MARGIN_W = [8, 14, 26, 52]


def margin(edge, rng):
    w = MARGIN_W[:]
    tilt = max(-1.0, min(1.0, (edge - 0.5) * 2.0))
    w[3] = int(max(1.0, w[3] * (1.0 + tilt * 0.6)))
    w[0] = int(max(1.0, w[0] * (1.0 - tilt * 0.6)))
    r = rng.randint(0, sum(w) - 1)
    for i, x in enumerate(w):
        r -= x
        if r < 0:
            return i + 1
    return 4


def quick_bout(pa, pb, rng, scale=RATING_SCALE):
    p = 1.0 / (1.0 + 10 ** ((pb - pa) / scale))
    ra = rb = ma = mb = 0
    for _ in range(3):
        if ra >= 2 or rb >= 2:
            break
        if rng.random() < DRAW_ROUND:
            continue
        if rng.random() < p:
            ra += 1; ma += margin(p, rng)
        else:
            rb += 1; mb += margin(1.0 - p, rng)
    return ra, rb, ma, mb


def p_win_bout(pa, pb, scale=RATING_SCALE):
    """Probability a knockout bout goes to a (estimated quickly by enumeration-free MC elsewhere)."""
    p = 1.0 / (1.0 + 10 ** ((pb - pa) / scale))
    return p


def new_row(c, rng):
    return {"club": c, "lots": rng.randint(0, 1_000_000), "pts": 0, "rf": 0, "ra": 0, "mf": 0, "ma": 0, "pl": 0}


def apply(row, rf, ra, mf, ma):
    row["pl"] += 1; row["rf"] += rf; row["ra"] += ra; row["mf"] += mf; row["ma"] += ma
    row["pts"] += 3 if rf > ra else (1 if rf == ra else 0)


def sort_table(rows):
    return sorted(rows, key=lambda r: (-r["pts"], -(r["mf"] - r["ma"]), -(r["rf"] - r["ra"]), -r["rf"], -r["lots"], r["club"]))


def fixtures(ids):
    """League.fixtures circle method."""
    ids = list(ids)
    if len(ids) % 2:
        ids.append(None)
    n = len(ids); out = []
    for _ in range(n - 1):
        day = [(ids[i], ids[n - 1 - i]) for i in range(n // 2) if ids[i] is not None and ids[n - 1 - i] is not None]
        out.append(day)
        last = ids.pop(); ids.insert(1, last)
    return out


def snake(entrants, n_pools):
    pools = [[] for _ in range(n_pools)]
    i, fwd = 0, True
    for c in entrants:
        pools[i].append(c)
        if fwd:
            i += 1
            if i >= n_pools:
                i, fwd = n_pools - 1, False
        else:
            i -= 1
            if i < 0:
                i, fwd = 0, True
    return pools


class Run:
    """One tournament. Records the player's bouts with their context."""

    def __init__(self, powers, me, rng, scale=RATING_SCALE, power_fn=None):
        self.p = list(powers)
        self.me = me
        self.rng = rng
        self.scale = scale
        self.power_fn = power_fn  # (club, stage_info) -> power
        self.log = []  # player's bouts: dict(stage, opp, won, dead)
        self.bouts_played = {}  # club -> count
        self.finish = None

    def pw(self, c, info):
        base = self.p[c]
        return self.power_fn(self, c, base, info) if self.power_fn else base

    def bout(self, a, b, info):
        res = quick_bout(self.pw(a, info), self.pw(b, info), self.rng, self.scale)
        self.bouts_played[a] = self.bouts_played.get(a, 0) + 1
        self.bouts_played[b] = self.bouts_played.get(b, 0) + 1
        return res

    def ko(self, a, b, info, seed_order):
        ra, rb, ma, mb = self.bout(a, b, info)
        if ra != rb:
            w = a if ra > rb else b
        elif ma != mb:
            w = a if ma > mb else b
        else:
            w = a if seed_order.index(a) < seed_order.index(b) else b
        if self.me in (a, b):
            self.log.append({"stage": info.get("stage"), "opp": b if a == self.me else a, "won": w == self.me, "dead": False, "elim": True})
        return w

    # ---------------------------------------------------------------- pools
    def pools(self, entrants, n_pools, stage="pool", advance=2):
        pools = snake(entrants, n_pools)
        tables = [{c: new_row(c, self.rng) for c in pl} for pl in pools]
        days = [fixtures(pl) for pl in pools]
        nd = max(len(d) for d in days)
        for d in range(nd):
            for pi, pl in enumerate(pools):
                if d >= len(days[pi]):
                    continue
                for a, b in days[pi][d]:
                    dead = False
                    if self.me in (a, b):
                        dead = self._settled(tables[pi], days[pi][d:], advance)
                    ra, rb, ma, mb = self.bout(a, b, {"stage": stage, "day": d})
                    apply(tables[pi][a], ra, rb, ma, mb)
                    apply(tables[pi][b], rb, ra, mb, ma)
                    if self.me in (a, b):
                        mine = (ra > rb) if a == self.me else (rb > ra)
                        self.log.append({"stage": stage, "day": d, "opp": b if a == self.me else a, "won": mine, "drawn": ra == rb, "dead": dead, "elim": False})
        order = [sort_table(list(t.values())) for t in tables]
        quals = []
        for place in range(advance):
            for rows in order:
                quals.append(rows[place]["club"])
        if self.me in entrants and self.me not in quals:
            self.finish = "pools" if stage == "pool" else stage
        return quals, order

    def _settled(self, table, remaining_days, advance):
        """Is the player's qualification already decided on points alone, whatever happens
        in the pool's remaining bouts (ties counted as undecided)?"""
        me = self.me
        rem = [m for day in remaining_days for m in day]
        cur = {c: r["pts"] for c, r in table.items()}
        mx = {c: cur[c] + 3 * sum(1 for m in rem if c in m) for c in cur}
        mn = dict(cur)
        others = [c for c in cur if c != me]
        # DEAD only if the player's whole place is fixed: nobody's reachable points can tie or
        # cross his (finishing first or second picks the quarter-final opponent, so it matters)
        return all(mn[c] > mx[me] or mx[c] < mn[me] for c in others)
        # surely through: fewer than `advance` others can reach or pass my minimum
        can_catch = sum(1 for c in others if mx[c] >= mn[me])
        if can_catch < advance:
            return True
        # surely out: at least `advance` others already sit strictly above my maximum
        above = sum(1 for c in others if mn[c] > mx[me])
        return above >= advance

    # -------------------------------------------------------------- bracket
    def bracket(self, quals, seed_order, third=True, stage_prefix="ko", final_bo3=False):
        field = list(quals)
        names = {16: "r16", 8: "qf", 4: "sf", 2: "final"}
        sf_losers = []
        while len(field) > 1:
            n = len(field)
            stage = names.get(n, "r%d" % n)
            winners, losers = [], []
            for i in range(n // 2):
                a, b = field[i], field[n - 1 - i]
                if stage == "final" and final_bo3:
                    w = self._series(a, b, seed_order)
                else:
                    w = self.ko(a, b, {"stage": stage}, seed_order)
                winners.append(w); losers.append(b if w == a else a)
                if self.me in (a, b) and w != self.me:
                    self.finish = stage
            if n == 4:
                sf_losers = losers
            field = winners
        champ = field[0]
        if third and len(sf_losers) == 2:
            bw = self.ko(sf_losers[0], sf_losers[1], {"stage": "bronze"}, seed_order)
            if self.me in sf_losers:
                self.finish = "third" if bw == self.me else "fourth"
        if champ == self.me:
            self.finish = "champion"
        elif self.finish == "final":
            self.finish = "runner-up"
        return champ

    def _series(self, a, b, seed_order):
        wa = wb = 0
        while wa < 2 and wb < 2:
            w = self.ko(a, b, {"stage": "final"}, seed_order)
            if w == a:
                wa += 1
            else:
                wb += 1
        return a if wa == 2 else b

    def double_elim(self, quals, seed_order):
        """Eight-club double elimination with a bracket reset in the grand final."""
        n = len(quals)
        qf = [(quals[i], quals[n - 1 - i]) for i in range(n // 2)]
        wq = []; lq = []
        for a, b in qf:
            w = self.ko(a, b, {"stage": "wb-qf"}, seed_order); wq.append(w); lq.append(b if w == a else a)
        # winners' semis: 0v3, 1v2 like the bracket
        ws, ls = [], []
        for a, b in [(wq[0], wq[3]), (wq[1], wq[2])]:
            w = self.ko(a, b, {"stage": "wb-sf"}, seed_order); ws.append(w); ls.append(b if w == a else a)
        wf = self.ko(ws[0], ws[1], {"stage": "wb-final"}, seed_order)
        wf_loser = ws[1] if wf == ws[0] else ws[0]
        out = set()
        # losers' round 1
        l1 = []
        for a, b in [(lq[0], lq[3]), (lq[1], lq[2])]:
            w = self.ko(a, b, {"stage": "lb1"}, seed_order); l1.append(w); out.add(b if w == a else a)
        # losers' round 2: l1 winners meet the winners' semi losers (crossed)
        l2 = []
        for a, b in [(l1[0], ls[1]), (l1[1], ls[0])]:
            w = self.ko(a, b, {"stage": "lb2"}, seed_order); l2.append(w); out.add(b if w == a else a)
        l3 = self.ko(l2[0], l2[1], {"stage": "lb3"}, seed_order); out.add(l2[1] if l3 == l2[0] else l2[0])
        lf = self.ko(l3, wf_loser, {"stage": "lb-final"}, seed_order); out.add(wf_loser if lf == l3 else l3)
        g = self.ko(wf, lf, {"stage": "grand-final"}, seed_order)
        if g == lf:  # reset: both now have one loss
            g = self.ko(wf, lf, {"stage": "grand-final-2"}, seed_order)
        champ = g
        if self.me in quals:
            self.finish = "champion" if champ == self.me else ("runner-up" if self.me in (wf, lf) else "bracket")
        return champ


# ------------------------------------------------------------------ formats
def fmt_today(r, powers):
    ent = list(range(len(powers)))
    quals, _ = r.pools(ent, len(ent) // 4)
    return r.bracket(quals, ent)


def fmt_32(r, powers):
    return fmt_today(r, powers)  # same code; the field is 32, so 8 pools and a round of 16


def fmt_second_group(r, powers):
    ent = list(range(len(powers)))
    q, _ = r.pools(ent, 4)  # [A1,B1,C1,D1,A2,B2,C2,D2]
    A1, B1, C1, D1, A2, B2, C2, D2 = q
    x, y = [A1, C1, B2, D2], [B1, D1, A2, C2]
    gx, _ = r.pools_fixed([x], "group2")
    gy, _ = r.pools_fixed([y], "group2")
    semis = [gx[0], gy[0], gx[1], gy[1]]  # X1 v Y2 and Y1 v X2 via i vs n-1-i on [X1,Y1,X2,Y2]
    if r.me in ent and r.finish is None and r.me in x + y and r.me not in semis:
        r.finish = "group2"
    return r.bracket(semis, ent)


def fmt_double(r, powers):
    ent = list(range(len(powers)))
    quals, _ = r.pools(ent, 4)
    return r.double_elim(quals, ent)


def fmt_bo3_final(r, powers):
    ent = list(range(len(powers)))
    quals, _ = r.pools(ent, 4)
    return r.bracket(quals, ent, final_bo3=True)


def fmt_choose(r, powers):
    """Pool winners pick their quarter-final opponent, best pool winner first; each picks
    the weakest runner-up left (what a sensible captain would do)."""
    ent = list(range(len(powers)))
    quals, order = r.pools(ent, 4)
    winners, runners = quals[:4], quals[4:]
    # pool winners ranked by their pool record
    rows = sorted([o[0] for o in order], key=lambda x: (-x["pts"], -(x["mf"] - x["ma"]), -(x["rf"] - x["ra"])))
    wl = [x["club"] for x in rows]
    pool_of = {}
    for pi, o in enumerate(order):
        for row in o:
            pool_of[row["club"]] = pi
    left = list(runners); pairs = []
    for w in wl:
        cand = [c for c in left if pool_of[c] != pool_of[w]] or left
        pick = min(cand, key=lambda c: r.p[c])
        left.remove(pick); pairs.append((w, pick))
    # bracket order so that the top two pool winners are on opposite halves
    field = [pairs[0][0], pairs[3][0], pairs[2][0], pairs[1][0], pairs[1][1], pairs[2][1], pairs[3][1], pairs[0][1]]
    return r.bracket(field, ent)


def _pools_fixed(self, pools_list, stage):
    out_q = []; out_o = []
    for pl in pools_list:
        q, o = self.pools(pl, 1, stage=stage)
        out_q += q; out_o += o
    return out_q, out_o


Run.pools_fixed = _pools_fixed

FORMATS = {
    "W0 today": fmt_today,
    "W2 second group": fmt_second_group,
    "W3 double elim": fmt_double,
    "W4 bo3 final": fmt_bo3_final,
    "W5 winners choose": fmt_choose,
}
