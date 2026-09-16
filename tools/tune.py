#!/usr/bin/env python3
"""Coordinate descent over the levers a single-variable sweep found.

Pete, 15 Sep 2026: "Target is a 10 season Championship for the average player."

`tools/sweep.sh` moves ONE tunable at a time and that is the right first pass --
it says which numbers matter and which are inert. It cannot find the SETTING,
because the target needs several of them together and a one-at-a-time sweep
never sees a combination. This walks the levers in turn, keeps whatever improved
the objective, and goes round again until a pass changes nothing.

THE OBJECTIVE AIMS AT THE TARGET RATHER THAN PAST IT, and getting that wrong was
the most instructive thing in the exercise. The first version minimised "seasons
to a title", and its answer was to set every development lever to the top of its
range -- LEVEL_XP to 1, GAIN_MAX to 9, CEILING_DRIFT to 10, DECLINE_RATE halved.
Of course it did. **"Minimise seasons to a title" is optimised by a game you win
immediately**, and nothing in that objective knows a career can be too fast. Pete
asked for a ten-season championship, not for the fewest possible seasons, so the
objective is DISTANCE FROM TEN.

The second term matters as much. Among settings that hit the target there are
many, and they are not equally good: one moves three numbers a little and another
moves nine of them a lot, and the second is a different game wearing this one's
name. So the tie-break is TOTAL RELATIVE CHANGE FROM WHAT SHIPS -- the balance
that hits the target while disturbing the least. Power breaks any remaining tie,
because a club that got there stronger got there more convincingly.

    |seasons to a title - 10|, then how far the settings moved, then power

PAIRED AND DETERMINISTIC. `tools/sweep.sh`'s control -- five values of an inert
constant scoring byte-identically -- proves a run is a pure function of its
settings and its seeds, so a difference here is a real consequence. What it is
NOT is a guarantee the effect generalises; every setting this finds is confirmed
on fresh seed bases afterwards.
"""
import subprocess, re, sys, os, shutil

G = os.environ.get("GODOT", "/tmp/godot462/Godot_v4.6.2-stable_linux.x86_64")
LANE = os.environ.get("LANE", "/tmp/sweeplane")
SEEDS = os.environ.get("SEEDS", "5")
YEARS = int(os.environ.get("YEARS", "14"))

# name -> (file, [candidates]).  Ranges are widened past what the sweep tried
# wherever the sweep's best value sat at the edge of its own range -- an optimum
# on the boundary is a range that was too narrow, not an answer.
LEVERS = [
    ("LEVEL_XP",          "scripts/game/career.gd",        [1, 2, 3, 4, 5]),
    ("POTENTIAL_GAP_MAX", "scripts/game/career.gd",        [18, 24, 27, 32, 40]),
    ("CEILING_DRIFT",     "scripts/game/career.gd",        [2, 4, 6, 8, 10]),
    ("GAIN_PER_GAP",      "scripts/game/career.gd",        [2, 3, 4, 6]),
    ("GAIN_MAX",          "scripts/game/career.gd",        [3, 5, 7, 9]),
    ("PRACTICE_PER_GRADE","scripts/game/career.gd",        [2.6, 4.0, 5.2, 7.0]),
    ("XP_SIMMED",         "scripts/league/season.gd",      [8, 12, 16, 24]),
    ("DECLINE_RATE",      "scripts/game/career.gd",        [0.15, 0.3, 0.45, 0.6]),
    ("STANDARD_ROOM",     "scripts/game/career.gd",        [10, 16, 22]),
    ("PEAK_SPREAD",       "scripts/game/career.gd",        [2, 4, 6, 8]),
    ## AND THE FIRST PROMOTION, which is a different problem from the title and
    ## has its own levers. "Out of the Backyard Circuit by season 2" is a
    ## statement about the distance between the club you inherit and the club
    ## leading the division you inherit it in — so both ends of that gap are in
    ## scope, and neither was in the first sweep.
    ("START_POWER",       "scripts/melee/melee_rosters.gd", [38, 41, 44, 47, 50]),
]

## AND THE LADDER, which the first sweep excluded as structural and which the
## first sweep's own result then pointed straight at: with every development
## lever pegged, a club reached the National Division at season 9.2 and needed
## nearly three more years to win it. Those years are not in development.
##
## These are not `const NAME = value` declarations — they are fields inside the
## `TIERS` table — so they need a patch by pattern rather than by name. The
## pattern carries its own value in a group, which keeps the rest of the line
## (and the table's shape) untouched.
PATCHES = [
    ("NAT_CLUBS",  "scripts/league/league.gd",
     r'("id": Tier\.NATIONAL,(?:.|\n)*?"clubs": )(\d+)', ["16", "12", "10", "8"]),
    ("NAT_TOP",    "scripts/league/league.gd",
     r'("id": Tier\.NATIONAL,(?:.|\n)*?"power": \[\d+, )(\d+)', ["86", "78", "72"]),
    ("REG_TOP",    "scripts/league/league.gd",
     r'("id": Tier\.REGIONAL,(?:.|\n)*?"power": \[\d+, )(\d+)', ["70", "64", "60"]),
    ("BYC_UP",     "scripts/league/league.gd",
     r'("id": Tier\.BACKYARD,(?:.|\n)*?"up": )(\d+)', ["2", "3"]),
]

DECL = re.compile(r"^(const [A-Z_]+(?:: *[A-Za-z\[\]]+)? *:?= *)([^#]*)(.*)$")


def set_patch(pat, path, value):
    f = os.path.join(LANE, path)
    src = open(f).read()
    new, n = re.subn(pat, lambda m: m.group(1) + str(value), src, count=1)
    if not n:
        raise SystemExit("patch did not match: %s" % pat[:40])
    open(f, "w").write(new)


def get_patch(pat, path):
    src = open(os.path.join(LANE, path)).read()
    m = re.search(pat, src)
    return m.group(2) if m else None


def set_const(name, path, value):
    f = os.path.join(LANE, path)
    lines = open(f).read().split("\n")
    for i, ln in enumerate(lines):
        if ln.startswith("const %s" % name) and DECL.match(ln):
            m = DECL.match(ln)
            lines[i] = "%s%s %s" % (m.group(1), value, m.group(3))
            open(f, "w").write("\n".join(lines))
            return True
    raise SystemExit("no such constant: %s in %s" % (name, path))


def score():
    out = subprocess.run(
        [G, "--headless", "--path", LANE, "--script",
         "res://tools/career_score.gd", "--", SEEDS, str(YEARS)],
        capture_output=True, text=True, timeout=600).stdout
    line = [l for l in out.split("\n") if l.startswith("SCORE")]
    if not line:
        return None
    d = dict(kv.split("=") for kv in line[0][6:].split())
    return {k: float(v) for k, v in d.items()}


## THE TARGET, and it is a BAND plus a deadline rather than a single number.
##
## Pete, 15 Sep 2026: *"promotion out of backyard by season 2, and championship
## win by season 10-12."* Two separate requirements, and the band matters as much
## as the numbers: anything inside 10 to 12 is a hit, so a setting that wins in
## season eight is now WORSE than one that wins in eleven. That alone is what
## stops the search walking to a corner — the previous objective aimed at a point
## and every lever pegged trying to reach it.
TITLE_LO = float(os.environ.get("TITLE_LO", "10"))
TITLE_HI = float(os.environ.get("TITLE_HI", "12"))
PROMO_BY = float(os.environ.get("PROMO_BY", "2"))
MISSED = float(YEARS) + 1.0


def reach(s):
    """One number for how far a career got, and it has to be smooth at "never".

    The obvious objective — |seasons to a title - 10| — is FLAT across every
    setting that never wins one, because they all score the same `MISSED`. A
    coordinate search starting from a game where nobody wins in sixteen seasons
    therefore finds that no single move improves anything and stops on its first
    pass, which is exactly what happened.

    So when no title arrives, the score is the window plus a hundredth of the
    season the club first reached the top division, plus a ten-thousandth of the
    one before that. Those terms are far too small to outrank a real title and
    large enough to say which of two title-less settings got closer — **a search
    needs a slope everywhere it might stand, not only near the answer.**
    """
    if s["title"] < MISSED:
        return s["title"]
    return MISSED + s["t3"] / 100.0 + s["t2"] / 10000.0


def drift(cur, ship):
    """How far a setting has moved from what ships, summed as relative change.

    Relative rather than absolute so a constant that happens to be large does not
    dominate one that happens to be small -- moving DECLINE_RATE from 0.30 to
    0.15 is the same size of decision as moving LEVEL_XP from 5 to 2.5, and an
    absolute sum would call the first one rounding.
    """
    total = 0.0
    for k, v in cur.items():
        a, b = float(v), float(ship[k])
        if b:
            total += abs(a - b) / abs(b)
    return round(total, 3)


def miss(s):
    """How far the two requirements are from being met. Zero is a hit.

    Summed rather than ranked, because they are not a priority order — Pete asked
    for both, and a setting that nails the title while leaving the first
    promotion at season six has not done the job. Summing also means the search
    can trade a little of one for a lot of the other, which a lexicographic key
    forbids and which is exactly how a balance gets found.
    """
    r = reach(s)
    title = 0.0 if TITLE_LO <= r <= TITLE_HI else min(abs(r - TITLE_LO),
                                                      abs(r - TITLE_HI))
    promo = max(0.0, s["t1"] - PROMO_BY)
    return round(title + promo, 4)


def key(s, cur=None, ship=None):
    """Lower is better. See `miss` for the two requirements it is measuring."""
    d = drift(cur, ship) if cur and ship else 0.0
    return (miss(s), d, -s["power"])


def main():
    if not os.path.isdir(LANE):
        raise SystemExit("no lane at %s -- run tools/sweep.sh once first" % LANE)
    # Start from what the game currently ships.
    cur = {}
    for name, path, cands in LEVERS:
        f = os.path.join(LANE, path)
        for ln in open(f):
            if ln.startswith("const %s" % name):
                cur[name] = DECL.match(ln.rstrip("\n")).group(2).strip()
                break
    for label, path, pat, cands in PATCHES:
        cur[label] = get_patch(pat, path)
    for name, path, _ in LEVERS:
        set_const(name, path, cur[name])
    ship = dict(cur)
    best = score()
    print("start %s  %s" % (key(best, cur, ship), cur), flush=True)

    for rnd in range(4):
        moved = False
        for label, path, pat, cands in PATCHES:
            here = cur[label]
            for c in cands:
                if str(c) == str(here):
                    continue
                set_patch(pat, path, c)
                s = score()
                trial = dict(cur)
                trial[label] = str(c)
                if s and key(s, trial, ship) < key(best, cur, ship):
                    best, cur[label], here, moved = s, str(c), str(c), True
                    print("  %-20s -> %-6s  %s  title=%.1f t1=%.1f t3=%.1f"
                          % (label, c, key(s, cur, ship), s["title"], s["t1"],
                             s["t3"]), flush=True)
                else:
                    set_patch(pat, path, here)
        for name, path, cands in LEVERS:
            here = cur[name]
            for c in cands:
                if str(c) == str(here):
                    continue
                set_const(name, path, c)
                s = score()
                trial = dict(cur)
                trial[name] = str(c)
                if s and key(s, trial, ship) < key(best, cur, ship):
                    best, cur[name], here, moved = s, str(c), str(c), True
                    print("  %-20s -> %-6s  %s  title=%.1f t3=%.1f power=%.1f"
                          % (name, c, key(s, cur, ship), s["title"], s["t3"],
                             s["power"]), flush=True)
                else:
                    set_const(name, path, here)
        print("pass %d done: %s" % (rnd + 1, key(best, cur, ship)), flush=True)
        if not moved:
            break
    print("\nBEST %s  title=%.1f t3=%.1f t2=%.1f power=%.1f"
          % (key(best, cur, ship), best["title"], best["t3"], best["t2"],
             best["power"]))
    print("  target: promotion by %g (got %.1f), title in %g-%g (got %.1f)"
          % (PROMO_BY, best["t1"], TITLE_LO, TITLE_HI, best["title"]))
    for k, v in cur.items():
        mark = "" if str(v) == str(ship[k]) else "   <- was %s" % ship[k]
        print("  %-22s %-8s%s" % (k, v, mark))


main()
