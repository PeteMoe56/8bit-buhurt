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
]

DECL = re.compile(r"^(const [A-Z_]+(?:: *[A-Za-z\[\]]+)? *:?= *)([^#]*)(.*)$")


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


TARGET = float(os.environ.get("TARGET", "10"))
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


def key(s, cur=None, ship=None):
    """Lower is better. See the header for why the first term is a distance."""
    d = drift(cur, ship) if cur and ship else 0.0
    return (round(abs(reach(s) - TARGET), 4), d, -s["power"])


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
    for name, path, _ in LEVERS:
        set_const(name, path, cur[name])
    ship = dict(cur)
    best = score()
    print("start %s  %s" % (key(best, cur, ship), cur), flush=True)

    for rnd in range(4):
        moved = False
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
    for k, v in cur.items():
        mark = "" if str(v) == str(ship[k]) else "   <- was %s" % ship[k]
        print("  %-22s %-8s%s" % (k, v, mark))


main()
