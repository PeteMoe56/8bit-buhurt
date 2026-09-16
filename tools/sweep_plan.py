#!/usr/bin/env python3
"""Build the sweep plan: every numeric tunable, five points around where it sits.

Pete, 15 Sep 2026: "We should be gathering all the possible variables of this
including every price... Each variable deserves its own test."

The plan is generated rather than typed for the obvious reason -- there are
about a hundred and thirty of them and a hand-written list is a list that goes
out of date the first time somebody adds a constant. It reads the same `const`
declarations the game compiles, so a tunable cannot be in the code and missing
from the sweep.

SKIPPED, and each for a stated reason rather than taste:
  structural   a number the rules are built on rather than balanced by, where
               moving it does not mean "harder" or "easier" but "a different
               game" -- POTENTIAL_CEILING is the top of the scale, WIN_POINTS is
               what a win is worth in a table everybody shares.
  derived      a figure measured from another part of the game rather than
               chosen (HOSTED_SHARE came off probe_venue; TIERS' slack came off
               probe_wallet). Sweeping it asks "what if we were wrong about a
               measurement", which is a different question.
  cosmetic     anything the career never reads -- purse log length, name lists.
"""
import re, sys

FILES = [
    "scripts/game/career.gd", "scripts/league/club_office.gd",
    "scripts/league/market.gd", "scripts/league/arena.gd",
    "scripts/league/league.gd", "scripts/league/contracts.gd",
    "scripts/league/season.gd", "scripts/league/club_factory.gd",
    "scripts/league/federation.gd", "scripts/league/league_world.gd",
    "scripts/league/venue.gd",
]

SKIP = {
    # structural: the scale itself, or a rule every club shares equally
    "POTENTIAL_CEILING", "AGE_MIN", "AGE_MAX", "WIN_POINTS", "DRAW_POINTS",
    "LOSS_POINTS", "MAX_LEVEL", "FACILITY_MAX", "CAP_MAX_LEVEL", "MAX_CAPTAINS",
    "SPECIALTIES", "RETIRE_HARD", "FOREIGN_TOP", "WORLDS_FIELD", "WORLDS_HOME",
    "INVITATIONAL_FIELD", "INVITE_RANK", "HOF_MAX", "SIZE", "BANDS",
    "LEVEL_BAR_CAP", "YEARS_MAX", "GROUND_SALT", "PURSE_KEEP", "DILEMMA_MEMORY",
    "AVAILABILITY_MAX", "WEARS_FROM_LEVEL", "STATS", "PEAK_STRENGTH",
    "PEAK_BASE", "PEAK_SKILL", "PEAK_GAS", "LINE_SLOTS", "BACKUP_SLOTS",
    "RESERVE_SLOTS", "SURNAMES", "SECOND", "INVITATIONALS", "TIERS", "LEVELS",
    "CPU_TIER", "TIER_CAP", "ORDER",
    # derived from a measurement rather than chosen
    "HOSTED_SHARE", "WEAR_HOSTED_SHARE", "XP_RATING_BASE", "BIGGEST_HOUSE",
    "RATING_SCALE", "LEARN_PAR", "NEAR_MILES", "FAR_MILES",
    # cosmetic or not on the career path
    "LEVEL_MORALE", "SOUR_CHANCE", "SOUR_LO", "SOUR_HI", "FINE_LO", "FINE_HI",
    "DRAW_ROUND_CHANCE", "MARGIN_WEIGHTS", "TACTICIAN_ODDS", "TACTICIAN_GRADE",
    "ARRIVAL_TRAITS", "HOME_SHARE",
}

DECL = re.compile(r"^const ([A-Z_]+)(?:: *([A-Za-z\[\]]+))? *:?= *([-0-9.]+)\s*(##.*)?$")


def points(v, is_int):
    """Five points spanning a halving and a doubling, kept distinct and legal."""
    mults = [0.5, 0.75, 1.0, 1.5, 2.0]
    out = []
    for m in mults:
        x = v * m
        if is_int:
            x = int(round(x))
            if v >= 1 and x < 1:
                x = 1
        else:
            x = round(x, 4)
        if x not in out:
            out.append(x)
    return out


def main():
    rows = []
    for f in FILES:
        for line in open(f):
            m = DECL.match(line.rstrip("\n"))
            if not m:
                continue
            name, typ, val, _ = m.groups()
            if name in SKIP:
                continue
            is_int = ("." not in val) and (typ != "float")
            v = float(val)
            if v == 0:
                continue
            for p in points(v, is_int):
                rows.append((name, f, p))
    for name, f, p in rows:
        print("%s\t%s\t%s" % (name, f, p))
    print("# %d points across %d tunables"
          % (len(rows), len({r[0] for r in rows})), file=sys.stderr)


main()
